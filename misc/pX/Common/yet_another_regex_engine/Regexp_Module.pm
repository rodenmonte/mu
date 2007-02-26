# CONTENTS
# Regexp Engine
#  package Regexp::ModuleA::ReentrantEngine;
#    package Regexp::ModuleA::ReentrantEngine::BacktrackMacros;
#    package Regexp::ModuleA::AST::BaseClass;
#  ...
#    package Regexp::ModuleA::AST::Namespace;
#   package Regexp::ModuleA::ReentrantEngine::Match;
# AST
#  package Regexp::ModuleA::AST
#   package Regexp::ModuleA::AST::Make0;
#   package Regexp::ModuleA::AST::BaseClass;
#  ...
#   package Regexp::ModuleA::AST::Namespace;
# P5 regexps
#  package Regexp::ModuleA::P5;
# P6 regexps
#  package Regexp::ModuleA::P6;
# Rx
#  package Regexp::ModuleA::Rx;
# Api
#  package Regexp::ModuleA::Api::GrammarA;
#  package Regexp::ModuleA::Api::FilterWithenvA;
#  package Regexp::ModuleA::Api::FilterRegexDefinitionsA;
#  package Regexp::ModuleA::Api::PreludeA;
#  package Regexp::ModuleA::Api::GatherMethodsA;
# Read-eval-print loop
#  package Regexp::ModuleA::Interactive
# Command-line and glue.

package Regexp::ModuleA;
use strict;
use warnings;
use Carp;

#======================================================================
# Regexp Engine RMARE
#
# CAUTION: Moving the Engine to later in this file causes the perlbug
# workaround to stop working in perl v5.8.8. :(

package Regexp::ModuleA::ReentrantEngine;

{
  package Regexp::ModuleA::ReentrantEngine::BacktrackMacros;
  
  my @_let_stack;
  sub _let_gen {
    my($vars)=@_;
    my $nvars = 1+($vars =~ tr/,//);
    my $tmpvars = join(",",map{"\$__tmp${_}__"}(0..($nvars-1)));
    push(@_let_stack,[$vars,$tmpvars]);
    "(do{my \$__v__ ; my($tmpvars); { local($vars)=($vars); \$__v__ = do{ ";
  }
  sub _let_end {
    my $e = shift(@_let_stack) || die "LET(){ }LET pairs didn't match up";
    my($vars,$tmpvars) = @$e;
    "}; if(!FAILED(\$__v__)){ ($tmpvars)=($vars); }}; if(!FAILED(\$__v__)){ ($vars)=($tmpvars) }; \$__v__ })"
    }
  sub filter_string {
    my($s)=@_;
    local $_ = $s;
    s/\bLET\(([^\)]+)\)\{/_let_gen($1)/eg;
    s/\}LET;/_let_end().";"/eg;
    s/\bFAIL_IF_FAILED\(([^\)]+)\);/return($1) if FAILED($1);/g;
    s/\bFAIL\(([^\)]{0,0})\)/return undef/g;
    s/\bFAIL_SEQUENCE\(([^\)]{0,0})\)/die "fail sequence\n"/g;
    s/\bFAIL_GROUP\(([^\)]{0,0})\)/die "fail group\n"/g;
    s/\bFAIL_REGEX\(([^\)]{0,0})\)/die "fail regex\n"/g;
    s/\bFAIL_MATCH\(([^\)]{0,0})\)/die "fail match\n"/g;
    s/\bFAILED\(([^\)]+)\)/(!defined($1)||(!ref($1)&&($1<=0)))/g;
    s/\bTAILCALL\(([^,\)]+),?([^\)]*)\);/\@_=($2);goto \&$1;/g;
    $_;
  }
  use Filter::Simple sub {
    $_ = filter_string($_);
    #print STDERR $_;
    $_;
  };
  1;
}
BEGIN { Regexp::ModuleA::ReentrantEngine::BacktrackMacros->import; };

use strict;
use warnings;

local $Regexp::ModuleA::ReentrantEngine::Env::str;
local $Regexp::ModuleA::ReentrantEngine::Env::pos;
local $Regexp::ModuleA::ReentrantEngine::Env::current_match;
local $Regexp::ModuleA::ReentrantEngine::Env::leaf_match;
local $Regexp::ModuleA::ReentrantEngine::Env::pkg;
local $Regexp::ModuleA::ReentrantEngine::Env::nested_data;
#local $Regexp::ModuleA::ReentrantEngine::Env::stop;

{
  package Regexp::ModuleA::AST::BaseClass;

  use Sub::Name;
  my $sub_id = 1;

  sub RMARE_emit {
    my $cls = ref($_[0]);
    die "bug: $cls RMARE_emit() unimplemented\n";
  }

  my $noop;
  $noop = subname "<noop ".($sub_id++).">" => sub {
    my $c = $_[0];
    return 1 if !defined($c) || $c eq $noop;
    TAILCALL($c,$noop);
  };
  sub RMARE_noop { $noop }
  sub RMARE_is_noop {
    my($o,$c)=@_;
    return 1 if !defined($c) || $c eq $noop;
    return 0;
  }

  sub RMARE_eat_backref {
    my($o,$idx,$mod5_re)=@_;
    my $noop = $o->RMARE_noop;
    subname "<eat_backref ".($sub_id++).">" => sub {
      my $c = $_[0];
      my $a = $$Regexp::ModuleA::ReentrantEngine::Env::current_match->{match_array};
      FAIL() if $idx >= @$a;
      my $m = $a->[$idx];
      FAIL() if !defined($m) || !$m->match_boolean;
      my $re = $m->match_string;
      $re =~ s/(\W)/\\$1/g;

      my($str) = $Regexp::ModuleA::ReentrantEngine::Env::str;
      pos($str) = $Regexp::ModuleA::ReentrantEngine::Env::pos;
      $str =~ /\G$mod5_re($re)/ or FAIL();
      $Regexp::ModuleA::ReentrantEngine::Env::pos += length($1);
      TAILCALL($c,$noop);
    };
  }
  { use re 'eval';
  sub RMARE_eat_regexp {
    my($o,$re)=@_;
    my $noop = $o->RMARE_noop;
    my $qr = qr/\G($re)/;
    subname "<eat_regexp ".($sub_id++).">" => sub {
      my $c = $_[0];

      my($str) = $Regexp::ModuleA::ReentrantEngine::Env::str;
      pos($str) = $Regexp::ModuleA::ReentrantEngine::Env::pos;
      $str =~ $qr or FAIL();
      $Regexp::ModuleA::ReentrantEngine::Env::pos += length($1);
      TAILCALL($c,$noop);
    }
  }
  }
  sub RMARE_imsx {
    my($o)=@_;
    my $mod = "";
    $mod .= "i" if $o->{flags}{i};
    $mod .= "m" if $o->{flags}{m};
    $mod .= "s" if $o->{flags}{s};
    $mod .= "x" if $o->{flags}{x};
    $mod;
  }
  sub RMARE_wrap_re_with_mods {
    my($o,$re)=@_;
    my $mod = $o->RMARE_imsx;
    return $re if $mod eq "";
    "(?$mod:$re)";
  }
  sub RMARE_alt {
    my($o,$aref)=@_;
    die "bug $aref" if ref($aref) ne 'ARRAY';
    my @fs = @$aref;
    subname "<alt ".($sub_id++).">" => sub {
      my $c = $_[0];
      for my $f (@fs) {
        my $v = LET($Regexp::ModuleA::ReentrantEngine::Env::pos){
          my $v1 = eval { $f->($c) }; #try
          if($@) {
            next if $@ eq "fail sequence\n";
            die $@ unless $@ eq "fail group\n";
            FAIL();
          }
          $v1;
        }LET;
        return $v if not FAILED($v);
      }
      FAIL();
    };
  }
  sub RMARE_group {
    my($o,$f)=@_;
    subname "<group ".($sub_id++).">" => sub {
      my $cn = $_[0];
      my $nd = $Regexp::ModuleA::ReentrantEngine::Env::nested_data;
      my $close = sub {
        my($c)=@_;
        $Regexp::ModuleA::ReentrantEngine::Env::nested_data = $nd;
        my $v = eval { $cn->($c) };
        if($@) {
          die 'jump '.$@ if $@ =~ /^fail /;
          die $@;
        }
        return $v;
      };
      my $v = eval {$f->($close)}; #try
      if($@) {
        die $1 if $@ =~ /^jump (.+)/s;
        die $@ unless $@ eq "fail group\n" || $@ eq "fail sequence\n";
        FAIL();
      }
      return $v;
    };
  }
  sub RMARE_conj {
    my($o,$aref)=@_;
    die "bug $aref" if ref($aref) ne 'ARRAY';
    my @fs = @$aref;
    my $noop = $o->RMARE_noop;
    return $noop if @fs == 0;
    return $fs[0] if @fs == 1;
    my $code1 = "()"; my $code2 = "";
    my $code0 = "my \$f0 = \$fs[0]; ";
    { my $i = $#fs;
      $code0 .= "";
      $code1 = 'sub {
  FAIL() if $__end__ != $Regexp::ModuleA::ReentrantEngine::Env::pos;
  @_='.$code1;
      $code2 .= ";\ngoto \&\$cn}";
    }
    for my $i (reverse(2..$#fs)) {
      $code0 .= "my \$f$i = \$fs[$i]; ";
      $code1 = 'sub {
  FAIL() if $__end__ != $Regexp::ModuleA::ReentrantEngine::Env::pos;
  $Regexp::ModuleA::ReentrantEngine::Env::pos = $__start__;
  @_='.$code1;
      $code2 .= ";\ngoto \&\$f$i}";
    }
    { my $i = 1;
      $code0 .= "my \$f$i = \$fs[$i]; ";
      $code1 = 'sub {
  $__end__ = $Regexp::ModuleA::ReentrantEngine::Env::pos;
  $Regexp::ModuleA::ReentrantEngine::Env::pos = $__start__;
  @_='.$code1;
      $code2 .= ";\ngoto \&\$f$i}";
    }
    my $code = $code0."
#line 2 \"Regexp::ModuleA::AST::BaseClass RMARE_conj\"
\n subname '<conj '.(\$sub_id++).'>' => sub {my \$cn = \$_[0];
  my \$__start__ = \$Regexp::ModuleA::ReentrantEngine::Env::pos;
  my \$__end__ = undef;
  my \$__f__ = ".$code1.$code2.';
    LET($Regexp::ModuleA::ReentrantEngine::Env::pos){
      $f0->($__f__);
    }LET;
  '."}\n";
    #print STDERR $code;
    # Currently expanded in the string itself. :/
    # $code = Regexp::ModuleA::ReentrantEngine::BacktrackMacros::filter_string($code);
    eval($code) || die "$@";
  }   
  sub RMARE_concat {
    my($o,$aref)=@_;
    die "bug $aref" if ref($aref) ne 'ARRAY';
    my @a = @$aref;
    return $o->RMARE_noop if @a == 0;
    return $a[0]->RMARE_emit if @a == 1;
    my @fs = map { $_->RMARE_emit } @a;
    my $code1 = ""; my $code2 = "";
    my $code0 = "my \$f0 = \$fs[0]; ";
    for my $i (reverse(1..$#a)) {
      $code0 .= "my \$f$i = \$fs[$i]; ";
      $code1 .= "sub {\@_=";
      $code2 .= ";goto \&\$f$i}";
    }
    my $code = $code0."
#line 2 \"Regexp::ModuleA::AST::BaseClass RMARE_concat\"
\n subname '<concat '.(\$sub_id++).'>' => sub {my \$cn = \$_[0]; \@_=".$code1."\$cn".$code2.";goto \&\$f0}\n";
    eval($code) || die "$@";
  }   
  my $repeat_id = 1;
  our(%repeat_count,%repeat_previous_pos);
  local %repeat_count;
  local %repeat_previous_pos;
  sub RMARE_repeat {
    my($o,$f,$min,$max,$ng)=@_;
    my $greedy = !$ng ? 1 : 0;
    my $noop = $o->RMARE_noop;
    my $myid = $sub_id++;
    subname "<repeat ".($myid).">" => sub {
      if(!defined $noop){die "this perl v5.8.8 bug workaround line didn't work"}
      my $c = $_[0];
      my $rid = $repeat_id++;
      local $repeat_previous_pos{$rid} = -1;
      local $repeat_count{$rid} = 0;
      my($get_minimum,$try_getting_more);
      $get_minimum = subname "get_minimum" => sub {
        if($repeat_count{$rid} < $min) {
          local $repeat_count{$rid} = $repeat_count{$rid} +1;
          $f->($get_minimum);
        } else {
          goto &$try_getting_more;
        }
      };
      $try_getting_more = subname "try_getting_more" => sub {
        if( !($repeat_previous_pos{$rid} < $Regexp::ModuleA::ReentrantEngine::Env::pos) ||
            !($repeat_count{$rid} < $max))
        {
          TAILCALL($c,$noop);
        }
        local $repeat_previous_pos{$rid} = $Regexp::ModuleA::ReentrantEngine::Env::pos;
        local $repeat_count{$rid} = $repeat_count{$rid} +1;
        
        my $v = LET($Regexp::ModuleA::ReentrantEngine::Env::pos){
          $greedy ? $f->($try_getting_more) : $c->($noop);
        }LET;
        return $v if not FAILED($v);
        if($greedy){
          TAILCALL($c,$noop); # tailcall ok despite locals.
        } else {
          $f->($try_getting_more);
        }
      };
      $get_minimum->();
    };
  }
  sub RMARE_capture {
    my($o,$idx,$f,$is6,$nparen6)=@_;
    my $myid = $sub_id++;
    subname "<capture ".($myid).">" => sub {
      my $c = $_[0];

      my $from = $Regexp::ModuleA::ReentrantEngine::Env::pos;
      my $nd = $Regexp::ModuleA::ReentrantEngine::Env::nested_data;
      my $leaf = $Regexp::ModuleA::ReentrantEngine::Env::leaf_match;

      my $m = Regexp::ModuleA::ReentrantEngine::Match0->new_failed();
      if($is6) {
        my $a = [map{Regexp::ModuleA::ReentrantEngine::Match0->new_failed()} (1..$nparen6)];
        $$m->{match_array} = $a;
      }

      my $close = subname '<capture-close '.($myid).">" => sub {
        my $c0 = $_[0];
        $Regexp::ModuleA::ReentrantEngine::Env::nested_data = $nd;
        $Regexp::ModuleA::ReentrantEngine::Env::leaf_match = $leaf if $is6;
        my $to = $Regexp::ModuleA::ReentrantEngine::Env::pos;
        $m->match_set(1,substr($Regexp::ModuleA::ReentrantEngine::Env::str,$from,$to-$from),$$m->{match_array},$$m->{match_hash},$from,$to);
        my $v = eval { $c0->($c) };
        if($@) {
          die 'jump '.$@ if $@ =~ /^fail /;
          die $@;
        }
        return $v;
      };

      return LET($$Regexp::ModuleA::ReentrantEngine::Env::leaf_match->{match_array}){
        my $newa = [@{$$Regexp::ModuleA::ReentrantEngine::Env::leaf_match->{match_array}}];
        $$Regexp::ModuleA::ReentrantEngine::Env::leaf_match->{match_array} = $newa;
        $newa->[$idx] = $m;

        local $Regexp::ModuleA::ReentrantEngine::Env::leaf_match = $is6 ? $m : $leaf;

        my $v = eval { $f->($close) }; #try
        if($@) {
          die $1 if $@ =~ /^jump (.+)/s;
          die $@ unless $@ eq "fail group\n" || $@ eq "fail sequence\n";
          $m->match_set_as_failed;
          FAIL();
        }
        $m->match_set_as_failed if FAILED($v);
        $v;
      }LET;
    };
  }
  sub RMARE_subrule {
    my($o,$fetch,$pkg,$name,$args,$neg,$nocap)=@_;
    my $noop = $o->RMARE_noop;
    my $myid = $sub_id++;
    subname "<subrule ".($myid)." $name>" => sub {
      my($c)=@_;
      my $f = $fetch->(@$args);

      my $pkg0 = $Regexp::ModuleA::ReentrantEngine::Env::pkg;
      my $pkg9 = $Regexp::ModuleA::ReentrantEngine::Env::pkg || $pkg;

      my $pos = $Regexp::ModuleA::ReentrantEngine::Env::pos;
      my $m0 = $Regexp::ModuleA::ReentrantEngine::Env::current_match;
      my $m0b = $Regexp::ModuleA::ReentrantEngine::Env::leaf_match;

      my $nd = $Regexp::ModuleA::ReentrantEngine::Env::nested_data;

      my $m1 = Regexp::ModuleA::ReentrantEngine::Match0->new_failed;
      $m1->match_set(1,"",[],{},$pos,undef);
      $$m1->{'RULE'} ||= $name; #EEEP

      my $close = subname "<subrule-close ".($myid)." $name>" => sub {
	my $cn = $_[0];

        $Regexp::ModuleA::ReentrantEngine::Env::nested_data = $nd;

	$$m1->{'match_to'} = $Regexp::ModuleA::ReentrantEngine::Env::pos; #EEEP
	$$m1->{'match_string'} = substr($Regexp::ModuleA::ReentrantEngine::Env::str,$pos,$Regexp::ModuleA::ReentrantEngine::Env::pos-$pos);

        my $post = $name."__post_action";
        if(UNIVERSAL::can($pkg9,$post)) {
          $m1->_match_enable_overload1;
          $pkg9->$post($m1);
        }

	$Regexp::ModuleA::ReentrantEngine::Env::current_match = $m0;
	$Regexp::ModuleA::ReentrantEngine::Env::leaf_match = $m0b;
	local $Regexp::ModuleA::ReentrantEngine::Env::pkg = $pkg0;

        LET($$m0->{'match_hash'}{$name}){
          $$m0->{'match_hash'}{$name} = [@{$$m0->{'match_hash'}{$name}||[]}];
          push(@{$$m0->{'match_hash'}{$name}},$m1);
          $neg ? 1 : $cn->($c);
        }LET;
      };

      my $v;
      { local $Regexp::ModuleA::ReentrantEngine::Env::current_match = $m1;
        local $Regexp::ModuleA::ReentrantEngine::Env::leaf_match = $m1;
        local $Regexp::ModuleA::ReentrantEngine::Env::pkg = $pkg0;
        local $Regexp::ModuleA::ReentrantEngine::Env::nested_data->{args} = $args;
	$v = eval { $f->($close) };
        if($@) {
          die $@ unless $@ eq "fail regex\n";
          FAIL() if !$neg;
          $v = undef; # FAILED #X
        }
      }
      if($neg) {
        if(FAILED($v)) {
          $$m1->{'match_to'} = $$m1->{'match_from'};
          $$m1->{'match_string'} = "";

          LET($$m0->{'match_hash'}{$name}){
            $$m0->{'match_hash'}{$name} = [@{$$m0->{'match_hash'}{$name}||[]}];
            push(@{$$m0->{'match_hash'}{$name}},$m1);
            $c->($noop);
          }LET;

        } else {
          FAIL();
        }
      } else {
        FAIL_IF_FAILED($v);
        return $v;
      }
    };
  }
  sub RMARE_aregex {
    my($o,$f)=@_;
    my $nparenx = $o->{flags}{p5} ? $o->{nparen} : $o->{nparen6};
    $nparenx = 0 if !defined $nparenx; #XXX arguments to subrules.  aregex not seeing an init.
    subname "<aregex ".($sub_id++).">" => sub {
      my($c)=@_;

      my $m = $Regexp::ModuleA::ReentrantEngine::Env::leaf_match;
      my $a = [map{Regexp::ModuleA::ReentrantEngine::Match0->new_failed()} (1..$nparenx)];
      $$m->{match_array} = $a;

      my $v = eval { $f->($c) }; #try
      if($@) {
        die $@ unless ($@ eq "fail group\n" ||
                       $@ eq "fail sequence\n");
        FAIL();
      }
      $v;
    };
  }
  sub RMARE_do_match {
    my($o,$f,$s,$beginat,$minlen)=@_;
    my $nparen = $o->{nparen};
    my $len = length($s);
    $beginat = 0 if !defined($beginat);
    my $noop = $o->RMARE_noop;
    my $atend = $noop;
    if(defined $minlen) {
      my $min_end = $minlen + $beginat;
      $atend = subname "<atend ".($sub_id++).">" => sub {return undef if $Regexp::ModuleA::ReentrantEngine::Env::pos < $min_end;return 1;}
    }
    for my $start ($beginat..$len) {
      local $Regexp::ModuleA::ReentrantEngine::Env::str = $s;
      local $Regexp::ModuleA::ReentrantEngine::Env::pos = $start;
      my $m = Regexp::ModuleA::ReentrantEngine::Match0->new_failed();
      local $Regexp::ModuleA::ReentrantEngine::Env::current_match = $m;
      local $Regexp::ModuleA::ReentrantEngine::Env::leaf_match = $m;
      local $Regexp::ModuleA::ReentrantEngine::Env::nested_data = {};
      $Regexp::ModuleA::ReentrantEngine::Env::nested_data->{args} = [];
      
      my $ok = eval { $f->($atend) }; #try
      if($@) {
        die $@ unless ($@ eq "fail match\n" || $@ eq "fail regex\n" ||
                       $@ eq "fail group\n" || $@ eq "fail sequence\n");
        last;
      }
      if(not FAILED($ok)) {
        $m->match_set(1,substr($Regexp::ModuleA::ReentrantEngine::Env::str,$start,$Regexp::ModuleA::ReentrantEngine::Env::pos-$start),$$m->{match_array},$$m->{'match_hash'},$start,$Regexp::ModuleA::ReentrantEngine::Env::pos);
        return $m;
      }
    }
    return Regexp::ModuleA::ReentrantEngine::Match0->new_failed();
  }
  sub RMARE_commit_sequence {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    subname "<commit_sequence ".($sub_id++).">" => sub {
      my($c)=@_;
      my $v = $c->($noop);
      FAIL_SEQUENCE() if FAILED($v);
      return $v;
    };
  }
  sub RMARE_commit_group {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    subname "<commit_group ".($sub_id++).">" => sub {
      my($c)=@_;
      my $v = $c->($noop);
      FAIL_GROUP() if FAILED($v);
      return $v;
    };
  }
  sub RMARE_commit_regex {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    subname "<commit_regex ".($sub_id++).">" => sub {
      my($c)=@_;
      my $v = $c->($noop);
      FAIL_REGEX() if FAILED($v);
      return $v;
    };
  }
  sub RMARE_commit_match {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    subname "<commit_regex ".($sub_id++).">" => sub {
      my($c)=@_;
      my $v = $c->($noop);
      FAIL_MATCH() if FAILED($v);
      return $v;
    };
  }

  sub RMARE_independent {
    my($o,$f)=@_;
    my $noop = $o->RMARE_noop;
    subname "<independent ".($sub_id++).">" => sub {
      my $cn = $_[0];
      my $uid = "independent ".rand()."\n";
      my $nbt = sub {
        my $c = $_[0];
        my $v = $c->($cn);
        die $uid if FAILED($v);
        $v;
      };
      my $v = eval { $f->($nbt) };
      if($@) {
        die if $@ ne $uid;
        FAIL();
      }
      $v;
    };
  }

}
{
  # any regexp
  package Regexp::ModuleA::AST::Pat5;
  sub RMARE_emit {
    my($o)=@_;
    my $re = $o->RMARE_wrap_re_with_mods($o->{pat});
    $o->RMARE_eat_regexp($re);
  }
  
  # \Qabc\E
  package Regexp::ModuleA::AST::Exact;
  sub RMARE_emit {
    my($o)=@_;
    my $re = $o->{text};
    $re =~ s/([^\w\s])/\\$1/g;
    $re = $o->RMARE_wrap_re_with_mods($re);
    $o->RMARE_eat_regexp($re);
  }

  # (?imsx-imsx:...)
  package Regexp::ModuleA::AST::Mod_expr;
  sub RMARE_emit {
    my($o)=@_;
    $o->{expr}->RMARE_emit;
  }
  
  # (?imsx-imsx)
  package Regexp::ModuleA::AST::Mod_inline;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_noop;
  }

  # ? * + {n,m} ?? *? etc
  package Regexp::ModuleA::AST::Quant;
  sub RMARE_emit {
    my($o)=@_;
    my($min,$max,$nongreedy)= (@$o{'min','max','nongreedy'});
    $min = 0 if !defined $min;
    $max = 1000**1000**1000 if !defined $max; #XXX inf
    die "assert - Quant min <= max" if $min > $max;
    my $f = $o->{expr}->RMARE_emit;
    $o->RMARE_repeat($f,$min,$max,$nongreedy);
  }

  # a|b
  package Regexp::ModuleA::AST::Alt;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_alt([map{$_->RMARE_emit}@{$o->{exprs}}]);
  }
  
  # a&b
  package Regexp::ModuleA::AST::Conj;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_conj([map{$_->RMARE_emit}@{$o->{exprs}}]);
  }
  
  # ab
  package Regexp::ModuleA::AST::Seq;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_concat($o->{exprs});
  }
  
  # (?:a)
  package Regexp::ModuleA::AST::Grp;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_group($o->{expr}->RMARE_emit);
  }
  
  # (a)
  package Regexp::ModuleA::AST::Cap;
  sub RMARE_emit {
    my($o)=@_;
    my $is6 = !$o->{flags}{'p5'};
    my $idx = ($is6
               ? $o->{cap6_idx}
               : $o->{cap5_idx});
    my $f = $o->{expr}->RMARE_emit;
    $o->RMARE_capture($idx,$f,$is6,$o->{nparen6});
  }
  
  # \1
  package Regexp::ModuleA::AST::Backref;
  sub RMARE_emit {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    my $idx = $o->{'backref_n'} -1;
    $o->RMARE_eat_backref($idx,'(?'.$o->RMARE_imsx.')');
  } #XXX move imsx into eat
  
  # <foo>
  package Regexp::ModuleA::AST::Subrule;
  use Sub::Name;
  sub RMARE_emit {
    my($o)=@_;
    my $exprs = $o->{exprs};
    my $pkg = $o->{pkg};
    my $name = $o->{name};
    my $neg = $name =~ /!/;
    my $nocap = $name =~ /\?/;
    $name =~ s/^[?!]+//;
    my $fetch = subname "<subrule-fetch for $name>" => sub {
      my $pkg9 = $Regexp::ModuleA::ReentrantEngine::Env::pkg || $pkg;
      die "assert" if !defined $pkg9;
      no strict;
      my $f = $pkg9->$name($name)->(' api0');
      use strict;
      die "assert" if !defined $f;
      $f;
    };
    $o->RMARE_subrule($fetch,$pkg,$name,[map{$_->RMARE_emit} @$exprs],$neg,$nocap);
  }
  
  # rx/a/
  package Regexp::ModuleA::AST::ARegex;
  use Sub::Name;
  sub RMARE_emit {
    my($o)=@_;
    my $pkg = $o->{pkg};
    my $name = $o->{name};
    my $f = $o->RMARE_aregex($o->{expr}->RMARE_emit);
    # Why the extra sub?  60+% shorter re_text runtime.  sigh.
    my $matchergen = sub { subname "<an aregex-matcher for $o>" => sub {
      my($pkg9,$name1,$s,$beginat,$minlen)=@_;
      local $Regexp::ModuleA::ReentrantEngine::Env::pkg = $pkg9;
      my $m = $o->RMARE_do_match($f,$s,$beginat,$minlen);
      $m->_match_enable_overload2;
      $$m->{RULE} = $name1;
      if($name1) {
        my $post = $name1."__post_action";
        $pkg9->$post($m) if UNIVERSAL::can($pkg9,$post);
      }
      $m;
    } };
    Regexp::ModuleA::Rx->_new_from_ast($o,$pkg,$name,$f,$matchergen);
  }    
  
  # regex foo /a/; rule foo /a/; token foo /a/
  package Regexp::ModuleA::AST::Bind;
  use Sub::Name;
  sub RMARE_emit {
    my($o)=@_;
    my $pkg = $o->{pkg};
    my $name = $o->{name};
    my $fr = $o->{expr}->RMARE_emit;
    eval("package $pkg; *$name = \$fr"); die "assert" if $@;
    $fr;
  }
  
  # grammar Foo::Bar { ... }
  package Regexp::ModuleA::AST::Namespace;
  sub RMARE_emit {
    my($o)=@_;
    my $pkg = $o->{pkg};
    eval("package $pkg;"); die "assert" if $@;
    map{$_->RMARE_emit;} @{$o->{bindings}};
  }

  # XXX high klude factor
  # (?{ ... })
  package Regexp::ModuleA::AST::Code;
  sub RMARE_emit {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    my $code = $o->{'code'};
    $code = "''" if $code =~ /\A\s*\z/;
    my $tmp = Regexp::ModuleA::AST::CodeRx::_rewrite_matchvars($o,$code);
    my $need_match = $code ne $tmp || $code =~ /\$M\b/;
    $code = $tmp;
    my $src = '
#line 2 "in Regexp::ModuleA::Code"
sub{my $__c__ = $_[0];
'.(!$need_match ? '' :
'  my $M = $Regexp::ModuleA::ReentrantEngine::Env::current_match;
  $M->_match_enable_overload1;').'
 '.$code.';
 $__c__->($noop);}';
    #print STDERR $src,"\n";
    eval($src) || die "Error compiling (?{$code}) :\n$@\n";
  }

  # XXX high klude factor
  # (??{ ... })
  package Regexp::ModuleA::AST::CodeRx;
  sub RMARE_emit {
    my($o)=@_;
    my $code = $o->{'code'};
    $code = "''" if $code =~ /\A\s*\z/;
    my $tmp = $o->_rewrite_matchvars($code);
    my $need_match = $code ne $tmp || $code =~ /\$M\b/;
    $code = $tmp;
    #XXX Really need to PPI the code.
    my $has_local = $code =~ /\blocal\b/;
    my $has_semi = $code =~ /;/;
    $code = ($has_semi && !$has_local) ? "do{$code}" : "($code)";
    warn "(??{...}) currently doesnt support code with multiple statments and local()" if $has_local && $has_semi;
    my $src = '
#line 2 "in Regexp::ModuleA::CodeRx"
sub{my $__c__ = $_[0];
'.(!$need_match ? '' :
'  my $M = $Regexp::ModuleA::ReentrantEngine::Env::current_match;
  $M->_match_enable_overload1;').'
  my $__rx__ = '.$code.';
  die "(??{...}) returned undef" if !defined $__rx__;
#  $__rx__ = "(?!)" if !defined $__rx__;
  my $__f__ = (ref($__rx__) eq "Regexp" || !ref($__rx__)) ? $o->RMARE_eat_regexp("$__rx__") : $__rx__->(" api0");
  $__f__->($__c__) }';
    #print STDERR $src,"\n";
    eval($src) || die "Error compiling (?{$code}) :\n$@\n";
  }
  sub _rewrite_matchvars {
    my($o_ignored,$s)=@_;
    local $_ = $s;
    s/\$([1-9])/'$M->['.($1-1).']'/eg; #XXX more...
    $_;
  }

  # (?>)
  package Regexp::ModuleA::AST::Independent;
  sub RMARE_emit {
    my($o)=@_;
    my $f = $o->{expr}->RMARE_emit;
    $o->RMARE_independent($f);
  }

  # (?(n)t|f)
  package Regexp::ModuleA::AST::Conditional;
  sub RMARE_emit {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    my $f_test;
    my $f_then = $o->{expr_then}->RMARE_emit;
    my $f_else = ($o->{expr_else}
                  ? $o->{expr_else}->RMARE_emit
                  : sub{my $c = $_[0]; TAILCALL($c,$noop);});
    if($o->{test} !~ /\A\d+\z/) {
      $f_test = $o->{test}->RMARE_emit;
    } else {
      my $idx = $o->{test} +0;
      $f_test = sub {
        my $c = $_[0];
        my $a = $Regexp::ModuleA::ReentrantEngine::Env::current_match->match_array;
        FAIL() if $idx > @$a;
        my $m = $a->[$idx-1];
        FAIL() if !$m->match_boolean;
        TAILCALL($c,$noop);
      };
    }
    sub {
      my $c = $_[0];
      my $v;
      { local($Regexp::ModuleA::ReentrantEngine::Env::pos)=($Regexp::ModuleA::ReentrantEngine::Env::pos);
        $v = $f_test->($noop);
      }
      if(not FAILED($v)) {
        TAILCALL($f_then,$c);
      } else {
        TAILCALL($f_else,$c);
      }
    };
  }

  # (?=) (?<=) (?!) (?<!)
  package Regexp::ModuleA::AST::Lookaround;
  sub RMARE_emit {
    my($o)=@_;
    my $noop = $o->RMARE_noop;
    my $f = $o->{expr}->RMARE_emit;
    my $is_forward = $o->{is_forward};
    my $is_positive = $o->{is_positive};
    if($is_positive) {
      if($is_forward) {
        sub {
          my $c = $_[0];
          { local($Regexp::ModuleA::ReentrantEngine::Env::pos)=($Regexp::ModuleA::ReentrantEngine::Env::pos);
            my $v = $f->($noop);
            FAIL_IF_FAILED($v);
          }
          TAILCALL($c,$noop);
        }
      } else {
        sub {
          my $c = $_[0];
          FAIL() if not &_is_found_backwards($f);
          TAILCALL($c,$noop);
        }
      }
    } else {
      if($is_forward) {
        sub {
          my $c = $_[0];
          my $v;
          { local($Regexp::ModuleA::ReentrantEngine::Env::pos)=($Regexp::ModuleA::ReentrantEngine::Env::pos);
            $v = $f->($noop);
            FAIL() if not FAILED($v);
          }
          TAILCALL($c,$noop);
        };
      } else {
        sub {
          my $c = $_[0];
          FAIL() if &_is_found_backwards($f);
          TAILCALL($c,$noop);
        };
      }
    }
  }
  sub _is_found_backwards {
    my($f)=@_;
    my $pos = $Regexp::ModuleA::ReentrantEngine::Env::pos;
    local $Regexp::ModuleA::ReentrantEngine::Env::pos = $Regexp::ModuleA::ReentrantEngine::Env::pos;
    my $at_pos = sub{ FAIL() if $Regexp::ModuleA::ReentrantEngine::Env::pos != $pos; return 1;};
    for(my $i = $Regexp::ModuleA::ReentrantEngine::Env::pos;$i>=0;$i--) {
      $Regexp::ModuleA::ReentrantEngine::Env::pos = $i;
      my $v = $f->($at_pos);
      return 1 if not FAILED($v);
    }
    return 0;
  }

  # nonexistent
  package Regexp::ModuleA::AST::CommitSequence;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_commit_sequence();
  }

  # ::
  package Regexp::ModuleA::AST::CommitGroup;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_commit_group();
  }

  # :::
  package Regexp::ModuleA::AST::CommitRegex;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_commit_regex();
  }

  # <commit>
  package Regexp::ModuleA::AST::CommitMatch;
  sub RMARE_emit {
    my($o)=@_;
    $o->RMARE_commit_match();
  }

}

#======================================================================
# Match
#
{
  package Regexp::ModuleA::ReentrantEngine::Match2;
  @Regexp::ModuleA::ReentrantEngine::Match2::ISA =
    qw(Regexp::ModuleA::ReentrantEngine::Match0);

  use overload
    'bool' => 'match_boolean',
    '""'   => 'match_string',
    '@{}'  => 'match_array',
    '%{}'  => 'match_hash',
    ;

  sub _match_enable_overload2 { }
  sub _match_enable_overload1 { die "assert not reached" }

  package Regexp::ModuleA::ReentrantEngine::Match1;
  @Regexp::ModuleA::ReentrantEngine::Match1::ISA =
    qw(Regexp::ModuleA::ReentrantEngine::Match0);

  use overload
    'bool' => 'match_boolean',
    '""'   => 'match_string',
    '@{}'  => 'match_array',
    '%{}'  => 'match_hash',
    ;

  # sub _match_enable_overload1 is still required.

  package Regexp::ModuleA::ReentrantEngine::Match0;

  sub _match_enable_overload2 {
    my($o)=@_;
    for my $m (@{$o->match_array}) { $m->_match_enable_overload2 }
    for my $m (map{@$_}values %{$o->match_hash}) { $m->_match_enable_overload2 }
    bless $o, 'Regexp::ModuleA::ReentrantEngine::Match2';
  }
  sub _match_enable_overload1 {
    my($o)=@_;
    for my $m (@{$o->match_array}) { $m->_match_enable_overload1 }
    for my $m (map{@$_}values %{$o->match_hash}) { $m->_match_enable_overload1 }
    bless $o, 'Regexp::ModuleA::ReentrantEngine::Match1';
  }

  sub match_boolean {${$_[0]}->{match_boolean}}
  sub match_string  {${$_[0]}->{match_string}}
  sub match_array   {${$_[0]}->{match_array}}
  sub match_hash    {${$_[0]}->{match_hash}}

  sub from          {${$_[0]}->{match_from}}
  sub to            {${$_[0]}->{match_to}}

  sub match_value   {${$_[0]}->{match_value}}

  sub new_failed {my($cls)=@_; $cls->new()->match_set_as_failed()}
  sub new {
    my($cls)=@_;
    my $h = {
      match_boolean => 1,
      match_string  => "",
      match_array   => [],
      match_hash    => {},
      match_from    => undef,
      match_to      => undef,
      match_value   => undef
      };
    my $o = \$h;
    bless $o,$cls;
    #$o->match_set(1,"",[],{});
    return $o;
  }
  sub match_set {
    my($o,$b,$s,$a,$h,$from,$to)=@_;
    $$o->{match_boolean} = $b;
    $$o->{match_string}  = $s;
    $$o->{match_array}   = $a;
    $$o->{match_hash}    = $h;
    $$o->{match_from}    = $from;
    $$o->{match_to}      = $to;
    $$o->{match_value}   = undef;
    return $o;
  }
  sub match_set_as_failed {
    my($o)=@_;
    $o->match_set(0,"",[],{});
    return $o;
  }
  sub match_set_value {
    my($o,$v)=@_;
    $$o->{match_value} = $v;
  }
  
  sub match_describe {
    my($o,$verbose_p)=@_;
    my $vp = $verbose_p;
    my $os = $o->match_string;
    $os = $o->match__indent_except_top($os) if $os =~ /\n/;
    my $s = $verbose_p ? $o->match__describe_name_as : "";
    $s .= "<".($o->match_boolean?"1":"0").",\"$os\",[";
    for (@{$o->match_array}) { $s .= "\n".$o->match__indent($_->match_describe($vp))."," }
    $s .= "\n " if @{$o->match_array};
    $s .= "],{";
    for my $k (keys(%{$o->match_hash})) {
      my $v = $o->match_hash->{$k};
      my $vs = "";
      if(ref($v) eq 'ARRAY') {
        $vs = "[\n".$o->match__indent(join(",\n",map{
          $_->match_describe($vp)
          }@$v))."\n]";
      } else {
        $vs = $v->match_describe($vp);
      }
      $s .= "\n  $k => " .$o->match__indent_except_top($vs)."," }
    $s .= "\n " if %{$o->match_hash};
    $s .= "},";
    my($from,$to)=($o->from,$o->to);
    $from = "" if !defined $from;
    $to   = "" if !defined $to;
    $s .= "$from,$to";
    my $val = $o->match_value;
    $s .= defined $val ? ",$val" : "";
    $s .= ">";
    return $s;
  }
  sub match__indent {my($o,$s)=@_; $s =~ s/^(?!\Z)/  /mg; $s}
  sub match__indent_except_top {my($o,$s)=@_; $s =~ s/^(?<!\A)(?!\Z)/  /mg; $s}
  sub match__describe_name_as {
    my($o)=@_;
    my $s = overload::StrVal($o);
    $s .= "{".$$o->{RULE}."}" if defined $$o->{RULE};
    $s;
  }

  sub match_copy {
    my($o)=@_;
    my $m = ref($o)->new()->match_set($o->match_boolean,
                                      $o->match_string,
                                      $o->match_array,
                                      $o->match_hash,
                                      $o->from,
                                      $o->to);
    $$m->{match_value} = $$o->{match_value};
    $$m->{RULE} = $$o->{RULE};
    $m;
  }

  sub match_x_process_children {
    my($o,$fun)=@_;
    my $a = [map{$fun->($_)} @{$o->match_array}];
    my $oh = $o->match_hash;
    my %h = map{
      my $k = $_;
      my $v = $oh->{$k};
      my $v1 = $v;
      if(ref($v) eq 'ARRAY') {
        $v1 = [map{$fun->($_)}@$v];
      } else {
        $v1 = $fun->($v);
      }
      ($k,$v1);
    } keys %{$oh};
    ($a,\%h);
  }

}

#======================================================================
# AST
# 
{
  package Regexp::ModuleA::AST::Make0;
  BEGIN{
  require Exporter;
  @Regexp::ModuleA::AST::Make0::ISA=qw(Exporter);
  @Regexp::ModuleA::AST::Make0::EXPORT_OK = qw(pat5 mod_expr mod_inline exact quant quant_ng alt conj seq cap grp sr aregex aregexm bind namespace  backref  ques star plus  ques_ng star_ng plus_ng  inf  code coderx independent conditional lookaround commit_sequence commit_group commit_regex commit_match);
  @Regexp::ModuleA::AST::Make0::EXPORT    = @Regexp::ModuleA::AST::Make0::EXPORT_OK;
  }
  sub pat5 { Regexp::ModuleA::AST::Pat5->new(@_) }
  sub mod_expr { Regexp::ModuleA::AST::Mod_expr->new(@_) }
  sub mod_inline { Regexp::ModuleA::AST::Mod_inline->new(@_) }
  sub exact { Regexp::ModuleA::AST::Exact->new(@_) }
  sub quant { Regexp::ModuleA::AST::Quant->new(@_) }
  sub quant_ng { Regexp::ModuleA::AST::Quant->new(@_,'ng') }
  sub alt { Regexp::ModuleA::AST::Alt->new(@_) }
  sub conj { Regexp::ModuleA::AST::Conj->new(@_) }
  sub seq { Regexp::ModuleA::AST::Seq->new(@_) }
  sub cap { Regexp::ModuleA::AST::Cap->new(@_) }
  sub grp { Regexp::ModuleA::AST::Grp->new(@_) }
  sub sr { my($pkg)=caller; Regexp::ModuleA::AST::Subrule->new($pkg,shift,[@_]) }
  sub aregex { Regexp::ModuleA::AST::ARegex->new('',@_) }
  sub aregexm { Regexp::ModuleA::AST::ARegex->new(@_) }
  sub bind { my($pkg)=caller; Regexp::ModuleA::AST::Bind->new($pkg,@_) }
  sub namespace { my($pkg)=caller; Regexp::ModuleA::AST::Namespace->new($pkg,@_) }

  sub backref { Regexp::ModuleA::AST::Backref->new(@_) }
  sub code { Regexp::ModuleA::AST::Code->new(@_) }
  sub coderx { Regexp::ModuleA::AST::CodeRx->new(@_) }
  sub independent { Regexp::ModuleA::AST::Independent->new(@_) }
  sub conditional { Regexp::ModuleA::AST::Conditional->new(@_) }
  sub lookaround { Regexp::ModuleA::AST::Lookaround->new(@_) }
  sub commit_sequence { Regexp::ModuleA::AST::CommitSequence->new(@_) }
  sub commit_group { Regexp::ModuleA::AST::CommitGroup->new(@_) }
  sub commit_regex { Regexp::ModuleA::AST::CommitRegex->new(@_) }
  sub commit_match { Regexp::ModuleA::AST::CommitMatch->new(@_) }

  sub ques { quant(0,1,    (@_ > 1 ? seq(@_) : @_)); }
  sub star { quant(0,undef,(@_ > 1 ? seq(@_) : @_)); }
  sub plus { quant(1,undef,(@_ > 1 ? seq(@_) : @_)); }

  sub ques_ng { quant_ng(0,1,    (@_ > 1 ? seq(@_) : @_)); }
  sub star_ng { quant_ng(0,undef,(@_ > 1 ? seq(@_) : @_)); }
  sub plus_ng { quant_ng(1,undef,(@_ > 1 ? seq(@_) : @_)); }

  sub inf () { 1000**1000**1000 } #XXX There has to be a better way, no?
}
{
  package Regexp::ModuleA::AST::Make1;
  sub pat5 {shift; Regexp::ModuleA::AST::Pat5->new(@_) }
  sub mod_expr {shift; Regexp::ModuleA::AST::Mod_expr->new(@_) }
  sub mod_inline {shift; Regexp::ModuleA::AST::Mod_inline->new(@_) }
  sub exact {shift; Regexp::ModuleA::AST::Exact->new(@_) }
  sub quant {shift; Regexp::ModuleA::AST::Quant->new(@_) }
  sub quant_ng {shift; Regexp::ModuleA::AST::Quant->new(@_,'ng') }
  sub alt {shift; Regexp::ModuleA::AST::Alt->new(@_) }
  sub conj {shift; Regexp::ModuleA::AST::Conj->new(@_) }
  sub seq {shift; Regexp::ModuleA::AST::Seq->new(@_) }
  sub cap {shift; Regexp::ModuleA::AST::Cap->new(@_) }
  sub grp {shift; Regexp::ModuleA::AST::Grp->new(@_) }
  sub sr {my $pkg = shift; Regexp::ModuleA::AST::Subrule->new($pkg,shift,[@_]) }
  sub aregex {shift; Regexp::ModuleA::AST::ARegex->new('',@_) }
  sub aregexm {shift; Regexp::ModuleA::AST::ARegex->new(@_) }
  sub bind {my $pkg = shift; Regexp::ModuleA::AST::Bind->new($pkg,@_) }
  sub namespace {my $pkg = shift; Regexp::ModuleA::AST::Namespace->new($pkg,@_) }

  sub backref {shift; Regexp::ModuleA::AST::Backref->new(@_) }
  sub code {shift; Regexp::ModuleA::AST::Code->new(@_) }
  sub coderx {shift; Regexp::ModuleA::AST::CodeRx->new(@_) }
  sub independent {shift; Regexp::ModuleA::AST::Independent->new(@_) }
  sub conditional {shift; Regexp::ModuleA::AST::Conditional->new(@_) }
  sub lookaround {shift; Regexp::ModuleA::AST::Lookaround->new(@_) }
  sub commit_sequence {shift; Regexp::ModuleA::AST::CommitSequence->new(@_) }
  sub commit_group {shift; Regexp::ModuleA::AST::CommitGroup->new(@_) }
  sub commit_regex {shift; Regexp::ModuleA::AST::CommitRegex->new(@_) }
  sub commit_match {shift; Regexp::ModuleA::AST::CommitMatch->new(@_) }

  sub ques {shift->quant(0,1,    (@_ > 1 ? seq(@_) : @_)); }
  sub star {shift->quant(0,undef,(@_ > 1 ? seq(@_) : @_)); }
  sub plus {shift->quant(1,undef,(@_ > 1 ? seq(@_) : @_)); }

  sub ques_ng {shift->quant_ng(0,1,    (@_ > 1 ? seq(@_) : @_)); }
  sub star_ng {shift->quant_ng(0,undef,(@_ > 1 ? seq(@_) : @_)); }
  sub plus_ng {shift->quant_ng(1,undef,(@_ > 1 ? seq(@_) : @_)); }

  sub inf {shift; 1000**1000**1000 }
}


{
  local $Regexp::ModuleA::AST::Env::pkg;
  local $Regexp::ModuleA::AST::Env::name;

  # AST::BaseClass
  package Regexp::ModuleA::AST::BaseClass;
  sub RAST_children {
    my($o)=@_;
    (exists($o->{expr})
     ? [$o->{expr}]
     : exists($o->{exprs})
     ? $o->{exprs}
     : []);
  }
  sub RAST_tell_children {
    my($o,$meth,@args)=@_;
    [map { $_->$meth(@args) } @{$o->RAST_children}];
  }
  sub RAST_pass1 {
    my($o)=@_;
    $o->{flags} = $Regexp::ModuleA::AST::Env::flags;
    shift->RAST_tell_children('RAST_pass1');
  }
  sub RAST_pass2 { shift->RAST_tell_children('RAST_pass2') }

  sub RAST_to_Make0 {
    my($o)=@_;
    my($cls) = ref($o) =~ /([^:]+)$/;
    my $name = lc $cls;
    $name.'('.$o->RAST_to_Make0_children.')';
  }
  sub RAST_to_Make0_children {
    my($o)=@_;
    my $args = $o->RAST_tell_children('RAST_to_Make0');
    join(",\n",@$args);
  }
  sub RAST_quote {
    my($o,$s)=@_;
    $s =~ s/([\\\'])/\\$1/g;
    "'$s'";
  }

  # AST::Pat5
  package Regexp::ModuleA::AST::Pat5;
  @Regexp::ModuleA::AST::Pat5::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$pat)=@_; die "api assert" if @_ != 2;
    bless {pat=>$pat}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'pat5('.($o->RAST_quote($o->{pat})).')';
  }

  # AST::Exact
  package Regexp::ModuleA::AST::Exact;
  @Regexp::ModuleA::AST::Exact::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$text)=@_; die "api assert" if @_ != 2;
    bless {text=>$text}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'exact('.($o->RAST_quote($o->{text})).')';
  }

  # AST::MixinMod
  package Regexp::ModuleA::AST::MixinMod;
  sub mods_from_modpat {
    my($cls,$modpat)=@_;
    my %m;
    for my $mod (split(":",$modpat)) {
      next if $mod eq '';
      $mod =~ /\A(\w+)(?:[[(<](.*?)[])>])?\z/ or die "assert";
      my($k,$v) = ($1,$2);
      $v = '1' if !defined $v;
      $v = eval($v);#X
        $m{$k} = $v;
    }
    \%m;
  }
  sub _add_mods {
    my($o)=@_;
    my $flags = {%$Regexp::ModuleA::AST::Env::flags};
    foreach my $key (keys(%{$o->{mods}})) {
      $flags->{$key} = $o->{mods}{$key};
    }
    $flags;
  }
  sub _RAST_to_Make0_hlp {
    my($o)=@_;
    my $modpat = join("",map{
      my $k = $_;
      my $v = $o->{mods}{$k};
      my $vs = $v eq '1' ? "" : "<$v>";
      ":$k$vs"
      } keys(%{$o->{mods}}));
    $o->RAST_quote($modpat);
  }
  sub RAST_pass1 {
    my($o,@args)=@_;
    local $Regexp::ModuleA::AST::Env::flags = $o->_add_mods;
    $o->{flags} = $Regexp::ModuleA::AST::Env::flags;
    $o->RAST_tell_children('RAST_pass1',@args);
  }

  # AST::Mod_expr
  package Regexp::ModuleA::AST::Mod_expr;
  @Regexp::ModuleA::AST::Mod_expr::ISA=qw(Regexp::ModuleA::AST::MixinMod Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$modpat,$expr)=@_; die "api assert" if @_ != 3;
    my $mods = $cls->mods_from_modpat($modpat);
    bless {mods=>$mods,expr=>$expr}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'mod_expr('.$o->_RAST_to_Make0_hlp.",".$o->RAST_to_Make0_children.')';
  }
  
  # AST::Mod_inline
  package Regexp::ModuleA::AST::Mod_inline;
  @Regexp::ModuleA::AST::Mod_inline::ISA=qw(Regexp::ModuleA::AST::MixinMod Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$modpat)=@_; die "api assert" if @_ != 2;
    my $mods = $cls->mods_from_modpat($modpat);
    bless {mods=>$mods}, $cls;
  }
  sub RAST_pass1 {
    my($o)=@_;
    $Regexp::ModuleA::AST::Env::flags = $o->_add_mods;
    $o->{flags} = $Regexp::ModuleA::AST::Env::flags;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'mod_inline('.$o->_RAST_to_Make0_hlp.')';
  }

  # AST::Backref
  package Regexp::ModuleA::AST::Backref;
  @Regexp::ModuleA::AST::Backref::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$idx)=@_; die "api assert" if @_ != 2;
    bless {backref_n=>$idx}, $cls;
  }
  sub RAST_pass2 {
    my($o)=@_;
    my $n = $o->{backref_n};
    my $total = $Regexp::ModuleA::AST::Env::nparen;
    die "Backreference to nonexistent group $n of $total"
      if $total < $n;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'backref('.$o->{backref_n}.')';
  }

  # AST::Cap
  package Regexp::ModuleA::AST::Cap;
  @Regexp::ModuleA::AST::Cap::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$expr)=@_;
    bless {expr=>$expr}, $cls;
  }
  sub RAST_pass1 {
    my($o)=@_;
    $o->{cap5_idx} = $Regexp::ModuleA::AST::Env::nparen++;
    $o->{cap6_idx} = $Regexp::ModuleA::AST::Env::nparen6++;
    $o->{flags} = $Regexp::ModuleA::AST::Env::flags;
    local $Regexp::ModuleA::AST::Env::flags = {%$Regexp::ModuleA::AST::Env::flags};
    local $Regexp::ModuleA::AST::Env::nparen6 = 0;
    $o->{expr}->RAST_pass1;
    $o->{nparen6} = $Regexp::ModuleA::AST::Env::nparen6;
  }

  # AST::Grp
  package Regexp::ModuleA::AST::Grp;
  @Regexp::ModuleA::AST::Grp::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$expr)=@_;
    bless {expr=>$expr}, $cls;
  }
  sub RAST_pass1 {
    my($o)=@_;
    $o->{flags} = $Regexp::ModuleA::AST::Env::flags;
    local $Regexp::ModuleA::AST::Env::flags = {%$Regexp::ModuleA::AST::Env::flags};
    $o->{expr}->RAST_pass1;
  }

  # AST::Quant
  package Regexp::ModuleA::AST::Quant;
  @Regexp::ModuleA::AST::Quant::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$min,$max,$expr,$nongreedy)=@_; die "api assert" if @_ < 4||@_ > 5;
    bless {min=>$min,max=>$max,expr=>$expr,nongreedy=>$nongreedy}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    my $min = $o->{min}; $min = 'undef' if !defined $min;
    my $max = $o->{max}; $max = 'undef' if !defined $max;
    my $expr = $o->RAST_to_Make0_children;
    my $ng = $o->{nongreedy}; $ng = defined $ng ? ",'ng'" : "";
    'quant('."$min,$max,$expr$ng".')';
  }

  # AST::Alt
  package Regexp::ModuleA::AST::Alt;
  @Regexp::ModuleA::AST::Alt::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,@exprs)=@_;
    bless {exprs=>\@exprs}, $cls;
  }

  # AST::Conj
  package Regexp::ModuleA::AST::Conj;
  @Regexp::ModuleA::AST::Conj::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,@exprs)=@_;
    bless {exprs=>\@exprs}, $cls;
  }

  # AST::Seq
  package Regexp::ModuleA::AST::Seq;
  @Regexp::ModuleA::AST::Seq::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,@exprs)=@_;
    bless {exprs=>\@exprs}, $cls;
  }

  # AST::Subrule
  package Regexp::ModuleA::AST::Subrule;
  @Regexp::ModuleA::AST::Subrule::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$inpkg,$name,$exprs)=@_; die "api assert" if @_ != 4;
    bless {created_in_pkg=>$inpkg,name=>$name,exprs=>($exprs||[])}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    my $exprs = $o->{exprs};
    my $x = defined $exprs ? ",".$o->RAST_quote($exprs) : "";
    'sr('.$o->RAST_quote($o->{name}).$x.')';
  }
  sub RAST_pass1 {
    my($o)=@_;
    $o->{pkg} = $Regexp::ModuleA::AST::Env::pkg || $o->{inpkg};
    $o->{flags} = $Regexp::ModuleA::AST::Env::flags;
    $o->RAST_tell_children('RAST_pass1');
    $o;
  }

  # AST::ARegex
  package Regexp::ModuleA::AST::ARegex;
  @Regexp::ModuleA::AST::ARegex::ISA=qw(Regexp::ModuleA::AST::MixinMod Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$modpat,$expr)=@_; die "api assert" if @_ != 3;
    my $mods = $cls->mods_from_modpat($modpat);
    bless {mods=>$mods,expr=>$expr}, $cls;
  }
  sub RAST_init {
    my($o)=@_;
    $o->{pkg} = $Regexp::ModuleA::AST::Env::pkg || $o->{inpkg};
    local $Regexp::ModuleA::AST::Env::pkg = $o->{pkg};
    $o->{name} = $Regexp::ModuleA::AST::Env::name;
    local $Regexp::ModuleA::AST::Env::nparen = 0;
    local $Regexp::ModuleA::AST::Env::nparen6 = 0;
    local $Regexp::ModuleA::AST::Env::flags = {};
    $o->RAST_pass1;
    $o->{nparen} = $Regexp::ModuleA::AST::Env::nparen;
    $o->{nparen6} = $Regexp::ModuleA::AST::Env::nparen6;
    $o->RAST_pass2;
    $o;
  }

  # AST::Bind
  package Regexp::ModuleA::AST::Bind;
  @Regexp::ModuleA::AST::Bind::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$inpkg,$name,$expr)=@_; die "api assert" if @_ != 4;
    die "api assert $name"  if $name =~ /::/;
    bless {created_in_pkg=>$inpkg,name=>$name,expr=>$expr}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'bind('.$o->RAST_quote($o->{name}).','.$o->RAST_to_Make0_children.')';
  }
  sub RAST_init {
    my($o)=@_;
    $o->{pkg} = $Regexp::ModuleA::AST::Env::pkg || $o->{inpkg};
    local $Regexp::ModuleA::AST::Env::pkg = $o->{pkg};
    local $Regexp::ModuleA::AST::Env::name = $o->{name};
    $o->{expr}->RAST_init;
    $o;
  }

  # AST::Namespace
  package Regexp::ModuleA::AST::Namespace;
  @Regexp::ModuleA::AST::Namespace::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$inpkg,$nsname,@bindings)=@_; die "api assert" if @_ < 3;
    my $pkg = ($nsname =~ /\A::(.*)/) ? $1 : $nsname eq '' ? $inpkg : "${inpkg}::$nsname";
    bless {created_in_pkg=>$inpkg,nsname=>$nsname,bindings=>\@bindings,pkg=>$pkg}, $cls;
  }
  sub RAST_children { [@{shift->{bindings}}] }
  sub RAST_to_Make0 {
    my($o)=@_;
    'namespace('.$o->RAST_quote($o->{nsname}).",\n".$o->RAST_to_Make0_children.')';
  }
  sub RAST_init {
    my($o)=@_;
    local $Regexp::ModuleA::AST::Env::pkg = $o->{pkg};
    $o->RAST_tell_children('RAST_init');
    $o;
  }

  # AST::Code
  package Regexp::ModuleA::AST::Code;
  @Regexp::ModuleA::AST::Code::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$code)=@_; die "api assert" if @_ != 2;
    bless {code=>$code}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'code('.$o->RAST_quote($o->{code}).')';
  }

  # AST::CodeRx
  package Regexp::ModuleA::AST::CodeRx;
  @Regexp::ModuleA::AST::CodeRx::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$code)=@_; die "api assert" if @_ != 2;
    bless {code=>$code}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    'coderx('.$o->RAST_quote($o->{code}).')';
  }

  # AST::Independent
  package Regexp::ModuleA::AST::Independent;
  @Regexp::ModuleA::AST::Independent::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$expr)=@_; die "api assert" if @_ != 2;
    bless {expr=>$expr}, $cls;
  }

  # AST::Conditional
  package Regexp::ModuleA::AST::Conditional;
  @Regexp::ModuleA::AST::Conditional::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls,$test,$expr_then,$expr_else)=@_; die "api assert" if @_ < 3 || @_ > 4;
    bless {test=>$test,expr_then=>$expr_then,expr_else=>$expr_else}, $cls;
  }
  sub RAST_children { 
    my($o)=@_;
    my @ch;
    push(@ch,$o->{test}) if $o->{test} !~ /\A\d+\z/;
    push(@ch,$o->{expr_then});
    push(@ch,$o->{expr_else}) if $o->{expr_else};
    \@ch;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    my $test = $o->{test};
    my $n = ($test =~ /^\d+$/) ? "$test," : "";
    'conditional('."$n".$o->RAST_to_Make0_children.')';
  }

  # AST::Lookaround
  package Regexp::ModuleA::AST::Lookaround;
  @Regexp::ModuleA::AST::Lookaround::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new { #XXX blech api
    my($cls,$is_forward,$is_positive,$expr)=@_; die "api assert" if @_ != 4;
    bless {is_forward=>$is_forward,is_positive=>$is_positive,expr=>$expr}, $cls;
  }
  sub RAST_to_Make0 {
    my($o)=@_;
    my $a = $o->{is_forward} ? '1' : '0';
    my $b = $o->{is_positive} ? '1' : '0';
    'lookaround('."$a,$b,".$o->RAST_to_Make0_children.')';
  }

  # AST::CommitSequence
  package Regexp::ModuleA::AST::CommitSequence;
  @Regexp::ModuleA::AST::CommitSequence::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls)=@_; die "api assert" if @_ != 1;
    bless {}, $cls;
  }
  # AST::CommitGroup
  package Regexp::ModuleA::AST::CommitGroup;
  @Regexp::ModuleA::AST::CommitGroup::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls)=@_; die "api assert" if @_ != 1;
    bless {}, $cls;
  }
  # AST::CommitRegex
  package Regexp::ModuleA::AST::CommitRegex;
  @Regexp::ModuleA::AST::CommitRegex::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls)=@_; die "api assert" if @_ != 1;
    bless {}, $cls;
  }
  # AST::CommitMatch
  package Regexp::ModuleA::AST::CommitMatch;
  @Regexp::ModuleA::AST::CommitMatch::ISA=qw(Regexp::ModuleA::AST::BaseClass);
  sub new {
    my($cls)=@_; die "api assert" if @_ != 1;
    bless {}, $cls;
  }

}

#======================================================================
package Regexp::ModuleA::Api::GatherMethodsA;
BEGIN{
  require Exporter;
  @Regexp::ModuleA::Api::GatherMethodsA::ISA=qw(Exporter);
  @Regexp::ModuleA::Api::GatherMethodsA::EXPORT_OK = qw(gather_methods);
  @Regexp::ModuleA::Api::GatherMethodsA::EXPORT = @Regexp::ModuleA::Api::GatherMethodsA::EXPORT_OK;
}
sub gather_methods {
  my($cls,%args)=@_;
  for(keys %args){Carp::confess("invalid argument $_") if !/^(filter|pkg)$/;}
  $args{pkg} ||= $cls;
  $args{filter} ||= qr/^(.+)$/;
  my $filter = $args{filter};
  my $bottom_up;
  $bottom_up = sub {
    my(@pkgs)=@_;
    no strict 'refs';
    map{
      my $a = $_."::ISA";
      my $b = $_."::";
      my @isa = eval{@$a};
      ((!$@ ? &$bottom_up(@isa) : ()),keys(%$b));
    } reverse @pkgs;
  };
  my @meth_list = &$bottom_up($args{pkg});
  my %meth_map = map{$_ =~ $filter ? ($1,$_) : ()} @meth_list;
  \%meth_map;
}
1;
#======================================================================
# P5 Regexps
#
package Regexp::ModuleA::P5;
BEGIN { Regexp::ModuleA::AST::Make0->import; };
use Regexp::Common;
sub mod_helper {
  my($mod)=@_;
  my $h = {%$Regexp::ModuleA::ReentrantEngine::Env::nested_data};
  my($on,$off) = split('-',$mod);
  if($on){for my $x (unpack('c*',$on)){$h->{$x}=1}}
  if($off){for my $x (unpack('c*',$off)){$h->{$x}=0}}
  $Regexp::ModuleA::ReentrantEngine::Env::nested_data = $h;
}
sub mod_x_or_fail {
  $Regexp::ModuleA::ReentrantEngine::Env::nested_data->{x} ? qr// : qr/(?!)/;  
}
{
  my $nonmeta = '[^[)({^$?*+\\\\\.|]';
  my $perlcode = ('(?:(?>[^][(){}"\'\/]+)'
                  .'|'.$RE{balanced}{-parens=>'()[]{}'}
                  .'|'.$RE{delimited}{-delim=>'\'"'}
                  .'|'.$RE{delimited}{-delim=>'/'}
                  .')*');
# a defining characteristic: ws is fudged, so comments are unsupported.
  namespace(""
            ,bind('regex',aregexm(':p5',sr('pattern')))
            ,bind('pattern',aregex(sr('regex_ordered_disjunction')))
            ,bind('regex_ordered_disjunction',aregex(seq(sr('regex_sequence'),star(exact('|'),sr('regex_sequence')))))
            ,bind('regex_sequence',aregex(star(sr('regex_quantified_atom'))))
            ,bind('regex_quantified_atom',aregex(seq(sr('regex_atom'),ques(pat5('[?*+]\??|{\d+(?:,\d*)?}\??')))))
            ,bind('regex_atom',aregex(alt(sr('_mod_inline'),sr('_mod_expr'),sr('_code'),sr('_coderx'),sr('_independent'),sr('_conditional'),sr('_lookaround'),sr('_cap'),sr('_grp'),sr('_charclass'),sr('_backref_or_char'),sr('_esc'),sr('_nonmeta'),sr('_passthru'),sr('_subrule'))))
            ,bind('_mod_inline',aregex(pat5('\(\?([imsx-]+)\)(?{Regexp::ModuleA::P5::mod_helper($^N)})')))
            ,bind('_mod_expr',aregex(seq(pat5('\(\?([imsx-]+):(?{Regexp::ModuleA::P5::mod_helper($^N)})'),sr('pattern'),exact(')'))))
            ,bind('_grp',aregex(seq(exact('(?:'),sr('pattern'),exact(')'))))
            ,bind('_cap',aregex(seq(pat5('\((?!\?)'),sr('pattern'),exact(')'))))
#            ,bind('_charclass',aregex(pat5('\[\^?\]?([^\]\\\\]|\\\\.)*\]\]?')))#X
            ,bind('_charclass',aregex(seq(pat5('\[\^?[\]\-]?'),sr('_charset_def'),pat5('\-?\]'))))
            ,bind('_charset_def',aregex(pat5('(?>\[:\^?\w+:\]|[^\]\\\\]+|\\\\(?s:.))*')))
            ,bind('_backref_or_char',aregex(pat5('\\\\\d+')))
            ,bind('_esc',aregex(pat5('\\\\[^\d]')))
            ,bind('_nonmeta',aregex(pat5("$nonmeta(?:$nonmeta+(?![?*+{]))?")))
            ,bind('_passthru',aregex(pat5('[$^.]')))
            ,bind('_code',aregex(seq(exact('(?{'),pat5($perlcode),exact('})'))))
            ,bind('_coderx',aregex(seq(exact('(??{'),pat5($perlcode),exact('})'))))
            ,bind('_independent',aregex(seq(exact('(?>'),sr('pattern'),exact(')'))))
            ,bind('_conditional',aregex(seq(pat5('\(\?(?=\()'),alt(pat5('\(\d+\)'),sr('_lookaround')),sr('regex_sequence'),ques(exact('|'),sr('regex_sequence')),exact(')'))))
            ,bind('_lookaround',aregex(seq(pat5('\(\?<?[=!]'),sr('pattern'),exact(')'))))
            ,bind('_subrule',aregex(pat5('(?!)')))
            )->RAST_init->RMARE_emit;
}
BEGIN{ Regexp::ModuleA::Api::GatherMethodsA->import('gather_methods') };
sub make0_from_match {
  my($cls,$m)=@_;
  my $map = $cls->gather_methods(filter=>qr/^make0_from_node__(.+)$/);
  my $map_code = {map{($_,UNIVERSAL::can($cls,$map->{$_}))} keys %$map};
  local $Regexp::ModuleA::Scratch::make0_from_match::map_code = $map_code;
  $cls->make0_from_node($m);
}
sub make0_from_node {
  my($cls,$m)=@_;
  my $r = $$m->{RULE};
  my $map_code = $Regexp::ModuleA::Scratch::make0_from_match::map_code;
  my $meth = $map_code->{$r} || $map_code->{DEFAULT};
  if($meth) {
    $meth->($cls,$m);
  } else {
    die "api assert";
  }
}
sub make0_from_children {
  my($cls,$m)=@_;
  $m->match_x_process_children(sub{$cls->make0_from_node($_)});
}
sub make0_from_node__DEFAULT {
  my($cls,$m)=@_;
  my($a,$h) = $cls->make0_from_children($m);
#  my $m1 = $m->match_copy();
#  $$m1->{match_array} = $a;
#  $$m1->{match_hash} = $h;
#  $m1;
  my @v = values(%{$h});
  $v[0][0];
}

sub make0_from_node___nonmeta {
  my($cls,$m)=@_;
  my $pat = "$m";
  $pat =~ s/\\([\\\'])/\\\\\\$1/g;
  return "exact('$pat')";
}
sub make0_from_node___passthru {
  my($cls,$m)=@_;
  my $pat = "$m";
  $pat =~ s/\\([\\\'])/\\\\\\$1/g;
  return "pat5('$pat')";
}
sub make0_from_node__regex_quantified_atom {
  my($cls,$m)=@_;
  my $s = "$m";
  my $e = $cls->make0_from_node($m->{regex_atom}[0]);
  if($s =~ /{(\d+)(?:,(\d*))?}(\?)?\z/) {
    my $ng = defined $3 ? '_ng' : '';
    my $min = $1;
    my $max = !defined $2 ? $min : $2 ne "" ? $2 : 1000**1000**1000; # inf
    $e = "quant${ng}($min,$max,$e)";
  }
  elsif($s =~ /([?*+])(\?)?\z/) {
    my $ng = defined $2 ? '_ng' : '';
    $e = "ques${ng}($e)" if $1 eq '?';
    $e = "star${ng}($e)" if $1 eq '*';
    $e = "plus${ng}($e)" if $1 eq '+';
  }
  return $e;
}
sub make0_from_node___backref_or_char {
  my($cls,$m)=@_;
  "$m" =~ /\A\\(\d+)\z/ or die "bug";
  my $n = $1;
  if($n !~ /\A0/ && $n < 10) {
    return "backref($n)";
  } else {
    # XXX kludge. Interpretation of \10 is much more complex.
    return "pat5('\\\\$n')";
  }
}
sub make0_from_node___esc {
  my($cls,$m)=@_;
  my $pat = "$m";
  $pat =~ s/\\([\\\'])/\\\\\\$1/g;
  return "pat5('$pat')";
}
sub make0_from_node___charclass {
  my($cls,$m)=@_;
  my $pat = "$m";
  $pat =~ s/\\([\\\'])/\\\\\\$1/g;
  return "pat5('$pat')";
}
sub make0_from_node___grp {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  return "grp($e)";
}
sub make0_from_node___cap {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  return "cap($e)";
}
sub make0_from_node___mod_expr {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  "$m" =~ /\A\(\?([imsx]*)(?:-([imsx]*))?/ or die 'bug';
  my $on  = join("",map{":${_}"} split("",$1));
  my $off = join("",map{":${_}<0>"} split("",defined $2 ? $2 : ""));
  return "mod_expr('$on$off',$e)";
}
sub make0_from_node___mod_inline {
  my($cls,$m)=@_;
  "$m" =~ /\A\(\?([imsx]*)(?:-([imsx]*))?/ or die 'bug';
  my $on  = join("",map{":${_}"} split("",$1));
  my $off = join("",map{":${_}<0>"} split("",defined $2 ? $2 : ""));
  return "mod_inline('$on$off')";
}
sub make0_from_node__regex_sequence {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{regex_quantified_atom}};
  return (@v != 1 ? ("seq(".join(",",@v).")") : $v[0]);
}
sub make0_from_node__regex_ordered_disjunction {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{regex_sequence}};
  return (@v > 1 ? ("alt(".join(",",@v).")") : $v[0]);
}
sub make0_from_node___coderx {
  my($cls,$m)=@_;
  "$m" =~ /\A\((\?\??){(.*?)}\)\z/ or die "bug";
  my($which,$code) = ($1,$2);
  return "coderx(q{$code})";
}
sub make0_from_node___code {
  my($cls,$m)=@_;
  "$m" =~ /\A\((\?\??){(.*?)}\)\z/ or die "bug";
  my($which,$code) = ($1,$2);
  return "code(q{$code})";
}
sub make0_from_node___independent {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  return "independent($e)";
}
sub make0_from_node___conditional {
  my($cls,$m)=@_;
  my($a,$h) = $cls->make0_from_children($m);
  "$m" =~ /\A\(\?\((.*?)\)/ or die "bug";
  my $test_ish = $1;
  my $test;
  if($test_ish =~ /\A\d+\z/) {
    $test = $test_ish;
  } else {
    $test = $h->{_lookaround}[0];
  }
  my $expr_then = $h->{regex_sequence}[0];
  my $expr_else = $h->{regex_sequence}[1];
  my $then_else = $expr_then.(defined $expr_else ? ",$expr_else" : "");
  return "conditional($test,$then_else)";
}
sub make0_from_node___lookaround {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  "$m" =~ /\A\(\?(<?[=!])/ or die "bug";
  my $flavor = $1;
  my $args = {'='=>[1,1],
              '!'=>[1,0],
              '<='=>[0,1],
              '<!'=>[0,0]}->{$flavor};
  my $s = join(",",@$args);
  return "lookaround($s,$e)";
}
sub make0_from_node__regex {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  return "aregexm(':p5',$e)";
}


sub new_rx_from_re {
  my($cls,$pat,$mods)=@_;
  my $re = $pat;
  $re = "(?$mods)$re" if $mods;
  my $verbose = 0;
  my($m,$mexpr,$ast);
  my $o = eval {
    $m = $cls->regex()->match($re);
    print STDERR $m->match_describe,"\n" if $verbose;
    if(!$m || $m->from != 0 || $m->to != length($re)) {
      my $err = "Regexp syntax error:";
      Carp::confess "$err / <== HERE $re/" if $m->from != 0; #XX should set beginat
      my $at = $m->to+1;
      Carp::confess "$err /".substr($re,0,$at)." <== HERE ".substr($re,$at)."/";
    }
    $mexpr = $cls->make0_from_match($m);
    die "assert" if !defined $mexpr;
    print STDERR $mexpr,"\n" if $verbose;
    $ast = eval("namespace('::$cls',$mexpr)");
    die if $@;
    $ast->RAST_init;
    my($rx) = $ast->RMARE_emit;
    $rx;
  };
  Carp::confess "compile \"$re\" failed: $@" if !defined $o;
  $o->_init($pat,$mods,$re,$mexpr,$ast);
}
sub bind_rx {
  my($cls,$pkg,$name,$rx)=@_;die "api assert" if @_ != 4;
  eval("package $pkg; *$name = \$rx"); die $@ if $@;
  $rx;
}

#======================================================================
# P5 Regexps with subrules
#
package Regexp::ModuleA::P5WithSubrules;
@Regexp::ModuleA::P5WithSubrules::ISA=qw(Regexp::ModuleA::P5);
BEGIN { Regexp::ModuleA::AST::Make0->import; };

{
  my $nonmeta = '[^[)({^$?*+\\\\\.|<]';
  namespace(""
            ,bind('_subrule',aregex(seq(pat5('\<[?!]*\w+'),ques(seq(pat5('\s+'),plus(sr('pattern')))),exact('>'))))
            ,bind('_nonmeta',aregex(pat5("$nonmeta(?:$nonmeta+(?![?*+{]))?")))
            ,bind('test1',aregex(pat5('\w{2}')))
            )->RAST_init->RMARE_emit;
}

sub make0_from_node___subrule {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{pattern}};
  "$m" =~ /\A<([?!]*(\w+))/ or die "bug";
  my $name = $1;
  my $args = (@v ? "," : "").join(",",map{"aregex($_)"}@v);
  return "sr('$name'$args)";
}


#======================================================================
# P6 Regexps
#
{ package Regexp::ModuleA::Api::PreludeA::_Misc;
  BEGIN { Regexp::ModuleA::AST::Make0->import; };
  sub nrx {my($name,$v)=@_; bind($name,aregex($v));}
  namespace(""
            ,(map{nrx($_,pat5("[[:$_:]]"))}
              qw(alpha alnum ascii blank cntrl digit
                 graph lower print punct space upper
                 word xdigit))
            ,nrx('commit',commit_match())
            ,nrx('null',pat5(''))
            ,nrx('before',lookaround(1,1,coderx(q{$Regexp::ModuleA::ReentrantEngine::Env::nested_data->{args}[0]||qr/(?!)/})))
            ,nrx('after',lookaround(0,1,coderx(q{$Regexp::ModuleA::ReentrantEngine::Env::nested_data->{args}[0]||qr/(?!)/})))
            ,nrx('sp',pat5('[ ]'))
            ,nrx('lt',pat5('<'))
            ,nrx('gt',pat5('>'))
            ,nrx('dot',pat5('\.'))
            ,nrx('ident',pat5('(?:_|[[:alpha:]])\w*'))
            ,nrx('wb',pat5('\b'))
            ,nrx('ws',pat5('\s+')) #XXX so very not
            ,nrx('fail',pat5('(?!)'))
            )->RAST_init->RMARE_emit;
}

package Regexp::ModuleA::P6;
@Regexp::ModuleA::P6::ISA=qw(Regexp::ModuleA::P5WithSubrules
                             Regexp::ModuleA::Api::PreludeA::_Misc);
BEGIN { Regexp::ModuleA::AST::Make0->import; };
  
sub nrx {my($name,$v)=@_; bind($name,aregex($v));}
sub unction {
  my($name,$op,$subname)=@_;
  nrx($name,seq(sr($subname),star($op,sr($subname))));
}
sub unction1 {
  my($name,$op,$subname)=@_;
  nrx($name,seq(ques($op),sr($subname),star($op,sr($subname))));
}

{
  my $nonmeta = '[^][)(><}{&|^$?*+\\\\\.:]';
  namespace(""
            ,bind('regex',aregex(seq(mod_inline(':x'),sr('pattern'))))
            ,nrx('pattern',sr('regex_ordered_disjunction'))
            ,unction1('regex_ordered_disjunction',
                      pat5('\|\|'),'regex_ordered_conjunction')
            ,unction('regex_ordered_conjunction',
                     pat5('\&\&'),'regex_unordered_disjunction')
            ,unction1('regex_unordered_disjunction',
                      pat5('\|(?!\|)'),'regex_unordered_conjunction')
            ,unction('regex_unordered_conjunction',
                     pat5('\&(?!\&)'),'regex_sequence')
            ,nrx('regex_sequence',plus(alt(seq(sr('_alias'),commit_group()),
                                           sr('regex_quantified_atom'))))
            ,nrx('regex_quantified_atom',
                 seq(sr('regex_atom'),ques(sr('regex_quantifier'))))
            ,nrx('regex_quantifier',
                 alt(seq(pat5('\*\*'),#<?ws>
                         sr('block'),sr('quantmod')),
                     seq(pat5('[\*\+\?](?!\*)'),sr('quantmod'))))
            ,nrx('quantmod',ques(pat5('\? | \! | \: | \+')))
            ,nrx('block',pat5('\{[\d\.]+\}'))
            ,bind('regex_atom',aregex(alt(sr('_mod_inline'),sr('_mod_expr'),sr('_code'),sr('_coderx'),sr('_independent'),sr('_conditional'),sr('_lookaround'),sr('_cap'),sr('_grp'),sr('_charclass'),sr('_backref_or_char'),sr('_esc'),sr('_nonmeta'),sr('_dot'),sr('_beosl'),sr('_subrule'),
                                          sr('_commit'),sr('_esc_code'),sr('_word_boundary'),sr('_literal'))))
            ,bind('_nonmeta',aregex(pat5("$nonmeta(?:$nonmeta+(?![?*+:!]))?")))
            ,bind('_grp',aregex(seq(exact('['),sr('pattern'),exact(']'))))
            ,nrx('_cap',seq(pat5('\('),sr('pattern'),exact(')')))
            ,nrx('_commit',pat5(':+'))
            ,bind('_esc',aregex(pat5('\\\\[^\doOxX]')))
            ,nrx('_esc_code',pat5('\\\\[oO][0-7]+|\\\\[xX][0-9a-fA-F]+'))
            ,bind('_backref_or_char',aregex(pat5('(?!)')))
            ,nrx('_charclass',seq(pat5('<(?=[-+\[])'),plus(sr('_charset')),pat5('>')))
            ,nrx('_charset',seq(pat5('[-+]?'),alt(pat5('\[(?:[^\]\\\\]|\\\\.)*\]'),sr('ident'))))
            ,nrx('_mod_inline',pat5('(?<![\?\*\+\!]):\w+'))
            ,nrx('_dot',pat5('\\.'))
            ,nrx('_beosl',pat5('[\^\$]{1,2}'))
            ,nrx('_alias',seq(sr('_alias_target'),pat5('\s*:=\s*'),sr('_construct')))
            ,nrx('_alias_target',alt(seq(pat5('[\$\@\%]<'),sr('name'),pat5('>')),
                                     pat5('\$\d+'),
                                     seq(pat5('[\$\@\%]'),sr('name'))))
            ,nrx('_construct',alt(sr('_construct_but_not_alias'),
                                  sr('_alias')))
            ,nrx('_construct_but_not_alias',
                 seq(alt(sr('_subrule'),sr('_cap'),sr('_grp')),
                     ques(sr('regex_quantifier'))))
            ,nrx('_word_boundary',pat5('<<|>>|\x{abd}|\x{bbd}'))
            ,nrx('_literal',pat5('<\'(?:[^\'\\\\]|\\\\.)*\'>'))

            ,nrx('name',alt(seq(sr('ident'),sr('nofat'),star(exact('::'),sr('ident'))),
                            plus(exact('::'),sr('ident'))))
            ,nrx('nofat',pat5('')) # <!before \h* <?unsp>? =\> >
            )->RAST_init->RMARE_emit;
}


sub make0_from_node__regex {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{pattern}[0]);
  return "aregex(seq(mod_inline(':x'),$e))";
}
sub make0_from_node___commit {
  my($cls,$m)=@_;
  my $pat = "$m";
  my $what = {':'=>'sequence',
              '::'=>'group',
              ':::'=>'regex'}->{$pat};
  die "assert" if !$what;
  return "commit_${what}()";
}
sub make0_from_node__regex_quantified_atom {
  my($cls,$m)=@_;
  my $e = $cls->make0_from_node($m->{regex_atom}[0]);
  return $e if !$m->{regex_quantifier};
  my $q = $m->{regex_quantifier}[0]."";
  if($q =~ /^\*\*{(\d+)(?:,(\d*))?}(\?)?\z/) {
    my $ng = defined $3 ? '_ng' : '';
    my $min = $1;
    my $max = !defined $2 ? $min : $2 ne "" ? $2 : 1000**1000**1000; # inf
    $e = "quant${ng}($min,$max,$e)";
  }
  elsif($q =~ /^([?*+])(\?)?\s*\z/) {
    my $ng = defined $2 ? '_ng' : '';
    $e = "ques${ng}($e)" if $1 eq '?';
    $e = "star${ng}($e)" if $1 eq '*';
    $e = "plus${ng}($e)" if $1 eq '+';
  }
  else { die "bug >>$q<<" }
  return $e;
}
sub make0_from_node__regex_ordered_disjunction {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{regex_ordered_conjunction}};
  return (@v > 1 ? ("alt(".join(",",@v).")") : $v[0]);
}
sub make0_from_node__regex_ordered_conjunction {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{regex_unordered_disjunction}};
  return $v[0] if @v == 1;
  return "conj(".join(",",@v).")";
}
sub make0_from_node__regex_unordered_disjunction {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{regex_unordered_conjunction}};
  return (@v > 1 ? ("alt(".join(",",@v).")") : $v[0]);
}
sub make0_from_node__regex_unordered_conjunction {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{regex_sequence}};
  return $v[0] if @v == 1;
  return "conj(".join(",",@v).")";
}
sub make0_from_node___esc {
  my($cls,$m)=@_;
  my $pat = "$m";
  $pat =~ /^\\(.)$/ or die "bug";
  my $ch = $1;
  my $nl = '\x0d\x0a?|(?<!\x0d)\x0a|\x2028\x2029';
  my $pat1 = {
    T => '[^\t]',
    n => $nl,
    N => "(?!$nl)(?s:.)",
    R => '[^\r]',
    F => '[^\f]',
    E => '[^\e]',
    v => '[\x0a\f]',
    V => '[^\x0a\f]',
    h => '[ \t\x0d\b]',
    H => '[^ \t\x0d\b]',
    Q => 'Q', L => 'L', U => 'U',
    z => 'z', Z => 'Z', A => 'A',
    p => 'p', P => 'P', G => 'G',
    b => 'b', B => 'B'
    }->{$ch};
  if(!defined($pat1)){
    $pat1 = $pat;
    $pat1 =~ s/\\([\\\'])/\\\\\\$1/g;
  }
  return "pat5('$pat1')";
}
sub make0_from_node___esc_code {
  my($cls,$m)=@_;
  my $pat = "$m";
  $pat =~ /^\\([oOxX])(.+)$/ or die "bug";
  my $neg = ($1 eq 'O' || $1 eq 'X') ? '^' : '';
  my $code = $2;
  $code =~ s/^0+//;
  my $ox = lc $1;
  if($ox eq 'o') {
  } else {
    $code = 'x'.$code;
  }
  return "pat5('[$neg\\$code]')";
}
sub make0_from_node___charclass {
  my($cls,$m)=@_;
  my @v = map{$cls->make0_from_node($_)} @{$m->{_charset}};
  my(@inc,@not);
  for my $opset (@v) {
    $opset =~ /^([-+])(.+)/s or die "bug";
    push(@{$1 eq '+' ? \@inc : \@not},$2);
  }
  my $maybe_alt = sub {
    my(@a)=@_; @a == 1 ? $a[0] : "alt(".join(",",@a).")";
  };
  my $code = "";
  $code .= "sr('!?before',".&$maybe_alt(map{"aregex($_)"}@not).")," if @not;
  $code .= @inc ? &$maybe_alt(@inc) : "pat5('(?s:.)')";
  $code = "seq(".$code.")" if @not;
  return $code;
}
sub make0_from_node___charset {
  my($cls,$m)=@_;
    my $pat = "$m";
    if($pat =~ /^([-+]?)\[(.+)\]$/s) {
      my $op = $1 eq '-' ? '-' : '+';
      my $set = $2;
      die "parse error - unescaped hyphen" if $set =~ /(^|[^\\])\-/;
      $set =~ s/\.\./-/g;
      $set =~ s/\\([\\\'])/\\\\\\$1/g;
      return $op."pat5('[$set]')";
    }
    elsif($pat =~ /^([-+]?)(\w+)$/) {
      my $op = $1 eq '-' ? '-' : '+';
      return $op."sr('?$2')";
    }
    else { die "bug" }
  }
sub make0_from_node___mod_inline {
  my($cls,$m)=@_;
    my $pat = "$m";
    return "mod_inline('$pat')";
  }
sub make0_from_node___dot {
  my($cls,$m)=@_;
    return "pat5('(?s:.)')";
  }
sub make0_from_node___beosl {
  my($cls,$m)=@_;
    my $pat = "$m";
    my $npat = { '^' => '\A', '$' => '\z',
                 '^^' => '(?m:^)(?!(?=\z)(?<=\n))',
                 '$$' => '(?m:$)(?!(?=\z)(?<=\n))'
                 }->{$pat};
    return "pat5('$npat')";
  }
sub make0_from_node___word_boundary {
  my($cls,$m)=@_;
    my $pat = "$m";
    my $npat = { '<<' => '\b(?=\w)',
                 '>>' => '\b(?<=\w)',
                 "\x{abd}" => '\b(?=\w)',
                 "\x{bbd}" => '\b(?<=\w)'
                 }->{$pat};
    return "pat5('$npat')";
  }
sub make0_from_node___literal {
  my($cls,$m)=@_;
    my $pat = "$m";
    $pat =~ /^<'(.*)'>$/ or die "bug";
    $pat = $1;
    $pat =~ s/\\([\\\'])/\\\\\\$1/g;
    return "pat5('(?-xi:$pat)')";
  }

#======================================================================
# Rx
#
package Regexp::ModuleA::Rx;
use Sub::Name;

sub _new_from_ast {
  my($rxclass,$ast,$pkg,$name,$f,$matchergen)=@_;
  $pkg ||= "";
  my $h = {ast=>$ast,pkg=>$pkg,name=>$name,f=>$f,matchergen=>$matchergen};
  my $self;
  my $showname = $name || '*anon*';
  $self = subname "<an aregex for $ast $pkg $showname>" => sub {
    if(@_ == 0) {
      return $self;
    }
    elsif($_[0] !~ /^ /) {
      my($cls,$method)=@_; Carp::confess "api assert" if @_ > 2;
      $method ||= $name;
      if($cls eq $pkg && $method eq $name) {
        return $self;
      }
      else {
        return $rxclass->_new_from_ast($ast,$cls,$method,$f,$matchergen);
      }
    }
    else {
      my($request)=@_;
      if($request eq ' api0') { return $f }
      if($request eq ' hash') { return $h }
      if($request eq ' match') {
        shift @_;
        return $matchergen->()($pkg,$name,@_);
      }
    }
    Carp::confess("ui assert");
    die "ui assert";
  };
  bless $self, $rxclass;
}
sub _init {
  my($o,$pat,$mods,$re,$mexpr,$ast)=@_;
  my $h = $o->(' hash');
  $h->{pattern} = $pat;
  $h->{modifiers} = $mods;
  $h->{regexp} = $re;
  $h->{mexpr} = $mexpr;
  $h->{ast} = $ast;
  $o;
}

sub match {
  my($o,$str)=@_;
  $o->(' match',$str);
}

sub _mexpr {
  my($o)=@_;
  $o->(' hash')->{mexpr};
}

#======================================================================
# Api
#
#======================================================================
package Regexp::ModuleA::Api::RegexApi0;
sub define_named_regex {
  my($cls,$name,$pat,%args)=@_;
  for(keys %args){Carp::confess("invalid argument $_") if !/^(env|pkg|mods)$/;}
  $args{pkg} ||= caller;
  $args{mods} = undef if !exists $args{mods};
  my $rx = Regexp::ModuleA::P6->new_rx_from_re($pat,$args{mods});
  Regexp::ModuleA::P6->bind_rx($args{pkg},$name,$rx);
  $rx;
}
sub match_named_regex {
  my($cls,$name,$string,%args)=@_;
  for(keys %args){Carp::confess("invalid argument $_") if !/^(pkg)$/;}
  $args{pkg} ||= caller;
  $args{mods} = undef if !exists $args{mods};
  Carp::confess("mods unimplemented") if $args{mods};
  $args{pkg}->${name}($name)->match($string);
}
1;
#======================================================================
package Regexp::ModuleA::Api::PreludeA;
BEGIN{
  require Exporter;
  @Regexp::ModuleA::Api::PreludeA::ISA=qw(Regexp::ModuleA::Api::PreludeA::_Misc Exporter);
  @Regexp::ModuleA::Api::PreludeA::EXPORT_OK =
    qw(regex_api0 regex_ast_maker_api0
       alpha alnum ascii blank cntrl digit
       graph lower print punct space upper
       word xdigit
       commit null before after sp lt gt dot ident wb ws fail);
  @Regexp::ModuleA::Api::PreludeA::EXPORT    = @Regexp::ModuleA::Api::PreludeA::EXPORT_OK;
}

sub regex_api0 {'Regexp::ModuleA::Api::RegexApi0'}
sub regex_ast_maker_api0 {'Regexp::ModuleA::AST::Make1'}
1;
#======================================================================
package Regexp::ModuleA::Api::FilterWithenvA;
use Regexp::Common;
sub _expand_withenv {
  my($s)=@_;
  my %code_fragments;
  while($s =~ /([\$\@\%]\w+)/g) {
    $code_fragments{$1} = '\\'.$1;
  }
  while($s =~ /($RE{balanced}{-parens=>'{}'})/g) {
    # Can't both get value and use a continuation.  PPI?  :(
    my $fragment = $1;
    my $for_value = 'sub'.$fragment;
    my $with_continuation = $fragment;
    $with_continuation =~ s/\}$// or die "bug";
    $with_continuation = 'sub'.$with_continuation.';$_[0]->()}';
    my $pair = "[$for_value,$with_continuation]";
    $code_fragments{$fragment} = $pair;
  }
  my $code = join(",",map{
    my $q = $_;
    my $e = $code_fragments{$_};
    $q =~ s/([\\\'])/\\$1/g;
    $e =~ s/([\\\'])/\\$1/g;
    "'$q'=>sub{eval('$q')}";
  } keys %code_fragments);
  $code = "sub{{$code}}";
  $s.",env=>(bless $code,'Regexp::ModuleA::Api::FilterWithenvA::Bindings')";
}
sub filter_string {
  my($s)=@_;
  $s =~ s/\bWITHENV{(.*?)}WITHENV\b/_expand_withenv($1)/eg;
  $s;
}
use Filter::Simple sub {
  $_ = filter_string($_);
  #print STDERR $_;
  $_;
};
package Regexp::ModuleA::Api::FilterWithenvA::Bindings;
sub lookup {
  my($self,$fragment)=@_;
  my $h = $self->();
  my $evaler = $h->{$fragment};
  die "Cannot lookup code fragment >$fragment<" if !$evaler;
  $evaler->();
}
1;
#======================================================================
package Regexp::ModuleA::Api::FilterRegexDefinitionsA;
sub expand_regex {
  my($name,$mods,$body,$oldcode)=@_;
  $mods =~ s/\s+$//;
  my($nameq,$modsq,$bodyq)=map{s/([\\\'])/\\$1/g;"'$_'"}($name,$mods,$body);
  my $modsarg = $mods eq "''" ? '' : ",mods=>$modsq";
  my $code = "__PACKAGE__->define_named_regex($nameq,WITHENV{$bodyq}WITHENV$modsarg);";
  my $old_line_count = $oldcode =~ tr/\n/\n/;
  my $new_line_count = $code =~ tr/\n/\n/;
  die "assert" if $new_line_count > $old_line_count;
  $code .= "\n" x ($old_line_count - $new_line_count);
  $code;
}
sub filter_string {
  my($s)=@_;
  my $re = qr/(
    ^[ ]* regex (?>\s+(\w*)\s*) ([^\n\{]*) \{
    (?: ([^\n]+) \} \s*(?:\#(?!\()[^\n]*)? $
      | ((?s:.)+? \n ) \2 \} )
  )/x;
  $s =~ s/$re/expand_regex($2,$3,(defined($4)?$4:$5),$1)/meg;
  $s;
}
use Filter::Simple sub {
  $_ = filter_string($_);
  #print STDERR $_;
  $_;
};
1;
#======================================================================
# Interactive
#
{
  package Regexp::ModuleA::Interactive;
  sub convert_p5_re_literal_to_p5_re {
    use re 'eval';
    my($lit5)=@_;
    $lit5 =~ s/\A\s+//; $lit5 =~ s/\s+\z//;
    
    my $modre = qr/[imsxogce]/;
    my %close = ('('=>qr/\)/,'{'=>qr/}/,'['=>qr/]/,'<'=>qr/>/);
    my $cl = sub{my $s = $_[0]; $close{$s}||qr/$s/ };
    my($op,$delim,$pat5,$delimC,$subst,$mod5);
    if($lit5 =~ /\A()(\/)(.+?)(\/)()($modre*)\z/) {
      ($op,$delim,$pat5,$delimC,$subst,$mod5)=($1,$2,$3,$4,$5,$6);
    }
    elsif($lit5 =~ /\A(qr|m)(.)(.+?)((??{$cl->($2)}))()($modre*)\z/) {
      ($op,$delim,$pat5,$delimC,$subst,$mod5)=($1,$2,$3,$4,$5,$6);
    }
    # s///ubstitution is not supported.
    #  elsif($lit5 =~ /\A(s)(.)(.+?)((??{$cl->($2)}))\2?(.+?)\4($modre*)\z/){
    #    ($op,$delim,$pat5,$delimC,$subst,$mod5)=($1,$2,$3,$4,$5,$6);
    #  }
    else { die "invalid literal: $lit5" }

    return $pat5 if $mod5 eq '';
    return "(?$mod5:$pat5)";
  }
  sub repl {
    my($use6)=@_;
    my($prompt,$dialect);
    if(!$use6) {
      print "Enter a Perl 5 regexp pattern or literal.\n";
      print "Enter just 6 or 5r to use P6 or P5+subrules dialect patterns.\n";
      ($prompt,$dialect) = ("5",'Regexp::ModuleA::P5');
    } else {
      print "Enter a Perl 6 regexp pattern.\n";
      print "Enter just 5 or 5r to use P5 or P5+subrules dialect patterns.\n";
      ($prompt,$dialect) = ("6",'Regexp::ModuleA::P6');
    }
    while(1) {
      print $prompt,": ";
      my $re = <>;
      chomp($re);
      last if $re =~ /\A\z/;
      if($re eq "6"){
        ($prompt,$dialect) = ("6",'Regexp::ModuleA::P6');
        next;        
      }
      if($re eq "5r"){
        ($prompt,$dialect) = ("5r",'Regexp::ModuleA::P5WithSubrules');
        next;        
      }
      if($re =~ /\A(\/|(m|s|qr)\W)/) {
        die "Only P5 literals are currently implemented" if $prompt ne "5";
        $re = convert_p5_re_literal_to_p5_re($re);
        print "As regexp: $re\n";
      }
      my $rx = $dialect->new_rx_from_re($re);
      print "As m-expr: ",$rx->_mexpr,"\n";
      print "Enter string to match against.  Blank line to stop.\nstring: ";
      while(<>) {
        chomp;
        last if /\A\z/;
        print $rx->match($_)->match_describe(),"\n";
        print "string: ";
      }
    }
  }
}

#======================================================================
# Command-line and glue. 
#

# Also used by t/re_tests.t.  Replace that with API, once it exists.
sub Regexp::ModuleA::test_target {
  sub {
    my($mods,$re)=@_;
    my $o = Regexp::ModuleA::P5->new_rx_from_re($re,$mods);
    sub{my($s)=@_;$o->match($s)}
  };
}
sub Regexp::ModuleA::test_target6 {
  sub {
    my($mods,$re)=@_;
    my $o = Regexp::ModuleA::P6->new_rx_from_re($re,$mods);
    sub{my($s)=@_;$o->match($s)}
  };
}

if($0 eq __FILE__ && @ARGV) {
  if($ARGV[0] eq '--test') {
    require './t/re_tests.pl';
    Pkg_re_tests::test(&Regexp::ModuleA::test_target);
    exit;
  }
  if($ARGV[0] eq '--test6') {
    require './t/rx.pl';
    Pkg_re_tests::test6(&Regexp::ModuleA::test_target6);
    exit;
  }
  if($ARGV[0] eq '--repl') {
    shift;
    Regexp::ModuleA::Interactive::repl();
    exit;
  }
  if($ARGV[0] eq '--repl6') {
    shift;
    Regexp::ModuleA::Interactive::repl(6);
    exit;
  }
}


1;
__END__
#; Local Variables:
#; perl-indent-level: 2
#; perl-continued-statement-offset: 2
#; perl-continued-brace-offset: -2
#; indent-tabs-mode: nil
#; End:
#; vim: shiftwidth=2:
