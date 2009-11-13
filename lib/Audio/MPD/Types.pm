use 5.008;
use warnings;
use strict;

package Audio::MPD::Types;
# ABSTRACT: types used in the distribution

use Moose::Util::TypeConstraints;
use Sub::Exporter;
use Sub::Exporter -setup => { exports => [ qw{ CONNTYPE } ] };

enum CONNTYPE  => qw{ reuse once };

1;
__END__

=head1 DESCRIPTION

This module implements the specific types used by the distribution, and
exports them. It is using L<Sub::Exporter> underneath, so you can use
all the shenanigans to change the export names.

Current types defined and exported:

=over 4

=item * CONNTYPE - a simple enumeration, allowing only C<reuse>
or C<once>.

=back
