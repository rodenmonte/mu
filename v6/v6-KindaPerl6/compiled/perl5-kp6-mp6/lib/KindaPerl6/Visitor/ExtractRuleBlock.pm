# Do not edit this file - Generated by MiniPerl6
use v5;
use strict;
use MiniPerl6::Perl5::Runtime;
use MiniPerl6::Perl5::Match;

package KindaPerl6::Visitor::ExtractRuleBlock;
sub new { shift; bless {@_}, "KindaPerl6::Visitor::ExtractRuleBlock" }
my $count;

sub visit {
    my $self   = shift;
    my $List__ = \@_;
    my $node;
    my $node_name;
    my $path;
    do { $node = $List__->[0]; $node_name = $List__->[1]; $path = $List__->[2]; [ $node, $node_name, $path ] };
    do {
        if ( ( $node_name eq 'Rule::Block' ) ) {
            use Data::Dumper;
            my $comp_unit = $path->[ ( 0 - 1 ) ];
            $count = ( $count + 1 );
            my $name = ( '__rule_block' . ( $count . ( '_' . $COMPILER::source_md5 ) ) );
            push(
                @{ $comp_unit->body()->body() },
                Method->new(
                    'block' => Lit::Code->new(
                        'body' => $node->closure()->body(),
                        'sig'  => Sig->new(
                            'invocant'   => '',
                            'positional' => [
                                Lit::SigArgument->new(
                                    'key'   => Var->new( 'namespace' => [], 'name' => 'MATCH', 'twigil' => '', 'sigil' => '$', ),
                                    'value' => (undef),
                                    'type'  => '',
                                    'is_multidimensional' => Val::Bit->new( 'bit' => '0', ),
                                    'is_slurpy'           => Val::Bit->new( 'bit' => '0', ),
                                    'is_optional'         => Val::Bit->new( 'bit' => '0', ),
                                    'is_named_only'       => Val::Bit->new( 'bit' => '0', ),
                                    'is_copy'             => Val::Bit->new( 'bit' => '0', ),
                                    'is_rw'               => Val::Bit->new( 'bit' => '0', ),
                                    'has_default'         => Val::Bit->new( 'bit' => '0', ),
                                )
                            ],
                        ),
                        'pad' => Pad->new(
                            'lexicals' => [
                                Decl->new( 'decl' => 'my', 'var' => Var->new( 'namespace' => [], 'name' => '_',     'twigil' => '', 'sigil' => '@', ), 'type' => '', ),
                                Decl->new( 'decl' => 'my', 'var' => Var->new( 'namespace' => [], 'name' => 'MATCH', 'twigil' => '', 'sigil' => '$', ), 'type' => '', )
                            ],
                        ),
                        'state' => {},
                    ),
                    'name' => $name,
                )
            );
            push( @{ $node->closure()->body() }, Return->new( 'result' => Val::Buf->new( 'buf' => 'sTrNgE V4l', ), ) );
            $node->closure($name);
            return ($node);
        }
        else { }
    };
    0;
}

1;
