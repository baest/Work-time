use v6;

use lib 'lib';
use Work-time;
use Persist;

my $login = Work-time.new;
my $persist = Persist.new();

react {
	say 'Ready';
	whenever IO::Socket::Async.listen('localhost', 3333) -> $conn {
		whenever $conn.Supply(:bin) -> $buf {
			my $str = $buf.decode('UTF-8');
			my $ret_login;
			given $str {
				when /[checkin|login|logout] \s+ (\d+)/ {
					my $time = DateTime.new(+$0, :timezone($*TZ));
					$ret_login = $login.set($time);
				}
				when m!'load-file:' \s+ (<[\w/\.]>.+)! {
					$persist.clear-data;
					$persist.load-data(~$0);
				}
				when /(\w+) \s+ (\d**1..2) ':'? (\d**2)/ {
					$ret_login = $login.set(~$0, DateTime.new(
						date => Date.today,
						hour => $1,
						minute => $2,
						timezone => $*TZ,
					));
				}
			}
			unless $ret_login === $login {
				$persist.save($l);
			}

			await $conn.print($login.Str.encode('UTF-8'));
		}
	}
}
