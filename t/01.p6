use v6;
use Test;
use lib 'lib';
use Work-time;

plan 9;

my $dt = DateTime.now.truncated-to('day').later(hours => 8);
my $login = Work-time.new(start => $dt, end => $dt.later(hours => 8), :!had-lunch);

isa-ok $login, 'Work-time';

is $login.get-time(), 3600*8, 'Working day is 8 hours';

$login.set($dt.later(hours => 16).earlier(minute => 1));
is $login.get-time(), 3600*16-60, 'Working day is 16 hours, long day';

my $old-login = $login.set($dt.later(hours => 16));
$login.had-lunch = False;

is $login.get-time(), 0, 'New day just set, no time worked';
is $old-login.get-time(), 3600*16-60, 'Working day for yesterday is still long';

$login = Work-time.new(start => $dt, end => $dt.later(hours => 8), :!had-lunch);
$login.set($dt.later(day => 1));
$login.set($dt.later(day => 1).later(hours => 8));

is $login.get-time(), 3600*8 - 1800, 'New day is 7:30 hours, since lunch is automatically on on an new day';

$login = Work-time.new(start => $dt, end => $dt.later(hours => 8).later(minutes => 5).later(seconds => 5), :!had-lunch);

is $login.get-time-pretty, '08:05', 'Get time in pretty format';

$login = Work-time.new(start => $dt, end => $dt.later(hours => 8), :!had-lunch);

{
	temp $dt;
	for 1..8 {
		$login.set($dt.later(hours => $_));
	}	

	my $old-login = $login.set($dt.later(hours => 16));
	$login.had-lunch = False;
	is $login.get-time(), 0, 'New day just set, no time worked';
	is $old-login.get-time(), 3600*8, 'Working day for yesterday';
}
