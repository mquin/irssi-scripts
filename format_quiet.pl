#!/usr/bin/perl
# (C) 2012 Mike Quin <mike@elite.uk.com>
# Licensed under the GNU General Public License Version 2 ( https://www.gnu.org/licenses/gpl-2.0.html )

use Irssi;
use strict;
use vars qw($VERSION %IRSSI); 
$VERSION = "0.8.15";
%IRSSI = (
    authors     => "Mike Quin",
    contact     => "mike at elite.uk.com",
    name        => "format_quiet",
    description => "Format quiet information on charybdis family ircds using the 728 numeric",
    license     => "GPLv2",
    url         => "http://www.elite.uk.com/mike/irc/",
);

Irssi::theme_register([
  'quietlist', '{channel $0}: quiet {ban $1} {comment by {nick $2}, $3 secs ago}'
]);

sub event_quiet_list {
  my ($server, $data) = @_;
  my @args=split /\ /,$data;
  my $witem= $server->window_item_find($args[1]);
  if (defined $witem) {
    $witem->printformat(MSGLEVEL_CRAP, 'quietlist', $args[1], $args[3], $args[4], time()-$args[5] );
  } else {
    $server->printformat($args[0], MSGLEVEL_CRAP, 'quietlist', $args[1], $args[3], $args[4], time()-$args[5] );
  }
  Irssi::signal_stop();
}

Irssi::signal_add ( {
        'event 728' => \&event_quiet_list 
} );

