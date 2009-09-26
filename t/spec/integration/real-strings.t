use v6;
use Test;
plan 11;

# Rakudo had a regression that
# string returned from regexes were Parrot strings, not Perl 6 strings.
# Basic stuff like interpolation and .uc, .lc still worked, but other things
# did not. We test it here by calling .trans on the string, which dies
# because parrot's .trans has a different calling syntax

{
    my $x = 'a';
    is $x.trans(['a'] => ['b']), 'b', 
       'basic sanity: .trans works with native Perl 6 strings';
}

{
    my $x = 'abc'.split(m/b/).[0];
    lives_ok {$x.trans(['a'] => ['b']) }, 
       'Still works with strings returned from split() (lives)';
    is $x.trans(['a'] => ['b']), 'b',
       'Still works with strings returned from split() (result)';
}

dies_ok { for "a b c".split(/\s/) -> $foo { $foo = $foo; } }, 'variables returned from split and passed to pointy block are still ro';

# used to be RT #55962

{
    my @foo = 'AB'.split('');
    @foo[0]++;
    is ~@foo, 'B B', 'Str.split(Str) works with postfix:<++>';
}

ok 1.Str ~~ / ^ 1 $ /, 'RT 66366; 1.Str is a "good" Str';

is "helo".flip().trans("aeiou" => "AEIOU"), 'OlEh', '.flip.trans (RT 66300)';
is "helo".flip.trans(("aeiou" => "AEIOU")), 'OlEh', '.flip.trans (RT 66300)';
is "helo".lc.trans(("aeiou" => "AEIOU")),   'hElO', '.flip.trans (RT 66300)';

# http://rt.perl.org/rt3/Ticket/Display.html?id=66596
# .subst within a multi sub didn't work

{
    multi substtest (Str $d) {
        $d.subst(/o/, 'a')
    }
    is substtest("mop"), "map", '.subst works in a multi';
}

# not a "real string', but a "real hash" bug found in Rakudo:

{
    my $x = 0;
    for %*VM.kv -> $k, $v { $x++};
    is $x, +%*VM.keys, '%*VM.kv is self-consistent';
}

# vim: ft=perl6
