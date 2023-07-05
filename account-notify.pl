#!/usr/bin/perl
# (C) 2023 Mike Quin <mike@elite.uk.com>
# Based on format_identify.pl by ResDev (Ben Reser)
# Licensed under the GNU General Public License Version 2 ( https://www.gnu.org/licenses/gpl-2.0.html )
# Requires Irssi > 1.4.1 with scrollback_format set to OFF

use Irssi qw(signal_stop signal_emit signal_remove
             signal_add signal_add_first
             settings_add_str settings_get_str settings_add_bool
	     settings_get_bool
             print );
use strict;

my %saved_colors;
my %session_colors = {};
my @colors = qw/2 4 8 9 13 15/;
my(@account_notify_message_formats) = qw(pubmsg pubmsg_channel msg_private
                                          msg_private_query pubmsg_hilight
                                          pubmsg_hilight_channel action_private
                                          action_private_query action_public
                                          action_public_channel ctcp_requested
                                          ctcp_requested_unknown pubmsg_me
                                          pubmsg_me_channel notice_public notice_private
                                         );


sub format_account_notify_message {
  my ($server, $data, $nick, $address) = @_;
  update_all_formats($server,$nick);
  account_notify_rewrite('event privmsg','format_account_notify_message', $server,$data,$nick,$address);
}

sub format_account_notify_ctcp {
  my ($server, $data, $nick, $address, $target) = @_;
  update_all_formats($server,$nick);
  account_notify_rewrite('ctcp msg','format_account_notify_ctcp', $server,$data,$nick,$address,$target);
}

sub format_account_notify_ctcp_reply {
  my ($server, $data, $nick, $address, $target) = @_;
  update_all_formats($server,$nick);
  account_notify_rewrite('ctcp reply','format_account_notify_ctcp_reply', $server,$data,$nick,$address,$target);
}


sub format_account_notify_notice {
  my ($server, $data, $nick, $address, $target) = @_;
  update_all_formats($server,$nick);
  account_notify_rewrite('event notice','format_account_notify_notice', $server,$data,$nick,$address,$target);
}

sub update_all_formats {
  my ($server,$nick) = @_;
  foreach my $format (@account_notify_message_formats) {
    if ($server->nicks_get_same($nick) && irclc($server->nicks_get_same($nick)->{'account'}) eq irclc($nick)) {
      update_account_notify($server,$format,colourise($nick).'$0');
    } elsif ($server->nicks_get_same($nick) && $server->nicks_get_same($nick)->{'account'} ne '*') {
      update_account_notify($server,$format,colourise($nick). '$0' . "(" . $server->nicks_get_same($nick)->{'account'} . ")");
    } else {
      update_account_notify($server,$format,colourise($nick).'~$0');
    }
  }
}

sub replace_account_notify {
  my ($format, $entry) = @_;

  my ($nickarg) = $format =~ /{\s*account_notify\s+?([^\s]+?)\s*}/;
  $entry =~ s/\$0/$nickarg/;
  $format =~ s/{\s*account_notify\s+?[^\s]+?\s*}/$entry/g;
  return $format;
}

# rewrite the message now that we've updated the formats
sub account_notify_rewrite {
  my $signal = shift;
  my $proc = shift;

  signal_stop();
  signal_remove($signal,$proc);
  signal_emit($signal, @_);
  signal_add($signal,$proc);
}

  
# Issue the format update after generating the new format.
sub update_account_notify {
  my ($server,$entry,$nick) = @_;

  my $identify_format = settings_get_str("${entry}_identify");
  my $replaced_format = replace_account_notify($identify_format,$nick);
  $server->command("^format $entry " . $replaced_format);
}
if(settings_get_bool('scrollback_format')) {
Irssi::print('scrollback_format is ON, this script may behave unpredictably.');
Irssi::print('To disable it, do /set scrollback_format OFF');
}
Irssi::signal_add_first( {
		    'event privmsg', 'format_account_notify_message',
                    'event notice', 'format_account_notify_notice',
                    'ctcp msg', 'format_account_notify_ctcp',
                    'ctcp reply', 'format_account_notify_ctcp_reply',
		   });


sub simple_hash {
  my ($string) = @_;
  chomp $string;
  my @chars = split //, $string;
  my $counter;

  foreach my $char (@chars) {
    $counter += ord $char;
  }

  $counter = $colors[($counter % @colors)];
  return $counter;
}

sub colourise {
  return if(!settings_get_bool('format_colour'));
  my ($nick) = @_;
  my $color = $saved_colors{$nick};
  if (!$color) {
    $color = $session_colors{$nick};
  }
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
  }
  $color = "0".$color if ($color < 10);
  return chr(3).$color;
}

sub irclc {
  # converts a string to lower case, using rfc1459 casemapping
  my $s=shift;
  $s=~tr/A-Z[]\^/a-z{}|~/;
  return $s;
}


# How we format the nick.  $0 is the nick we'll be formating.
settings_add_str('account_notify','format_identified_nick','$0');
settings_add_str('account_notify','format_unidentified_nick','~$0');
settings_add_str('account_notify','format_unknown_nick','$0');
settings_add_bool('account_notify','format_colour',0);
settings_add_bool('account_notify','account_notify_debug',0);

# What we use for the formats...
# Don't modify here, use the /set command or modify in the ~/.irssi/config file.
settings_add_str('account_notify','pubmsg_identify','{pubmsgnick $2 {pubnick {account_notify $0}}}$1');
settings_add_str('account_notify','pubmsg_channel_identify','{pubmsgnick $3 {pubnick {account_notify $0}}{msgchannel $1}}$2');
settings_add_str('account_notify','msg_private_identify','{privmsg {account_notify $0} $1 }$2');
settings_add_str('account_notify','msg_private_query_identify','{privmsgnick {account_notify $0}}$2');
settings_add_str('account_notify','pubmsg_hilight_identify','{pubmsghinick {account_notify $3$1} $0 }$2');
settings_add_str('account_notify','pubmsg_hilight_channel_identify','{pubmsghinick {account_notify $4$1:$2} $0 }$3');
settings_add_str('account_notify','action_private_identify','{pvtaction {account_notify $0}}$2');
settings_add_str('account_notify','action_private_query_identify','{pvtaction_query {account_notify $0}}$2');
settings_add_str('account_notify','action_public_identify','{pubaction {account_notify $0}}$1');
settings_add_str('account_notify','action_public_channel_identify', '{pubaction {account_notify $0}{msgchannel $1}}$2');
settings_add_str('account_notify','ctcp_requested_identify','{ctcp {hilight {account_notify $0}} {comment $1} requested CTCP {hilight $2} from {nick $4}}: $3');
settings_add_str('account_notify','ctcp_requested_unknown_identify','{ctcp {hilight {account_notify $0}} {comment $1} requested unknown CTCP {hilight $2} from {nick $4}}: $3');
settings_add_str('account_notify','pubmsg_me_identify','{pubmsgmenick $2 {menick {account_notify $0}}}$1');
settings_add_str('account_notify','pubmsg_me_channel_identify','{pubmsgmenick $3 {menick {account_notify $0}}{msgchannel $1}}$2');
settings_add_str('account_notify','notice_public_identify','{notice {account_notify $0}{pubnotice_channel $1}}$2');
settings_add_str('account_notify','notice_private_identify','{notice {account_notify $0}{pvtnotice_host $1}}$2');
settings_add_str('account_notify','ctcp_reply_identify','CTCP {hilight $0} reply from {nick {account_notify $1}}: $2');
settings_add_str('account_notify','ctcp_reply_channel_identify','CTCP {hilight $0} reply from {nick {account_notify $1}} in channel {channel $3}: $2');
settings_add_str('account_notify','ctcp_ping_reply_identify','CTCP {hilight PING} reply from {nick {account_notify $0}}: $1.$[-3.0]2 seconds');
