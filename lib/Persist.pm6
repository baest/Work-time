use v6;
use Work-time;

use DBIish;
use DateTime::Parse;

class Persist {
	#has $.file where { .IO.w // die "file not found in $*CWD" } = 'worktime.db';
	has $.file = 'worktime.db';
	has $dbh;

	method setup {
		$!dbh = DBIish.connect("SQLite", :database($!file));
		my $sth = $dbh.do(q:to/STATEMENT/);
			CREATE TABLE IF NOT EXISTS working_day (
				started int NOT NULL,
				ended int NOT NULL
			)
		STATEMENT
	}

	method save (Work-time $login) {
		state $sth = $dbh.prepare(q:to/STATEMENT/);
        INSERT INTO working_day (started, ended)
        VALUES (?, ?)
        STATEMENT

    $sth.execute($login.start.Instant, $login.end.Instant); 

		return 1;
	}

	method !sum-week ($week-num, $year) {
		#my $dt = DateTime.now.truncated-to('week');

		my $dt = DateTime.new(
			:$year,
			:1month
			:i1day,
			:8hour,
			:0minute,
			timezone => $*TZ,
		).truncated-to('week').later(:weeks($week-num));

		state $sth = $dbh.prepare(q:to/STATEMENT/);
        SELECT SUM(ended-started) FROM working_day WHERE started >= ? AND ended <= ?
        STATEMENT

        given $sth {
            .execute($dt.Instant, $dt.later(:1week).earlier(:1minute).Instant);
            return .allrows[0][0];
        }
	}

	method sum-week (:$week-num = Date.today.week-number, :$year = Date.today.year) {
		my ($sum) = self!sum-week($week-num, $year);

		return self.get-time($sum);
	}

	method account-week (:$week-num = Date.today.week-number, :$year = Date.today.year) {
		my ($sum) = self!sum-week($week-num, $year);
		$sum -= (37 * 60 + 30) * 60;

		return self.get-time($sum);
	}

	method get-time ($secs) {
		my $hours = $secs / 3600;
		my $min = ($secs - Int($hours) * 3600) / 60;
		my $minus = '';

		$minus = '-' if $min < 0 || $hours < 0;

		return sprintf '%s%d:%02d', $minus, $hours.abs, $min.abs;
	}

	method account-week-rows () {
		my $dt = DateTime.now.truncated-to('week');

		state $sth = $dbh.prepare(q:to/STATEMENT/);
        SELECT * FROM working_day
				WHERE started >= ? AND ended <= ?
        STATEMENT

		$sth.execute($dt.Instant, $dt.later(:1week).earlier(:1minute).Instant);

		my @rows = $sth.allrows;
		return @rows;

		my $sum = [+] map { $_[1] - $_[0] }, @rows;
		my $hours = $sum / 3600;
		my $min = ($sum % 3600) / 60;

		return sprintf '%02d:%02d', $hours, $min;
	}

	method clear-data {
		$dbh.do('DELETE FROM working_day');
	}

	method load-data (Str $filename where { .IO.r || die "Couldn't load file $filename" }) {
		my $year = 2014;
		my $last_month = 5;

		for $filename.IO.lines -> $line {
			given $line { 
				next if /^^ ','+ \s* $$/;
				next if / 'Total' | 'Fridage' | 'Sygedage' /;

				if /$<week_num>=\d* ',' $<day>=\d+ \s+ $<mon>=\w+ ',' $<hour>=\d+ ":" $<min>=\d+ ','/ {
					my $month = DateTime::Parse.new(~$/<mon>, :rule<month>);

					$year++ if $month < $last_month;
					$last_month = $month;

					my $start = DateTime.new(
						:$year,
						:$month
						:day(~$/<day>),
						#:hour(~$/<hour>),
						#:minute(~$/<min>),
						:8hour,
						:0minute,
						timezone => $*TZ,
					);

					my $end = $start.later(:hour($/<hour>)).later(:minute($/<min>));

					self.save(Work-time.new(:$start, :$end));
				}
			}
		}
	}
}
