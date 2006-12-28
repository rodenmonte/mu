# Do not edit this file - Generated by MiniPerl6
use v5;
use strict;
use MiniPerl6::Perl5::Runtime;
use MiniPerl6::Perl5::Match;
package CompUnit; sub new { shift; bless { @_ }, "CompUnit" } sub name { @_ == 1 ? ( $_[0]->{name} ) : ( $_[0]->{name} = $_[1] ) }; sub attributes { @_ == 1 ? ( $_[0]->{attributes} ) : ( $_[0]->{attributes} = $_[1] ) }; sub methods { @_ == 1 ? ( $_[0]->{methods} ) : ( $_[0]->{methods} = $_[1] ) }; sub body { @_ == 1 ? ( $_[0]->{body} ) : ( $_[0]->{body} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $a = $self->{body}; my  $item; my  $s; $s = ($s . ('package ' . ($self->{name} . (';' . Main::newline())))); $s = ($s . '
          my $base = MO::Compile::Class::SI->new(
            instance_methods => [
            '); do { for my $item ( @{$a} ) { do { if (Main::isa($item, 'Method')) { $s = ($s . (' MO::Compile::Method::Simple->new(' . ('     name       => ' . (Main::quote() . ($item->name() . (Main::quote() . (',    definition => ' . ($item->emit() . (', )' . Main::newline()))))))))) } else {  } } } }; $s = ($s . '  ],
            attributes => [
          '); do { for my $item ( @{$a} ) { do { if ((Main::isa($item, 'Decl') && ($item->decl() eq 'has'))) { my  $name = $item->var()->name();$s = ($s . ('MO::Compile::Attribute::Simple->new( name => ' . (Main::quote() . ($name . (Main::quote() . (', ), ' . Main::newline())))))) } else {  } } } }; $s = ($s . '   ],
            );
          '); ('.sub ' . (Main::quote() . ('_class_vars_' . (Main::quote() . Main::newline())))); do { for my $item ( @{$a} ) { do { if ((Main::isa($item, 'Decl') && ($item->decl() ne 'has'))) { $s = ($s . $item->emit()) } else {  } } } }; $s = ($s . ('.end' . (Main::newline() . Main::newline()))); do { for my $item ( @{$a} ) { do { if (Main::isa($item, 'Sub')) { $s = ($s . $item->emit()) } else {  } } } }; $s = ($s . ('.sub _ :anon :load :init :outer(' . (Main::quote() . ('_class_vars_' . (Main::quote() . (')' . (Main::newline() . ('  .local pmc self' . (Main::newline() . ('  newclass self, ' . (Main::quote() . ($self->{name} . (Main::quote() . Main::newline()))))))))))))); do { for my $item ( @{$a} ) { do { if ((Main::isa($item, 'Decl') && ($item->decl() eq 'has'))) { $s = ($s . $item->emit()) } else {  } };do { if ((Main::isa($item, 'Decl') || (Main::isa($item, 'Sub') || Main::isa($item, 'Method')))) {  } else { $s = ($s . $item->emit()) } } } }; $s = ($s . ('.end' . (Main::newline() . Main::newline()))); return($s) }
;
package Val::Int; sub new { shift; bless { @_ }, "Val::Int" } sub int { @_ == 1 ? ( $_[0]->{int} ) : ( $_[0]->{int} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; $self->{int} }
;
package Val::Bit; sub new { shift; bless { @_ }, "Val::Bit" } sub bit { @_ == 1 ? ( $_[0]->{bit} ) : ( $_[0]->{bit} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; $self->{bit} }
;
package Val::Num; sub new { shift; bless { @_ }, "Val::Num" } sub num { @_ == 1 ? ( $_[0]->{num} ) : ( $_[0]->{num} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; $self->{num} }
;
package Val::Buf; sub new { shift; bless { @_ }, "Val::Buf" } sub buf { @_ == 1 ? ( $_[0]->{buf} ) : ( $_[0]->{buf} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('\'' . ($self->{buf} . '\'')) }
;
package Val::Undef; sub new { shift; bless { @_ }, "Val::Undef" } sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; '(undef)' }
;
package Val::Object; sub new { shift; bless { @_ }, "Val::Object" } sub class { @_ == 1 ? ( $_[0]->{class} ) : ( $_[0]->{class} = $_[1] ) }; sub fields { @_ == 1 ? ( $_[0]->{fields} ) : ( $_[0]->{fields} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('bless(' . (Main::perl($self->{fields}, ) . (', ' . (Main::perl($self->{class}, ) . ')')))) }
;
package Lit::Seq; sub new { shift; bless { @_ }, "Lit::Seq" } sub seq { @_ == 1 ? ( $_[0]->{seq} ) : ( $_[0]->{seq} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('(' . (Main::join([ map { $_->emit() } @{ $self->{seq} } ], ', ') . ')')) }
;
package Lit::Array; sub new { shift; bless { @_ }, "Lit::Array" } sub array { @_ == 1 ? ( $_[0]->{array} ) : ( $_[0]->{array} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('[' . (Main::join([ map { $_->emit() } @{ $self->{array} } ], ', ') . ']')) }
;
package Lit::Hash; sub new { shift; bless { @_ }, "Lit::Hash" } sub hash { @_ == 1 ? ( $_[0]->{hash} ) : ( $_[0]->{hash} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $fields = $self->{hash}; my  $str = ''; do { for my $field ( @{$fields} ) { $str = ($str . ($field->[0]->emit() . (' => ' . ($field->[1]->emit() . ',')))) } }; ('{ ' . ($str . ' }')) }
;
package Lit::Code; sub new { shift; bless { @_ }, "Lit::Code" } 1
;
package Lit::Object; sub new { shift; bless { @_ }, "Lit::Object" } sub class { @_ == 1 ? ( $_[0]->{class} ) : ( $_[0]->{class} = $_[1] ) }; sub fields { @_ == 1 ? ( $_[0]->{fields} ) : ( $_[0]->{fields} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $fields = $self->{fields}; my  $str = ''; do { for my $field ( @{$fields} ) { $str = ($str . ($field->[0]->emit() . (' => ' . ($field->[1]->emit() . ',')))) } }; ($self->{class} . ('->new( ' . ($str . ' )'))) }
;
package Index; sub new { shift; bless { @_ }, "Index" } sub obj { @_ == 1 ? ( $_[0]->{obj} ) : ( $_[0]->{obj} = $_[1] ) }; sub index { @_ == 1 ? ( $_[0]->{index} ) : ( $_[0]->{index} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ($self->{obj}->emit() . ('->[' . ($self->{index}->emit() . ']'))) }
;
package Lookup; sub new { shift; bless { @_ }, "Lookup" } sub obj { @_ == 1 ? ( $_[0]->{obj} ) : ( $_[0]->{obj} = $_[1] ) }; sub index { @_ == 1 ? ( $_[0]->{index} ) : ( $_[0]->{index} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ($self->{obj}->emit() . ('->{' . ($self->{index}->emit() . '}'))) }
;
package Var; sub new { shift; bless { @_ }, "Var" } sub sigil { @_ == 1 ? ( $_[0]->{sigil} ) : ( $_[0]->{sigil} = $_[1] ) }; sub twigil { @_ == 1 ? ( $_[0]->{twigil} ) : ( $_[0]->{twigil} = $_[1] ) }; sub name { @_ == 1 ? ( $_[0]->{name} ) : ( $_[0]->{name} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $table = { '$' => '$','@' => '$List_','%' => '$Hash_','&' => '$Code_', }; (($self->{twigil} eq '.') ? ('$self->{' . ($self->{name} . '}')) : (($self->{name} eq '/') ? ($table->{$self->{sigil}} . 'MATCH') : ($table->{$self->{sigil}} . $self->{name}))) }; sub name { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; $self->{name} }
;
package Bind; sub new { shift; bless { @_ }, "Bind" } sub parameters { @_ == 1 ? ( $_[0]->{parameters} ) : ( $_[0]->{parameters} = $_[1] ) }; sub arguments { @_ == 1 ? ( $_[0]->{arguments} ) : ( $_[0]->{arguments} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; do { if (Main::isa($self->{parameters}, 'Lit::Array')) { my  $a = $self->{parameters}->array();my  $str = 'do { ';my  $i = 0;do { for my $var ( @{$a} ) { my  $bind = Bind->new( 'parameters' => $var,'arguments' => Index->new( 'obj' => $self->{arguments},'index' => Val::Int->new( 'int' => $i, ), ), );$str = ($str . (' ' . ($bind->emit() . '; ')));$i = ($i + 1) } };return(($str . ($self->{parameters}->emit() . ' }'))) } else {  } }; do { if (Main::isa($self->{parameters}, 'Lit::Hash')) { my  $a = $self->{parameters}->hash();my  $b = $self->{arguments}->hash();my  $str = 'do { ';my  $i = 0;my  $arg;do { for my $var ( @{$a} ) { $arg = Val::Undef->new(  );do { for my $var2 ( @{$b} ) { do { if (($var2->[0]->buf() eq $var->[0]->buf())) { $arg = $var2->[1] } else {  } } } };my  $bind = Bind->new( 'parameters' => $var->[1],'arguments' => $arg, );$str = ($str . (' ' . ($bind->emit() . '; ')));$i = ($i + 1) } };return(($str . ($self->{parameters}->emit() . ' }'))) } else {  } }; do { if (Main::isa($self->{parameters}, 'Lit::Object')) { my  $class = $self->{parameters}->class();my  $a = $self->{parameters}->fields();my  $b = $self->{arguments};my  $str = 'do { ';my  $i = 0;my  $arg;do { for my $var ( @{$a} ) { my  $bind = Bind->new( 'parameters' => $var->[1],'arguments' => Call->new( 'invocant' => $b,'method' => $var->[0]->buf(),'arguments' => [],'hyper' => 0, ), );$str = ($str . (' ' . ($bind->emit() . '; ')));$i = ($i + 1) } };return(($str . ($self->{parameters}->emit() . ' }'))) } else {  } }; ($self->{parameters}->emit() . (' = ' . $self->{arguments}->emit())) }
;
package Proto; sub new { shift; bless { @_ }, "Proto" } sub name { @_ == 1 ? ( $_[0]->{name} ) : ( $_[0]->{name} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ("" . $self->{name}) }
;
package Call; sub new { shift; bless { @_ }, "Call" } sub invocant { @_ == 1 ? ( $_[0]->{invocant} ) : ( $_[0]->{invocant} = $_[1] ) }; sub hyper { @_ == 1 ? ( $_[0]->{hyper} ) : ( $_[0]->{hyper} = $_[1] ) }; sub method { @_ == 1 ? ( $_[0]->{method} ) : ( $_[0]->{method} = $_[1] ) }; sub arguments { @_ == 1 ? ( $_[0]->{arguments} ) : ( $_[0]->{arguments} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $invocant = $self->{invocant}->emit(); do { if (($invocant eq 'self')) { $invocant = '$self' } else {  } }; do { if ((($self->{method} eq 'perl') || (($self->{method} eq 'yaml') || (($self->{method} eq 'say') || (($self->{method} eq 'join') || (($self->{method} eq 'chars') || ($self->{method} eq 'isa'))))))) { do { if ($self->{hyper}) { return(('[ map { Main::' . ($self->{method} . ('( $_, ' . (', ' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ', ') . (')' . (' } @{ ' . ($invocant . ' } ]'))))))))) } else { return(('Main::' . ($self->{method} . ('(' . ($invocant . (', ' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ', ') . ')'))))))) } } } else {  } }; my  $meth = $self->{method}; do { if (($meth eq 'postcircumfix:<( )>')) { $meth = '' } else {  } }; my  $call = ('->' . ($meth . ('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ', ') . ')')))); do { if ($self->{hyper}) { ('[ map { $_' . ($call . (' } @{ ' . ($invocant . ' } ]')))) } else { ($invocant . $call) } } }
;
package Apply; sub new { shift; bless { @_ }, "Apply" } sub code { @_ == 1 ? ( $_[0]->{code} ) : ( $_[0]->{code} = $_[1] ) }; sub arguments { @_ == 1 ? ( $_[0]->{arguments} ) : ( $_[0]->{arguments} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $code = $self->{code}; do { if (($code eq 'say')) { return(('Main::say(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ', ') . ')'))) } else {  } }; do { if (($code eq 'print')) { return(('Main::print(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ', ') . ')'))) } else {  } }; do { if (($code eq 'array')) { return(('@{' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . '}'))) } else {  } }; do { if (($code eq 'prefix:<~>')) { return(('("" . ' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . ')'))) } else {  } }; do { if (($code eq 'prefix:<!>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . ' ? 0 : 1)'))) } else {  } }; do { if (($code eq 'prefix:<?>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . ' ? 1 : 0)'))) } else {  } }; do { if (($code eq 'prefix:<$>')) { return(('${' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . '}'))) } else {  } }; do { if (($code eq 'prefix:<@>')) { return(('@{' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . '}'))) } else {  } }; do { if (($code eq 'prefix:<%>')) { return(('%{' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ') . '}'))) } else {  } }; do { if (($code eq 'infix:<~>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' . ') . ')'))) } else {  } }; do { if (($code eq 'infix:<+>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' + ') . ')'))) } else {  } }; do { if (($code eq 'infix:<->')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' - ') . ')'))) } else {  } }; do { if (($code eq 'infix:<&&>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' && ') . ')'))) } else {  } }; do { if (($code eq 'infix:<||>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' || ') . ')'))) } else {  } }; do { if (($code eq 'infix:<eq>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' eq ') . ')'))) } else {  } }; do { if (($code eq 'infix:<ne>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' ne ') . ')'))) } else {  } }; do { if (($code eq 'infix:<==>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' == ') . ')'))) } else {  } }; do { if (($code eq 'infix:<!=>')) { return(('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ' != ') . ')'))) } else {  } }; do { if (($code eq 'ternary:<?? !!>')) { return(('(' . ($self->{arguments}->[0]->emit() . (' ? ' . ($self->{arguments}->[1]->emit() . (' : ' . ($self->{arguments}->[2]->emit() . ')'))))))) } else {  } }; ($self->{code} . ('(' . (Main::join([ map { $_->emit() } @{ $self->{arguments} } ], ', ') . ')'))) }
;
package Return; sub new { shift; bless { @_ }, "Return" } sub result { @_ == 1 ? ( $_[0]->{result} ) : ( $_[0]->{result} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('return(' . ($self->{result}->emit() . ')')) }
;
package If; sub new { shift; bless { @_ }, "If" } sub cond { @_ == 1 ? ( $_[0]->{cond} ) : ( $_[0]->{cond} = $_[1] ) }; sub body { @_ == 1 ? ( $_[0]->{body} ) : ( $_[0]->{body} = $_[1] ) }; sub otherwise { @_ == 1 ? ( $_[0]->{otherwise} ) : ( $_[0]->{otherwise} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('do { if (' . ($self->{cond}->emit() . (') { ' . (Main::join([ map { $_->emit() } @{ $self->{body} } ], ';') . (' } else { ' . (Main::join([ map { $_->emit() } @{ $self->{otherwise} } ], ';') . ' } }')))))) }
;
package For; sub new { shift; bless { @_ }, "For" } sub cond { @_ == 1 ? ( $_[0]->{cond} ) : ( $_[0]->{cond} = $_[1] ) }; sub body { @_ == 1 ? ( $_[0]->{body} ) : ( $_[0]->{body} = $_[1] ) }; sub topic { @_ == 1 ? ( $_[0]->{topic} ) : ( $_[0]->{topic} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $cond = $self->{cond}; do { if ((Main::isa($cond, 'Var') && ($cond->sigil() eq '@'))) { $cond = Apply->new( 'code' => 'prefix:<@>','arguments' => [$cond], ) } else {  } }; ('do { for my ' . ($self->{topic}->emit() . (' ( ' . ($cond->emit() . (' ) { ' . (Main::join([ map { $_->emit() } @{ $self->{body} } ], ';') . ' } }')))))) }
;
package Decl; sub new { shift; bless { @_ }, "Decl" } sub decl { @_ == 1 ? ( $_[0]->{decl} ) : ( $_[0]->{decl} = $_[1] ) }; sub type { @_ == 1 ? ( $_[0]->{type} ) : ( $_[0]->{type} = $_[1] ) }; sub var { @_ == 1 ? ( $_[0]->{var} ) : ( $_[0]->{var} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $decl = $self->{decl}; my  $name = $self->{var}->name(); (($decl eq 'has') ? ('sub ' . ($name . (' { ' . ('@_ == 1 ' . ('? ( $_[0]->{' . ($name . ('} ) ' . (': ( $_[0]->{' . ($name . ('} = $_[1] ) ' . '}')))))))))) : ($self->{decl} . (' ' . ($self->{type} . (' ' . $self->{var}->emit()))))) }
;
package Sig; sub new { shift; bless { @_ }, "Sig" } sub invocant { @_ == 1 ? ( $_[0]->{invocant} ) : ( $_[0]->{invocant} = $_[1] ) }; sub positional { @_ == 1 ? ( $_[0]->{positional} ) : ( $_[0]->{positional} = $_[1] ) }; sub named { @_ == 1 ? ( $_[0]->{named} ) : ( $_[0]->{named} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ' print \'Signature - TODO\'; die \'Signature - TODO\'; ' }; sub invocant { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; $self->{invocant} }; sub positional { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; $self->{positional} }
;
package Method; sub new { shift; bless { @_ }, "Method" } sub name { @_ == 1 ? ( $_[0]->{name} ) : ( $_[0]->{name} = $_[1] ) }; sub sig { @_ == 1 ? ( $_[0]->{sig} ) : ( $_[0]->{sig} = $_[1] ) }; sub block { @_ == 1 ? ( $_[0]->{block} ) : ( $_[0]->{block} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $sig = $self->{sig}; my  $invocant = $sig->invocant(); my  $pos = $sig->positional(); my  $str = 'my $List__ = \@_; no strict "vars"; '; my  $bind = Bind->new( 'parameters' => Lit::Array->new( 'array' => $sig->positional(), ),'arguments' => Var->new( 'sigil' => '@','twigil' => '','name' => '_', ), ); $str = ($str . ($bind->emit() . '; ')); ('sub { ' . ('my ' . ($invocant->emit() . (' = shift; ' . ($str . (Main::join([ map { $_->emit() } @{ $self->{block} } ], '; ') . ' }')))))) }
;
package Sub; sub new { shift; bless { @_ }, "Sub" } sub name { @_ == 1 ? ( $_[0]->{name} ) : ( $_[0]->{name} = $_[1] ) }; sub sig { @_ == 1 ? ( $_[0]->{sig} ) : ( $_[0]->{sig} = $_[1] ) }; sub block { @_ == 1 ? ( $_[0]->{block} ) : ( $_[0]->{block} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; my  $sig = $self->{sig}; my  $pos = $sig->positional(); my  $str = 'my $List__ = \@_; no strict "vars"; '; my  $bind = Bind->new( 'parameters' => Lit::Array->new( 'array' => $sig->positional(), ),'arguments' => Var->new( 'sigil' => '@','twigil' => '','name' => '_', ), ); $str = ($str . ($bind->emit() . '; ')); ('sub ' . ($self->{name} . (' { ' . ($str . (Main::join([ map { $_->emit() } @{ $self->{block} } ], '; ') . ' }'))))) }
;
package Do; sub new { shift; bless { @_ }, "Do" } sub block { @_ == 1 ? ( $_[0]->{block} ) : ( $_[0]->{block} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('do { ' . (Main::join([ map { $_->emit() } @{ $self->{block} } ], '; ') . ' }')) }
;
package Use; sub new { shift; bless { @_ }, "Use" } sub mod { @_ == 1 ? ( $_[0]->{mod} ) : ( $_[0]->{mod} = $_[1] ) }; sub emit { my $self = shift; my $List__ = \@_; no strict "vars"; do { [] }; ('use ' . $self->{mod}) }
;
1;
