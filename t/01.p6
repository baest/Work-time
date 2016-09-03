use v6;
use Test;
use lib 'lib';
use Work-time;

plan 5;

my $dt = DateTime.now.truncated-to('day').later(hours => 8);
my $login = Work-time.new(start => $dt, end => $dt.later(hours => 8));

isa-ok $login, 'Work-time';

is $login.get-time(), 3600*8, 'Working day is 8 hours';

$login.set($dt.later(hours => 16).earlier(minute => 1));
is $login.get-time(), 3600*16-60, 'Working day is 16 hours, long day';

$login.set($dt.later(hours => 16));

is $login.get-time(), 0, 'New day just set, no time worked';

$login = Work-time.new(start => $dt, end => $dt.later(hours => 8));
$login.set($dt.later(day => 1));
$login.set($dt.later(day => 1).later(hours => 8));

is $login.get-time(), 3600*8, 'New day is 8 hours';
