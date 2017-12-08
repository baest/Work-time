use v6;

use Work-time;
use Persist;

use Cro::HTTP::Router;
use Cro::HTTP::Server;

my regex time-match { $<hour> = \d**1..2 ':'? $<minute> = \d**2 }
my subset time of Str where /^ <time-match>  $/;

class Server {
	has Work-time $.login is rw;
	has Work-time $.ret-login is rw;
	has Persist $.persist is rw = Persist.new();
	has Bool $.verbose;

	method start {
		$!login = $!persist.get-current // Work-time.new;

		my $application = route {
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
				$!login.had-lunch = False;
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
			post -> 'load' {
				request-body-text -> $file {
					$!persist.load-data($file);
				}
			}
		}

		say 'Ready';
		$!persist.save($!login);
		my Cro::Service $service = Cro::HTTP::Server.new: :host<localhost>, :port<10000>, :$application;
		$service.start;
		react whenever signal(SIGINT) { $service.stop; exit; }
	}

	method output (Str $what) {
		say $what if $!verbose;
		content 'text/plain', $what;
	}

	method handle_update {
		$!persist.save($!login);
		say ~$!login;
		say ~$!ret-login;
	}

	method set-to-now {
		$!ret-login = $!login.set();
		self.output(~$!login);
	}

	method set-to-time (Str $what, time $time) {
		$time ~~ / <time-match> /;
		$!ret-login = $!login.set($what, DateTime.new(
			date => Date.today,
			hour => $<time-match><hour>,
			minute => $<time-match><minute>,
			timezone => $*TZ,
		));
		self.output(~$!login);
	}
}
