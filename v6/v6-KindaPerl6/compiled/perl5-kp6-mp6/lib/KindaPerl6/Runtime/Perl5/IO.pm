# use strict; $meta_Value is not defined

=head2 $::IO

low level IO module

If guard_insecure_code is on ($::Kp6Security) then this code will die.

=head3 Parents:

$::Value

=head3 Attributes:

none

=head3 Methods:

=over

=item mkdir

=item rmdir

=back

=head1 AUTHORS

The Pugs Team E<lt>perl6-compiler@perl.orgE<gt>.

=head1 SEE ALSO

The Perl 6 homepage at L<http://dev.perl.org/perl6>.

The Pugs homepage at L<http://pugscode.org/>.

=head1 COPYRIGHT

Copyright 2007 by Flavio Soibelmann Glock and others.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

my $meta_Value = ::DISPATCH($::Value,'HOW');

$::IO = KindaPerl6::Runtime::Perl5::MOP::make_class(
    name    => 'IO',
    parents => [$meta_Value],
    methods => {
        mkdir => sub {
            ::DISPATCH( $::Kp6Security, 'guard_insecure_code' );
            my $self    = shift;
            my $dirname = GLOBAL::_str( $_[0] );
            ::DISPATCH( $::Int, 'new', mkdir($dirname) ? 1 : 0 );
        },
        rmdir => sub {
            ::DISPATCH( $::Kp6Security, 'guard_insecure_code' );
            my $self    = shift;
            my $dirname = GLOBAL::_str( $_[0] );
            ::DISPATCH( $::Int, 'new', rmdir($dirname) ? 1 : 0 );
        },
    }
);

1;
