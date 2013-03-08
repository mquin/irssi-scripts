#!/usr/bin/perl
# (C) 2012 Mike Quin <mike@elite.uk.com>
# Licensed under the GNU General Public License Version 2 ( https://www.gnu.org/licenses/gpl-2.0.html )

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);


$VERSION = "0.1";

%IRSSI = (
    authors     => 'Mike Quin',
    contact     => 'mike@elite.uk.com',
    name        => 'autorelease.pl',
    description => 'Automatically recovers enforced nicks when connecting to freenode.
                    May work on other networks running Atheme services and charybdis family ircds.
                    This script assumes the user is using PASS or CAP SASL to authenticate'
    license     => 'GPLv2'
);

my ($recovering,$sasl);
my $nick='';

sub event_notice {
  my ($server,$message,$sender,$address,$target)=@_;
  if ($address eq 'NickServ@services.' && $recovering==1) {
    if ($message =~/^You are now identified/) {
     $server->send_raw_now("NS RELEASE $nick");
    } elsif ($message =~/^\002?(\S+?)\002? has been released/) {
     $server->send_raw_now("NICK $1");
    }
  }
}

sub event_sasl {
  my ($server,$data)=@_;
  if ($recovering==1 && $data=~/:You are now logged in/) {
    $sasl=1;
  }
}

sub event_connected {
   my ($server,$data)=@_;
   if ($sasl && $recovering) {
    $server->send_raw_now("NS RELEASE $nick");
   }
}
sub event_nick_inuse {
  my ($server,$data)=@_;
  if ($data=~/(\S+) (\S+) :(.*)/) {
    $nick=$2;
  }
  $recovering=1;
}

sub event_nick_unavail {
  my ($server,$data)=@_;

  if ($data=~/(\S+) (\S+) :(.*)/) {
    $nick=$2;
  }

  if ($recovering==1) {
    $server->send_raw_now("NS RELEASE $nick");
  } else {
   $recovering=1;
  }
}

sub server_connected {
  undef $recovering;
  undef $sasl;
  undef $nick;
}

Irssi::signal_add_first('server connected', \&server_connected);
Irssi::signal_add('event 437', \&event_nick_unavail);
Irssi::signal_add('event 433', \&event_nick_inuse);
Irssi::signal_add('event 001', \&event_connected);
Irssi::signal_add('event 900', \&event_sasl);
Irssi::signal_add('message irc notice', \&event_notice);
