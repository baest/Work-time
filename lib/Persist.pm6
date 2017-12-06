use v6;
use Work-time;

use DBIish;
use DateTime::Parse;

class Persist {
	#has $.file where { .IO.w // die "file not found in $*CWD" } = 'worktime.db';
	has $.file;# = 'worktime.db';
	has $.dbh;

	submethod BUILD (:file($!file) = 'worktime.db') {
		$!dbh = DBIish.connect("SQLite", :database($!file));
		$!dbh.do(q:to/STATEMENT/);
			CREATE TABLE IF NOT EXISTS version (
				version int NOT NULL DEFAULT 1
			)
		STATEMENT
		$!dbh.do(q:to/STATEMENT/);
			CREATE TABLE IF NOT EXISTS working_day (
				started int NOT NULL
			,	ended int NOT NULL
			,	had_lunch int NOT NULL DEFAULT 1
			)
		STATEMENT
		$!dbh.do(q:to/STATEMENT/);
			CREATE VIEW IF NOT EXISTS v_working_day AS 
				SELECT
					rowid
				,	started
				,	ended
				,	datetime(started, 'unixepoch') as started_date
				,	datetime(ended, 'unixepoch') as ended_date
				,	(ended-started-1800*had_lunch) as total
				FROM working_day;
			;
		STATEMENT

		$!dbh.do(q:to/STATEMENT/);
			CREATE VIEW IF NOT EXISTS v_working_day_pretty AS 
				SELECT
					*
				,	datetime(started, 'unixepoch') as started_date
				,	datetime(ended, 'unixepoch') as ended_date
				,	(total/3600) || ':' || ((total%3600)/60)
				FROM v_working_day;
			;
		STATEMENT
	}

	method save (Work-time $login) {
		state $ins_sth = $!dbh.prepare(q:to/STATEMENT/);
			INSERT INTO working_day (started, ended, had_lunch)
			VALUES (?, ?, ?)
		STATEMENT
		state $upd_sth = $!dbh.prepare(q:to/STATEMENT/);
			UPDATE working_day SET started = ?, ended = ?, had_lunch = ? WHERE rowid = ?
		STATEMENT

		my $sth = ($login.id) ?? $upd_sth !! $ins_sth;
        warn $login.id;
		my @params = Int($login.start.Instant), Int($login.end.Instant), $login.had-lunch.Numeric;
		@params.push($login.id) if $login.id;

		$sth.execute(|@params);

		return 1;
	}

	method get-current () returns Work-time {
		state $sth = $!dbh.prepare(q:to/STATEMENT/);
			SELECT rowid, * FROM working_day WHERE date(started, 'unixepoch') = CURRENT_DATE
		STATEMENT

		$sth.execute();
		my @rows = $sth.allrows;
		return unless @rows;

		my $start = DateTime.new(+@rows[0][1], :timezone($*TZ));
		my $end = DateTime.new(+@rows[0][2], :timezone($*TZ));

		return Work-time.new(:id(@rows[0][0]), :$start, :$end, :had-lunch(?@rows[0][3]));
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

		state $sth = $!dbh.prepare(q:to/STATEMENT/);
		SELECT SUM(total) FROM v_working_day WHERE started >= ? AND ended <= ?
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

		state $sth = $!dbh.prepare(q:to/STATEMENT/);
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

	method get-current-account {
		state $sth = $!dbh.prepare(q:to/STATEMENT/);
			SELECT SUM(total) - COUNT(*) * 7.5 * 3600 FROM v_working_day
		STATEMENT

		$sth.execute();
		my @rows = $sth.allrows;
		self.get-time(@rows[0][0]);
	}

	method clear-data {
		$!dbh.do('DELETE FROM working_day');
	}

	method load-file (Str $filename where { .IO.r || die "Couldn't load file $filename" }) {
        self.load-file($filename.IO);
    }

	method load-data (Str $file) {
		my $year = 2014;
		my $last_month = 5;
		my $inserted = 0;

		for $file.lines -> $line {
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
						:8hour,
						:0minute,
						timezone => $*TZ,
					);

					my $end = $start.later(:hour($/<hour>)).later(:minute($/<min> + 30));

					self.save(Work-time.new(:$start, :$end));
					$inserted++;
				}
			}
		}
		return $inserted;
	}
}
