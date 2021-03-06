module Net::IRC-0.05;
# This is a take at a Perl 6 IRC library.
# This library provides the "classes" bot and queue, to be used in other bots.
# One is able to say:
#   my $bot = new_bot(nick => $nick, host => $host, port => $port);
#   $bot<connect>();
#   $bot<login>();
#   $bot<join>("#channel");
#   $bot<run>();            # Enter main event loop
# Note that this is *not* a port of Perl 5's Net::IRC.
# See the POD of this document for more documentation.

use v6;
use Algorithm::TokenBucket;
use Set;

sub debug(Str $msg) is export {
  state $is_fresh;
  $is_fresh //= 1;

  print "» " if $is_fresh;
  if $msg ~~ rx:P5/ $/ {
    print "$msg";
    $is_fresh = 0;
  } else {
    say $msg;
    $is_fresh++;
  }
}
sub debug_recv(Str $msg) { say "< $msg" }
sub debug_sent(Str $msg) { say "> $msg" }

# Definition of the bot "class"
sub new_bot(
  Str $nick,
  Str $username = $nick,
  Str $ircname  = $nick,
  Str $host,
  Str $password,
  Int $port          = 6667,
  Int $autoping      = 90,     # Autoping the server when we haven't seen traffic for 90s
  Int $live_timeout  = 120,    # Drop connection when we haven't seen traffic for 120s
  Bool $floodcontrol = 0,      # Check that we don't flood excessively
  Bool $debug_raw = 0,
) is export {
  $*ERR.say: "Username: $username";
  my $connected = 0;
  my $inside    = 0;
  my $chans = set();       # Which chans have we joined?
  my $servername;          # What is the IRC servername?
  my $last_traffic;        # Timestamp of last traffic seen from server
  my $last_autoping;       # Timestamp of last ping sent to server
  my $hdl;                 # Socket
  my $queue = new_queue(floodcontrol => $floodcontrol);
                           # Queue
  my %handler;             # Callbacks for numeric (001) and command (PRIVMSG)
                           # messages
  my ($curnick, $curusername, $curircname, $curhostname);
                           # Our current nick, username, ircname, etc.
  my $nickgen = new_permutation($nick);
                           # A permutation object, providing the methods
                           # "reset" and "next".
  my %channels;            # Stores the current topic, the users on the
                           # channel, etc. Note: Hash keys are always
                           # normalized() first!
  my %users;               # Stores the channels a user is on. Note: As with
                           # %channels, hash keys are always normalized().
  my %cache353;            # We need a temporary storage for the names we
                           # receive after we've done a /NAMES (the numeric
                           # code for /NAMES is 353).
  my $in_login_phase;

  my $self;

  # Sub which sends $msg, flushes $hdl and logs $msg to STDERR.
  my $say = -> Str $msg {
    debug_sent $msg if $debug_raw;
    $hdl.print("$msg\c[13,10]");
    $hdl.flush();
  };

  # Thin wrapper around $queue<enqueue>.
  # (Perl 6)++ for allowing me to define &subs easily. :)
  sub enqueue (Str $msg) {
    $queue<enqueue>({ $say($msg) })
      if $connected;
  };

  # Default (passive) handlers
  # First event we get, indicating a successful login
  %handler<001> = [-> $event {
    $inside++;
    $servername     = $event<server>;
    $curnick        = $event<to>;
    $in_login_phase = 0;
    $self<handle_pseudo>("loggedin");
    # We want to know our username and host, so we /WHO ourselves.
    $self<who>($curnick);
    debug "Logged in to \"$servername\" as \"$curnick\".";
  }];

  # Nick already used, so we permute our nick.
  %handler<433> = [-> $event {
    if $in_login_phase {
      $self<nick>($nickgen<next>());
    }
  }];

  # /WHO (we /WHO ourselves so we can provide accurate username, hostname, and
  # ircname information.)
  %handler<352> = [-> $event {
    my %rest;
    %rest<_ username hostname servername nickname umode _ ircname> =
      split " ", $event<rest>;
    if normalize(%rest<nickname>) eq normalize($curnick) {
      ($curusername, $curhostname, $curircname) =
        %rest<username hostname ircname>;
    }
  }];

  # The topic of a chan.
  %handler<332> = [-> $event {
    my ($chan, $topic) = split " ", $event<rest>;
    $topic = strip_colon($topic);

    %channels{~normalize($chan)}<topic> = $topic;
  }];
  %handler<TOPIC> = [-> $event {
    %channels{~normalize($event<object>)}<topic> = $event<rest>;
  }];

  # /NAMES response
  %handler<353> = [-> $event {
    my ($chan, $nicks) = $event<rest> ~~ m:P5/^. ([^ ]+) :?(.*)$/;
    return unless defined $chan;
    $chan = normalize $chan;

    my @nicks = split(" ", $nicks)\
               .map:{ ($_ ~~ m:P5/^[@+%]?(.+)/)[0] }\
               .grep:{ defined $_ }\
               .map:{ normalize $_ };

    unless defined %cache353{$chan} {
      # We initialize %cache353{$chan} by makeing %cache353{$chan} a hashref
      # which has the nicks, which we currently think are on the channel, as
      # keys. Then, we delete all nicks we see as response from the /NAMES.
      # Finally, we delete all nicks, which are still in %cache353{$chan}.

      %cache353{$chan}{$_}++ for %channels{$chan}<users>.keys;
    }

    # We have already initialized %cache353{$chan}.
    if @nicks {
      %cache353{$chan}.delete(@nicks);
    }

    # For each nick, make sure we've registered them as people who are on
    # $chan:
    %channels{$chan}<users>{$_}++ for @nicks;
    %users{$_}<channels>{$chan}++ for @nicks;
  }];

  # End of /NAMES
  %handler<366> = [-> $event {
    # (Perl 6)++ for new parenthesis rules! :)
    my $chan = normalize (split " ", $event<rest>)[0];

    unless defined %cache353{$chan} {
      %cache353{$chan} = %channels{$chan}<users>;
    }

    %channels{$chan}<users>.delete(%cache353{$chan}.keys);
    %users{$_}<channels>.delete($chan) for %cache353{$chan}.keys;
  }];

  # We track our status, especially the channels we've joined.
  # Somebody joined. Update %channels and %users accordingly.
  %handler<JOIN> = [-> $event {
    if normalize($event<from_nick>) eq normalize($curnick) {
      $chans.insert(normalize $event<object>);
      debug "Joined channel \"$event<object>\".";
    }

    %channels{~normalize($event<object>)}<users>{~normalize($event<from_nick>)}++;
    %users{~normalize($event<from_nick>)}<channels>{~normalize($event<object>)}++;
  }];

  # Somebody left a channel. Update %channels and %users accordingly.
  %handler<PART> = [-> $event {
    my $chan = normalize $event<object>;

    if normalize($event<from_nick>) eq normalize($curnick) {
      $chans.remove(normalize $event<object>);
      for %channels{$chan}<users>.keys {
        %users{$_}<channels>.delete($chan) if %users{$_}<channels>;
      }
      %channels.delete($chan);
      debug "Left channel \"$chan\".";
    } else {
      %channels{$chan}<users>.delete(normalize $event<from_nick>);
      %users{~normalize($event<from_nick>)}<channels>.delete($chan)
        if %users{~normalize($event<from_nick>)}<channels>;
    }
  }];

  # Somebody was kicked. Update %channels and %users accordingly.
  %handler<KICK> = [-> $event {
    my ($kickee, $reason) = split " ", $event<rest>;
    $reason = strip_colon($reason);
    my $chan = normalize $event<object>;

    if normalize($kickee) eq normalize($curnick) {
      $chans.remove(normalize $event<object>);
      for %channels{$chan}<users>.keys {
        %users{$_}<channels>.delete($chan) if %users{$_}<channels>;
      }
      %channels.delete($chan);
      debug "Was kicked from channel \"$chan\" by \"$event<from>\" (\"$reason\").";
    } else {
      %channels{$chan}<users>.delete(normalize $kickee);
      %users{~normalize($kickee)}<channels>.delete($chan)
        if %users{~normalize($kickee)}<channels>;
    }
  }];

  # Somebody was killed. Update %channels and %users accordingly.
  %handler<KILL> = [-> $event {
    my ($killee, $reason) = $event<object rest>;
    if normalize($killee) eq normalize($curnick) {
      $chans.clear;
      debug "Was killed by \"$event<from>\" (\"$reason\").";
    }

    my @chans = %users{~normalize($killee)}<channels>.keys;
    %channels{$_}<users>.delete(~normalize($killee)) for @chans;
    %users.delete(normalize $killee);
  }];

  # Somebody quit. Remove him/her from %users and %channels.
  %handler<QUIT> = [-> $event {
    my @chans = %users{~normalize($event<from_nick>)}<channels>.keys;
    %channels{$_}<users>.delete(normalize $event<from_nick>) for @chans;
    %users.delete(normalize $event<from_nick>);
  }];

  # Somebody changed his/her nick. Rename his/her entry in %users, and update
  # all %channels he/she has joined.
  %handler<NICK> = [-> $event {
    if normalize($event<from_nick>) eq normalize($curnick) {
      $curnick = $event<object>;
      debug "Changed nick to \"$event<object>\".";
    }

    my $oldnick = normalize $event<from_nick>;
    my $newnick = normalize $event<object>;
    if %users{$oldnick}<channels> {
      for %users{$oldnick}<channels>.keys {
        %channels{$_}<users>.delete($oldnick);
        %channels{$_}<users>{$newnick}++;
      }
    }

    # The more elegant %users{$newnick} = %users.delete($oldnick) doesn't work
    # yet in Pugs, because, so it seems, delete stringifies its return values,
    # but I was unable to work out a test case, and in interactive Pugs delete
    # seems to work...
    %users{$newnick} = %users{$oldnick};
    %users.delete($oldnick);
  }];

  # Instance methods
  $self = {
    # Readonly accessors
    curnick       => { $curnick },
    curusername   => { $curusername },
    curircname    => { $curircname },
    curhostname   => { $curhostname },
    servername    => { $servername },
    connected     => { $connected },
    logged_in     => { $inside },
    last_traffic  => { $last_traffic },
    last_autoping => { $last_autoping },
    channels      => { $chans.members },
    channel       => -> Str $channel { %channels{~normalize($channel)} },
    user          => -> Str $nick    { %users{~normalize($nick)} },

    # Main handler register method
    add_handler => -> Str $code, Code $cb { %handler{$code}.push($cb) },

    # Connect/disconnect methods
    connect    => { $self<reconnect>() },
    reconnect  => {
      $self<disconnect>() if $connected;

      debug "Connecting to $host:$port... ";
      try { $hdl = connect($host, $port) };
      if $hdl {
        try { $hdl.autoflush(1) };
        $connected++;
        $last_traffic  = time;
        $last_autoping = time;
        debug "done.";
      } else {
        debug "failed ($!).";
      }
    },
    disconnect => {
      if $connected {
        debug "Disconnecting from $host:$port... ";
        try { $hdl.close };
        # We want to have a sane state when we connect next time.
        $connected      = 0;
        $inside         = 0;
        $chans          = set();
        $servername     = undef;
        $hdl            = undef;
        $curnick        = undef;
        $curusername    = undef;
        $curircname     = undef;
        $curhostname    = undef;
        $last_traffic   = 0;
        $last_autoping  = 0;
        $in_login_phase = 0;
        %channels       = ();
        $queue<clear>();
        $nickgen<reset>();
        debug "done.";
      }
    },

    # Login
    login => {
      if $connected {
        $queue<enqueue>({
          # Indicate that we're currently logging in, so our nick_already_used
          # handler can choose a different nick. $in_login_phase is reset to 0
          # when we're successfully logged in.
          $in_login_phase++;
          if ($password) {
            $say("PASS $password");
          }
          $say("NICK {$nickgen<next>()}");
          $say("USER $username * * :$ircname");
        });
      }
    },

    # Process $queue, wait for input from server and process it
    run => {
      while $connected {
        $queue<run>();
        $self<readline>();
        $self<livecheck>();
        $self<handle_pseudo>("runloop");
      }
    },

    # Read a line from the server and process it
    readline => {
      my $line = readline $hdl;
      $line ~~ s:P5/[\015\012]*$//; # Hack to remove all "\r\n"s
      debug_recv $line if $debug_raw;
      # We record the time the last traffic from the server was seen, so we can
      # autoping the server if needed.
      $last_traffic = time;

      if $line ~~ rx:P5/^:([^ ]+) (\d+) ([^ ]+) ?(.*)$/ {
        $self<handle_numeric>($line, $0, $1, $2, $3);
      } elsif $line ~~ rx:P5/^:([^ ]+) (\w+) ([^ ]+) ?(.*)$/ {
        $self<handle_command>($line, $0, $1, $2, $3);
      } elsif $line ~~ rx:P5/^ERROR ?:?(.*)$/ {
        debug "Error in connection to $host:$port (\"$0\").";
        $self<disconnect>();
      } elsif $line ~~ rx:P5/^PING ?:?(.*)$/ {
        $say("PONG $0");
      } else {
        debug "No handler found for \"$line\".";
      }
    },

    # Handle numeric commands (e.g. 001 -> welcome)
    handle_numeric => -> Str $line, Str $server, Str $code, Str $to, Str $rest {
      my $event = {
        line   => $line,
        server => $server,
        to     => $to,
        rest   => strip_colon($rest),
      };

      if %handler{$code} {
        $_($event) for %handler{$code}[];
      }
    },

    # Handle word commands (e.g. JOIN, INVITE)
    handle_command => -> Str $line, Str $from, Str $command, Str $object, Str $rest {
      my $from_nick; $from_nick = $0 if $from ~~ rx:P5/^([^!]+)!/; #/#--vim
      my $event = {
        line      => $line,
        from      => $from,
        from_nick => $from_nick,
        rest      => strip_colon($rest),
        object    => strip_colon($object),
      };

      if %handler{$command} {
        $_($event) for %handler{$command}[];
      }
    },

    # Handle pseudo events (runloop, loggedin)
    handle_pseudo => -> Str $pseudo, *@args {
      my $event = {
        pseudo => $pseudo,
        args   => @args,
      };

      if %handler{$pseudo} {
        $_($event) for %handler{$pseudo}[];
      }
    },

    # Check that our connection is still alive.
    livecheck => {
      if $connected {
        # We haven't seen any traffic for at least $autoping seconds, so we
        # PING the server. If the connection is still alive, the server will
        # respond with a PONG, so everything's fine. But if the connection is
        # somehow b0rked, we won't get a reply.
        if $servername and time() - $last_traffic >= $autoping and time() - $last_autoping >= 60 {
          debug "No traffic seen for {time() - $last_traffic} seconds; pinging server.";
          $self<raw>("PING :$servername");
          $last_autoping = time;
        }

        # So we haven't seen any traffic for at least $live_timeout seconds,
        # even though we've pinged the server (probably several times). So, we
        # conclude, the connection is b0rked, and we disconnect.
        if time() - $last_traffic >= $live_timeout {
          debug "No traffic seen for {time() - $last_traffic} seconds; disconnecting.";
          $self<disconnect>();
        }
      }
    },

    # JOIN/PART/KICK/...
    join => -> Str $channel, Str $key? {
      if $connected {
        if defined $key {
          enqueue "JOIN $channel $key";
        } else {
          enqueue "JOIN $channel";
        }
      }
    },
    part  => -> Str $channel { enqueue "PART $channnel" },
    quit  => -> Str $reason  { enqueue "QUIT :$reason" },
    nick  => -> Str $newnick { enqueue "NICK $newnick" },
    who   => -> Str $target  { enqueue "WHO $target" },
    whois => -> Str $target  { enqueue "WHOIS $target" },
    ison  => -> Str @targets { enqueue "ISON @targets[]" },
    topic => -> Str $channel, Str $topic? {
      if defined $topic {
        enqueue "TOPIC $channel :$topic";
      } else {
        enqueue "TOPIC $channel";
      }
    },
    kick  => -> Str $channel, Str $nick, Str $reason? {
      enqueue "KICK $channel $nick :{$reason // ""}";
    },
    mode  => -> Str $target, Str $mode? {
      if defined $mode {
        enqueue "MODE $target $mode";
      } else {
        enqueue "MODE $target";
      }
    },
    invite => -> Str $channel, Str $target { enqueue "INVITE $target $channel" },
    oper   => -> Str $username, Str $password { enqueue "OPER $username $password" },

    # PRIVMSG/NOTICE
    privmsg => -> Str $to, Str $text {
      enqueue "PRIVMSG $to :$text";
    },
    notice  => -> Str $to, Str $text {
      enqueue "NOTICE $to :$text",
    },

    # RAW
    raw => -> Str $command { enqueue $command },
  };

  return $self;
}

# Definition of queue "class"
sub new_queue(Bool $floodcontrol = 0) {
  my @queue;

  my $bucket = $floodcontrol
    ?? Algorithm::TokenBucket::new_bucket(rate => (1/2),    burst_size => 5)
    !! Algorithm::TokenBucket::new_bucket(rate => (1000/2), burst_size => 5000); # hack
  $bucket<fill>();

  # "Instance methods"
  return {
    # Run all entries of @queue. Will need throttling later.
    run => {
      my @q = splice @queue;
      while @q {
        if $bucket<conform>(1) {
          $bucket<count>(1);
          @q.shift().();
        } else {
          last;
        }
      }
      @queue.unshift(@q);
    },

    # Enqueue a new callback
    enqueue => -> Code $code { push @queue, $code },

    # Remove all items from the queue
    clear => { @queue = () },
  };
}

sub new_permutation(Str $nick) {
  my @perms;

  my $self = {
    reset => {
      @perms = (
        "$nick",
        "{$nick}_", "{$nick}__",
        "_{$nick}", "__{$nick}",
        "_{$nick}_", "__{$nick}__",
      );
    },
    "next" => {
      my $cur = @perms.shift;
      @perms.push($cur);

      $cur;
    },
  };

  $self<reset>();
  return $self;
}

sub strip_colon(Str $str is copy) {
  $str = substr $str, 1 if substr($str, 0, 1) eq ":";
  return $str;
}

sub normalize(Str $str) returns Str { return lc $str }

=head1 NAME

Net::IRC - IRC library for Pugs

=head1 SYNOPSIS

  use Net::IRC;
  
  # Create new bot "object"
  my $bot = new_bot(
    nick     => "blechbot",
    username => "blech",      # (optional, defaults to $nick)
    ircname  => "Ingo's Bot", # (optional, defaults to $nick)
    host     => "localhost",
    port     => 6667,         # (optional)
    autoping => 90,           # (optional, defaults to 90)
    live_timeout => 120,      # (optional, defaults to 120)
    floodcontrol => 0,        # (optional, defaults to 0)
    debug_raw => 0,           # (optional, defaults to 0)
  );
  
  # Register callbacks
  $bot<add_handler>("INVITE",   \&on_invite);
  $bot<add_handler>("PRIVMSG",  \&on_privmsg);
  $bot<add_handler>("loggedin", \&on_ready);

  # Connect and login
  $bot<connect>();
  $bot<login>();

  # Enter main event loop
  $bot<run>();

=head1 DESCRIPTION

C<Net::IRC> is an IRC library for Pugs. Note that it is I<not> a port of Perl
5's C<Net::IRC>.

=head1 METHODS

=head2 C<new_bot(...)>

Creates a new bot "object". See L<SYNOPSIS> for accepted parameters.

The bot will autoping the server if it hasn't seen traffic for C<$autoping>
seconds, and it'll drop the connection if it hasn't seen traffic for
C<$live_timeout> seconds. Furthermore, it'll track its status (its nick, the
channels it has joined, etc.).

=head2 C<$botE<lt>loginE<gt>()>

Tries to login, using the C<nickname>, C<username>, and C<ircname> you've
specified in the constructor. If the nickname is already used, C<Net::IRC> will
try to use a permuted nick (for example C<bot_>, C<_bot>, etc.).

=head2 C<$botE<lt>runE<gt>()>

Starts the main runloop, which is only exited if the connection to the server
dies. To read data from the server, a blocking C<readline> call is used.

=head2 C<$botE<lt>curnickE<gt>()>, C<$botE<lt>curusernameE<gt>()>,
C<$botE<lt>curircnameE<gt>()>, C<$botE<lt>curhostnameE<gt>()>

Returns the current nickname, username, or ircname. Note that thesse are I<not>
necessarily the names you specified in the constructor. For example,
C<Net::IRC> automatically tries to use slight variations of the nickname in the
login phase (for example C<bot_>, C<_bot>, etc.) if the desired nick is already
used.

C<Net::IRC> will C</WHO> itself after login, so it can give you accurate
C<username> and C<ircname> information.

This is a readonly accessor. To set the nickname, use the C<nick> method.

=head2 C<$botE<lt>last_trafficE<gt>()>, C<$botE<lt>last_autopingE<gt>()>

These are readonly accessors. C<last_traffic> is the timestamp of when the last
traffic from the server was seen, and C<last_autoping> is the timestamp of the
last autoping.

=head2 C<$botE<lt>connectedE<gt>()>

Returns a true value if the bot's socket to the server is currently connected.

Note that you might want to use the C<logged_in> method instead.

=head2 C<$botE<lt>logged_inE<gt>()>

Returns a true value if the bot is logged in.

=head2 C<$botE<lt>channelsE<gt>()>

Returns a list of channels the bot has joined. This is a readonly accessor, you
have to use the C<join> and C<part> methods to join or leave channels.

=head2 C<$botE<lt>channelE<gt>("#chan")>

Returns a hashref describing C<#chan>. Its keys are C<topic> (the current
topic) and C<users>, a hashref, which has the nicks who are on the channel as
keys.  Note that the nicknames are normalized.

=head2 C<$botE<lt>userE<gt>("nick")>

Returns a hashref describing C<nick>. Currently, there's only one key,
C<channels>, which is a hashref, which has the channels C<nick> has joined as
keys. Note that the channel names are normalized.

=head2 C<$botE<lt>add_handlerE<gt>("001", -E<gt> $event {...})>

=head2 C<$botE<lt>add_handlerE<gt>("JOIN", -E<gt> $event {...})>

=head2 C<$botE<lt>add_handlerE<gt>("loggedin", -E<gt> $event {...})>

Adds a callback to be executed when the bot receives a corresponding message.
Event names which are all lowercase are "pseudo" events. See below for a list
of pseudo events.

The callback is given a C<$event> hashref, containing:

=over

=item C<line>

The original line received from the server (unmodified).

=item C<server>

The server the line was sent from. This is I<not> necessarily the server you
connected to.

=item C<to>

The nick the message was sent to.

=item C<rest>

Additional information (varies).

=item C<from>

The C<nick!hostmask> the message was sent from. Not available for numeric
handlers.

=item C<from_nick>

The nick part of C<from>. Not available for numeric handlers.

=item C<object>

The nick/channel/whatever the message operated (varies).

=item C<pseudo>

The pseudo event (if appropriate).

=back

=head2 C<$botE<lt>joinE<gt>(channel =E<gt> "#chan", key =E<gt> "password")>

Joins a channel (optionally using the specified key).

=head2 C<$botE<lt>partE<gt>("#chan")>

Parts a channel.

=head2 C<$botE<lt>quitE<gt>("reason")>

Quits the connection to the server by sending a C</QUIT> command. Note that the
socket usually stays connected for a few seconds.

=head2 C<$botE<lt>nickE<gt>("newnick")>

Tries to change the bot's nick. Also see C<nick> below.

=head2 C<$botE<lt>topicE<gt>("#chan")>, C<$botE<lt>topicE<gt>(channel =E<gt> "#chan",
topic =E<gt> "new topic")>

Retrieves a channel's topic or tries to set it.

=head2 C<$botE<lt>kickE<gt>(channel =E<gt> "#chan", nick
=E<gt> "...", reason =E<gt> "...")>

Kicks somebody from a channel, stating a reason optionally.

=head2 C<$botE<lt>modeE<gt>(target =E<gt> $nick|$channel, mode =E<gt> "+o iblech")>

Performs the C</MODE> command. Note that you can supply both a nickname and a
channel name to the C<target> parameter.

=head2 C<$botE<lt>inviteE<gt>(channel =E<gt> "#chan", target =E<gt> "nick")>

Invites C<nick> to C<#chan>.

=head2 C<$botE<lt>operE<gt>(username =E<gt> "...", password =E<gt> "...")>

Tries to gain IRC operator rights.

=head2 C<$botE<lt>privmsgE<gt>(to =E<gt> "...", text =E<gt> "...")>,
C<$botE<lt>noticeE<gt>(to =E<gt> "...", text =E<gt> "...")>

Sends a C<PRIVMSG> or a C<NOTICE> to a destination.

B<Note>: A bot should I<always> use C<NOTICE> to send replies. Quoting L<RFC
1459|http://www.ietf.org/rfc/rfc1459.txt>:

  The NOTICE message is used similarly to PRIVMSG.  The difference between
  NOTICE and PRIVMSG is that automatic replies must never be sent in response
  to a NOTICE message.  This rule applies to servers too - they must not send
  any error reply back to the client on receipt of a notice.  The object of
  this rule is to avoid loops between a client automatically sending something
  in response to something it received.  This is typically used by automatons
  (clients with either an AI or other interactive program controlling their
  actions) which are always seen to be replying lest they end up in a loop with
  another automaton.

=head2 C<$botE<lt>rawE<gt>("...")>

Sends a command to the server. The command is not modified by C<Net::IRC>,
aside from appending the correct newline characters.

=head1 PSEUDO EVENTS

=head2 C<loggedin>

The C<loggedin> event is fired when the bot has successfully logged in.

=head2 C<runloop>

The C<runloop> event is fired when an iteration of the main runloop is
finished.

=head1 FLOODCONTROL

Most IRC servers disconnect you if you post too many commands in too short time.

If you supply C<:floodcontrol(1)> to the constructor, C<Net::IRC> won't simply
send all commands immediately to the server, but creates a queue, which is then
slowly sent to the server.

=head1 EXAMPLES

See F<examples/network/seenbot.pl>, F<examples/network/logbot.pl> and
F<examples/network/svnbot.pl> in the L<Pugs Subversion
Repository|svn.pugscode.org/pugs/> for example bots using C<Net::IRC>.

=head1 AUTHOR

Ingo Blechschmidt <iblech@web.de>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlgpl> and L<perlartistic> for details.

=cut
