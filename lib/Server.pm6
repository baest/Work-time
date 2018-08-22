use v6;

use Work-time;
use Persist;

use Cro::HTTP::Router;
use Cro::HTTP::Server;

my regex time-match { $<hour> = \d**1..2 ':'? $<minute> = \d**2 }
my subset time of Str where /^ <time-match>  $/;
my regex date-match { [ $<month> = \d**2 $<day> = \d**2 |  $<year> = [ \d**2 | \d**4 ] $<month> = \d**2 $<day> = \d**2 ] }
my regex from-to-time-match { ^ $<from-hour> = \d**1..2 [ $<from-min> = \d**2 ]? '-' $<to-hour> = \d**1..2 [ $<to-min> = \d**2 ]? $ }

my subset set-date of Str where /^ $<mydate> = [ \d**4  | \d**6 | \d**8 ] $/;
my subset set-time of Str where / <from-to-time-match> /;
my subset pick-entry of Str where / \- \d+ /;

class Server {
	has Work-time $.work-time is rw;
	has Persist $.persist is rw = Persist.new();
	has Bool $.verbose;

	method start {
		$!work-time = $!persist.get-current // Work-time.new;

		my $application = self.routes();

		say 'Ready';
		$!persist.save($!work-time);
		my Cro::Service $service = Cro::HTTP::Server.new: :host<localhost>, :port<10000>, :$application;
		$service.start;
		react whenever signal(SIGINT) { $service.stop; exit; }
	}

	method routes() is export {
		route {
			get -> 'checkin' {
				self.set-to-now;
				self.handle_update;
			}
			get -> 'login' {
				self.set-to-now;
				self.handle_update;
			}
			get -> 'logout' {
				self.set-to-now;
				self.handle_update;
			}
			get -> 'no-lunch' {
				$!work-time.had-lunch = False;
				self.handle_update;
			}
			get -> 'start', time $time is rw {
				self.set-to-time('start', $time);
				self.handle_update;
			}
			get -> 'end', time $time is rw {
				self.set-to-time('end', $time);
				self.handle_update;
			}
			get -> 'set', set-date $set-date is rw, set-time $set-detail is rw {
				my $old-work-time = $!work-time;
				my $dt = DateTime.now();

				$set-date ~~ / <date-match> /;
				my $year = $<date-match><year> // $dt.year;
				$year += 2000 if $year < 2000;
				my $month = $<date-match><month> // $dt.month;
				my $day = $<date-match><day> // $dt.day;

				$dt = DateTime.new(
					:$year,
					:$month,
					:$day,
					timezone => $*TZ,
				);
				self.set($dt, $set-detail);
			}
			get -> 'set', set-time $set-detail is rw {
				self.set(DateTime.now().truncated-to('day'), $set-detail);
			}
			get -> 'set', pick-entry $pick is rw, set-time $set-detail is rw {
                # later since we get a negative number
                self.set(DateTime.now().truncated-to('day').later(days => $pick), $set-detail);
			}
			get -> 'set', pick-entry $pick is rw, 'no-lunch' {
                # later since we get a negative number
                self.set-no-lunch(DateTime.now().truncated-to('day').later(days => $pick));
			}
			post -> 'load' {
				request-body-text -> $file {
					$!persist.load-data($file);
				}
			}
		}
	}

	method output (Str $what, :$is-verbose = False) {
		say $what if $is-verbose || $!verbose;
		content 'text/plain', $what;
	}

	method handle_update {
		$!persist.save($!work-time);
		say ~$!work-time;
	}

	method set-to-now {
		$!work-time.set();
		self.output(~$!work-time);
	}

	method set-to-time (Str $what, time $time) {
		$time ~~ / <time-match> /;
		$!work-time.set($what, DateTime.new(
			date => Date.today,
			hour => $<time-match><hour>,
			minute => $<time-match><minute>,
			timezone => $*TZ,
		));
		self.output(~$!work-time);
	}

    method set-no-lunch($dt) {
		my $wt = $!persist.get(:$dt);
        unless $wt {
            self.output("Record with {$dt.Date.Str} not found", :is-verbose(True));
            return;
        }
        $wt.had-lunch = False;

		$!persist.save($wt);
		self.output(~$wt, :is-verbose(True));
    }

	method set ($dt, $set-detail) {
		#TODO handle lunch, how?
		my $wt = $!persist.get(:$dt);
        unless $wt {
            self.output("Record with {$dt.Date.Str} not found", :is-verbose(True));
            return;
        }

		$set-detail ~~ / <from-to-time-match> /;

        my $from-hour = $<from-to-time-match><from-hour>;
        my $from-min = $<from-to-time-match><from-min>;
        my $to-hour = $<from-to-time-match><to-hour>;
        my $to-min = $<from-to-time-match><to-min>;

		$wt.set(:$from-hour, :$from-min, :$to-hour, :$to-min);

		$!persist.save($wt);
		self.output(~$wt, :is-verbose(True));
	}
}
