use v6;
use Test;
use lib 'lib';
use Work-time;

use Persist;

my $db = 'test.db';

$db.IO.unlink;

isa-ok(my $persist = Persist.new(:file($db)), 'Persist','Grab file');

ok $db.IO ~~ :e, 'DB file exists';

{
	my $dt-loc = DateTime.now.truncated-to('day').truncated-to('week').later(hours => 8);
	for (0..4) {
		ok $persist.save(Work-time.new(start => $dt-loc, end => $dt-loc.later(:8hours).later(:minutes($_)), had-lunch => False)), 'Saving Work-time';
		$dt-loc = $dt-loc.later(day => 1);
	}
}

is $persist.sum-week, '40:10', 'Get numbers of hours worked per week';
is $persist.account-week, '2:40', 'Get overtime hours per week';

$persist.clear-data;

# make sure a next day gets a new id
my $dt-start = DateTime.new(
	:2018year,
	:1month
	:2day,
	:0hour,
	:1minute,
	timezone => $*TZ,
);
my $wt = Work-time.new(start => $dt-start, had-lunch => True);
$wt.set('end', $dt-start.later(minute => 20));
$persist.save($wt);

$wt.set($dt-start.later(day => 1));
is $persist.sum-week(dt => $dt-start), '-0:10', 'Get really short week after only lunch';
$wt.set($dt-start.later(day => 1).later(hour => 1));
$persist.save($wt);
is $persist.sum-week(dt => $dt-start), '0:20', 'Get really short week and also make sure that we do not override first work time';

$persist.clear-data;

is 805, $persist.load-file("data/timer.csv"), 'Saved correct number of days';

# 22/8/16 -> week 34
my $dt = DateTime.new(
	:2016year,
	:8month
	:22day,
	:0hour,
	:1minute,
	timezone => $*TZ,
);
is $persist.sum-week(:$dt), '39:20', 'Get numbers of hours worked per week for week 34 2016';
is $persist.account-week(:$dt), '1:50', 'Get overtime hours for week 34';

$dt .= later(:week(1));
is $persist.sum-week(:$dt), '27:45', 'Get numbers of hours worked per week for week 35 2016';
is $persist.account-week(:$dt), '-9:45', 'Get overtime hours for week 35';

my @week_totalts = <0 0:00 2:15 2:10 0:00 4:40 -6:20 1:30 4:35 2:03 -0:45 1:10 -0:25 2:00 -0:25 0:00 0:00 2:50 -0:50 0:00 -0:40 2:40 -0:15 -0:40 2:05 0:05 0:00 0:00 2:45 0:30 0:30 0:40 0:50 2:35>;

# week 1
$dt = DateTime.new(
	:2016year,
	:1month
	:4day,
	:0hour,
	:1minute,
	timezone => $*TZ,
);
for 1..33 {
	my $total = $persist.account-week(:$dt);

	$dt .= later(:week(1));
	is $total, @week_totalts[$_], "The total is correct for week $_";
}

# first day at work
$dt = DateTime.new(
	:2014year,
	:8month
	:4day,
	:0hour,
	:1minute,
	timezone => $*TZ,
);

is $persist.get-current-account, '34:10', 'Current flex is correct';

if %*ENV<NO_UNLINK> {
	skip "Not removing file since NO_UNLINK", 1;
}
else {
	ok $db.IO.unlink, 'Remove file';
}

done-testing;
