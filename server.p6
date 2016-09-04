use v6;

use lib 'lib';
use Work-time;

my $login = Work-time.new;

react {
	whenever IO::Socket::Async.listen('localhost', 3333) -> $conn {
		whenever $conn.Supply(:bin) -> $buf {
			my $str = $buf.decode('UTF-8');
			given $str {
				when /checkin|login|logout/ { 
					$login.set();
				}
				when /(\w+) \s+ (\d**2) ':'? (\d**2)/ {
					$login.set(~$0, DateTime.new(
						date => Date.today,
						hour => $1,
						minute => $2,
						timezone => $*TZ,
					));
				}
			}

			await $conn.print($login.Str.encode('UTF-8'));
		}
	}
}
