use v6;
use Test;
use lib 'lib';
use Work-time;

use Persist;

plan 47;

my $db = 'test.db';

$db.IO.unlink;

isa-ok(my $persist = Persist.new(:file($db)), 'Persist','Grab file');

ok $db.IO ~~ :e, 'DB file exists';

{
	my $dt-loc = DateTime.now.truncated-to('day').truncated-to('week').later(hours => 8);
	for (0..4) {
		ok $persist.save(Work-time.new(start => $dt-loc, end => $dt-loc.later(:8hours).later(:minutes($_)))), 'Saving Work-time';
		$dt-loc = $dt-loc.later(day => 1);
	}
}

is $persist.sum-week, '40:10', 'Get numbers of hours worked per week';
is $persist.account-week, '2:40', 'Get overtime hours per week';

$persist.clear-data;

$persist.load-data("data/timer.csv");

is $persist.sum-week(:week-num(34), :2016year), '39:20', 'Get numbers of hours worked per week for week 34 2016';
is $persist.account-week(:week-num(34), :2016year), '1:50', 'Get overtime hours for week 34';

is $persist.sum-week(:week-num(35), :2016year), '27:45', 'Get numbers of hours worked per week for week 35 2016';
is $persist.account-week(:week-num(35), :2016year), '-9:45', 'Get overtime hours for week 35';

my @week_totalts = <0 0:00 2:15 2:10 0:00 4:40 -6:20 1:30 4:35 2:03 -0:45 1:10 -0:25 2:00 -0:25 0:00 0:00 2:50 -0:50 0:00 -0:40 2:40 -0:15 -0:40 2:05 0:05 0:00 0:00 2:45 0:30 0:30 0:40 0:50 2:35>;

for 1..33 {
	my $total = $persist.account-week(:week-num($_), :2016year);

	is $total, @week_totalts[$_], "The total is correct for week $_";
}

if %*ENV<NO_UNLINK> {
	skip "Not removing file since NO_UNLINK", 1;
}
else {
	ok $db.IO.unlink, 'Remove file';
}
