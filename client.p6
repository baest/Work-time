use v6;
#= Client

#| Do a checkin on MAIN
multi sub MAIN() {
	connect-send;
}

#| Call on login
multi sub MAIN(Bool :$login) {
	put-time(:what('login'));
}

#| Call on logout
multi sub MAIN(Bool :$logout) {
	put-time(:what('logout'));
}

#| Set the start time of today
multi sub MAIN(Str :$start) {
	put-time(:what('start'), :time($start));
}

#| Sets no lunch for today
multi sub MAIN(Bool :$no-lunch) {
	connect-send('no-lunch');
}

#| Set the end time of today
multi sub MAIN(Str :$end) {
	put-time(:what('end'), :time($end));
}

#| Load data from file
multi sub MAIN(Str :$load-file) {
	connect-send("load-file: $load-file");
}

sub put-time (Str :$time, Str :$what) {
	if $time && $time ~~ /(\d\d?) ':'? (\d**2)/ {
		my $time = "$0:$1";
		connect-send("$what $time");
		exit 0;
	}
	elsif !$time {
		my $time = DateTime.now.truncated-to('minute');
		connect-send("$what {Int($time.Instant)}");
	}
	else {
		say qq!Don't recognize time: '$time'!;
	}
	exit 1;
}

sub connect-send (Str $data = 'checkin') {
	await IO::Socket::Async.connect('localhost', 3333).then( -> $conn {
		if $conn.status {
			given $conn.result {
				.print($data);
				react {
					whenever .Supply() -> $v {
						print $v;
						done;
					}
				}
				.close;
			}
		}
	});
}
