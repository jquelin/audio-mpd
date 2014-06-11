use 5.008;
use warnings;
use strict;

package Audio::MPD::Types;
# ABSTRACT: types used in the distribution

use Moose::Util::TypeConstraints;

enum CONNTYPE => [ qw{ reuse once } ];

1;
__END__

=head1 DESCRIPTION

This module implements the specific types used by the distribution, and
exports them (exporting is done directly by
L<Moose::Util::TypeConstraints>.

Current types defined:

=over 4

=item * CONNTYPE - a simple enumeration, allowing only C<reuse>
or C<once>.

=back
