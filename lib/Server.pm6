use v6;

use Work-time;
use Persist;

use Cro::HTTP::Router;
use Cro::HTTP::Server;

my regex time-match { $<hour> = \d**1..2 ':'? $<minute> = \d**2 }
my subset time of Str where /^ <time-match>  $/;
my regex date-match { [ $<month> = \d**2 $<day> = \d**2 |  $<year> = [ \d**2 | \d**4 ] $<month> = \d**2 $<day> = \d**2 ] }
my regex from-to-time-match { ^ $<from-hour> = \d**1..2 [ $<from-min> = \d**1..2 ]? '-' $<to-hour> = \d**1..2 [ $<to-min> = \d**1..2 ]? $ }

my subset set-date of Str where /^ $<mydate> = [ \d**4  | \d**6 | \d**8 ] $/;
my subset set-time of Str where / <from-to-time-match> /;

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
			post -> 'load' {
				request-body-text -> $file {
					$!persist.load-data($file);
				}
			}
		}
	}

	method output (Str $what) {
		say $what if $!verbose;
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

	method set ($dt, $set-detail) {
		#TODO handle lunch, how?
		my $wt = $!persist.get(:$dt) // Work-time.new;
		$set-detail ~~ / <from-to-time-match> /;

		$wt.set('start', $dt.later(hours => $<from-to-time-match><from-hour>).later(minutes => $<from-to-time-match><from-min> // 0));
		$wt.set('end', $dt.later(hours => $<from-to-time-match><to-hour>).later(minutes => $<from-to-time-match><to-min> // 0));
		$!persist.save($wt);
		say ~$wt;
		self.output(~$wt);
	}
}
