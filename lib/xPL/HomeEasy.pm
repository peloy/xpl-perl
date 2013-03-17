package xPL::HomeEasy;

=head1 NAME

xPL::HomeEasy - Perl extension for xPL HomeEasy Encoding/Decoding

=head1 SYNOPSIS

  use xPL::HomeEasy;

  my $rfcode = xPL::HomeEasy::to_rf(address => "0x31f8177",
                                    unit => '1',
                                    command => 'on');

  my $res = xPL::HomeEasy::from_rf($rfcode);

=head1 DESCRIPTION

This is a module for handling the encoding/decoding of HomeEasy
messages.  These methods are not symmetrical because the RFXCOM
receiver and RFXCOM transmitter use different length parameters.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use English qw/-no_match_vars/;
use xPL::Message;
use Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';
our $SVNVERSION = qw/$Revision: 370 $/[1];

=head2 C<to_rf( %parameter_hash )>

Takes a parameter hash describing an HomeEasy command returns an array
reference of bytes containing the command in RF encoded form.

=cut

sub to_rf {
  my %p = @_;
  my @bytes = ( 0, 0, 0, 0, 0 );
  my $length = 33;
  my $command;
  if ($p{command} eq 'preset') {
    $length = 36;
    $bytes[4] = $p{level} << 4;
    $command = 0;
  } else {
    $command = $p{command} eq 'on' ? 1 : 0;
  }
  if ($p{unit} eq 'group') {
    $p{unit} = 0;
    $command |= 0x2;
  }
  my $addr = encode_address($p{address});
  $bytes[0] = $addr >> 18;
  $bytes[1] = ($addr >> 10) & 0xff;
  $bytes[2] = ($addr >> 2) & 0xff;
  $bytes[3] = (($addr & 0x3) << 6);
  $bytes[3] |= $p{unit};
  $bytes[3] |= ($command << 4);
  return [ $length, \@bytes ];
}

=head2 C<from_rf( $bytes )>

Takes an array reference of bytes from an RF message and converts it
in to an hash reference with the details.

=cut

sub from_rf {
  my $length = shift;
  my $bytes = shift;
  my %p = ();
  $p{address} = ($bytes->[0] << 18) + ($bytes->[1] << 10) +
    ($bytes->[2] << 2) + ($bytes->[3] >> 6);
  my $command = ($bytes->[3] >> 4) & 0x3;
  $p{unit} = ($command & 0x2) ? 'group' : ($bytes->[3] & 0xf);
  if ($length == 36) {
    $p{command} =  'preset';
    $p{level} = $bytes->[4] >> 4;
  } else {
    $p{command} = ($command & 0x1) ? 'on' : 'off';
  }
  return \%p;
}

=head2 C<encode_address( $addr )>

Takes a 26-bit address in the form of a hex string prefixed by '0x' or
an arbitrary string.  A hex string is converted in the obvious way.
An arbitrary string is hashed to a 26-bit value.

=cut

sub encode_address {
  my $addr = shift;
  return hex($addr) & 0x3ffffff if ($addr =~ /^0x[0-9a-f]{1,8}$/i);
  my $val = 0;
  my $offset = 0;
  foreach my $b (map { ord $_ } split //, $addr) {
    $val ^= ($b&0x7f) << $offset;
    $offset += 4;
    $offset = 0 if ($offset > 20);
  }
  return $val & 0x3ffffff;
}

1;
__END__

=head1 EXPORT

None by default.

=head1 SEE ALSO

Project website: http://www.xpl-perl.org.uk/

=head1 AUTHOR

Mark Hindess, E<lt>soft-xpl-perl@temporalanomaly.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 by Mark Hindess

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut