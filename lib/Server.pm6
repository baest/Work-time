use v6;

use Work-time;
use Persist;

use Cro::HTTP::Router;
use Cro::HTTP::Server;

my regex time-match { $<hour> = \d**1..2 ':'? $<minute> = \d**2 }
my subset time of Str where /^ <time-match>  $/;
my regex date-match { [ $<month> = \d**2 $<day> = \d**2 |  $<year> = [ \d**2 | \d**4 ] $<month> = \d**2 $<day> = \d**2 ] }
my regex from-to-time-match { ^ $<from-hour> = \d**1..2 [ $<from-min> = \d**2 ]? '-' $<to-hour> = \d**1..2 [ $<to-min> = \d**2 ]? $ }

my subset start-end of Str where /^ 'start' | 'end' $/;
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

				$dt = DateTime.new(
					:$year,
					:month($<date-match><month> // $dt.month),
					:day($<date-match><day> // $dt.day),
					timezone => $*TZ,
				);
				self.set($dt, $set-detail);
			}
			get -> 'set', set-time $set-detail is rw {
				self.set(DateTime.now().truncated-to('day'), $set-detail);
			}
			get -> 'set', pick-entry $pick is rw, set-time $set-detail is rw {
                # later since we get a negative number
                self.set(DateTime.now().truncated-to('day').later(days => $pick), $set-detail, fail-if-not-found => True);
			}
			get -> start-end $start-end is rw, pick-entry $pick is rw, time $time is rw {
                my $dt = DateTime.now().truncated-to('day').later(days => $pick);
                my $wt = $!persist.get(:$dt);

                unless $wt {
                    self.output("Record with {$dt.Date.Str} not found", :is-verbose(True));
                    return;
                }

				self.set-to-time($start-end, $time, $wt);
				self.handle_update($wt);
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

	method handle_update ($wt = $!work-time) {
		$!persist.save($wt);
		say ~$wt;
	}

	method set-to-now {
        if ($!work-time.is-next-day()) {
            # output old time
            self.notify(~$!work-time);
        }
		$!work-time.set();
		self.output(~$!work-time);
	}

	method set-to-time (Str $what, time $time, $wt = $!work-time) {
		$time ~~ / <time-match> /;
		$wt.set($what, DateTime.new(
			date => Date.today,
			hour => $<time-match><hour>,
			minute => $<time-match><minute>,
			timezone => $*TZ,
		));
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

	method set ($dt, $set-detail, :$fail-if-not-found = False) {
		my $wt = $!persist.get(:$dt);
        if ($fail-if-not-found && !$wt) {
            self.output("Record with {$dt.Date.Str} not found", :is-verbose(True));
            return;
        }
        else {
            $wt //= Work-time.new(start => $dt, end => $dt);
        }

		$set-detail ~~ / <from-to-time-match> /;

        my $from-hour = $<from-to-time-match><from-hour>;
        my $from-min = $<from-to-time-match><from-min> // 0;
        my $to-hour = $<from-to-time-match><to-hour>;
        my $to-min = $<from-to-time-match><to-min> // 0;

		$wt.set-from-to(:$from-hour, :$from-min, :$to-hour, :$to-min);

		$!persist.save($wt);
		self.output(~$wt, :is-verbose(True));
	}

    method notify ($text) {
        state $notify;
        my $expire_never = 0;
        unless ($notify) {
            my $class = 'Desktop::Notify';
            try require ::($class);
            unless ::($class) ~~ Failure {
                $notify = ::($class).new(app-name => 'irssi');
            }
        }

        my $n = $notify.new-notification('Work time for yesterday:', $text, 'stop');

        $notify.set-timeout($n, $expire_never);

        $notify.show($n);
    }
}
