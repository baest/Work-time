use v6;

use lib 'lib';
use Work-time;
use Persist;

my $login = Work-time.new;
my $persist = Persist.new();
my Bool $v;

multi sub MAIN() { run-server(); }
multi sub MAIN(Bool :$verbose) {
	run-server(:$verbose);
}

sub run-server (Bool :$verbose = False) {
	$v = $verbose;
	react {
		say 'Ready';
		whenever IO::Socket::Async.listen('localhost', 3333) -> $conn {
			whenever $conn.Supply(:bin) -> $buf {
				my $str = $buf.decode('UTF-8');
				my $ret-login;
				given $str {
					when /[checkin|login|logout] \s+ (\d+)/ {
						my $time = DateTime.new(+$0, :timezone($*TZ));
						$ret-login = $login.set($time);
					}
					when /"no-lunch"/ {
						$login.had-lunch = False;
					}
					when m!'load-file:' \s+ (<[\w/\.]>.+)! {
						$persist.clear-data;
						my $inserted = $persist.load-data(~$0);
						my $current = $persist.get-current-account();
						output $conn, "Inserted $inserted records. Current account is $current";
						next;
					}
					when /(\w+) \s+ (\d**1..2) ':'? (\d**2)/ {
						$ret-login = $login.set(~$0, DateTime.new(
							date => Date.today,
							hour => $1,
							minute => $2,
							timezone => $*TZ,
						));
					}
				}
				if !$ret-login || $ret-login === $login {
					say "Not saving: ";
					say ~$login;
				}
				else {
					$persist.save($ret-login);
					say "Saving: ";
					say ~$ret-login;
				}

				await $conn.print(($login ~ "\n").encode('UTF-8'));
			}
		}
	}
}

sub output ($conn, Str $what) {
	say $what if $v;
	await $conn.print(($what ~ "\n").encode('UTF-8'));
}
