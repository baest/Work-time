use v6;
#= Client

#| Do a checkin on MAIN
multi sub MAIN() {
	connect-send;
}

#| Call on login
multi sub MAIN(Bool :$login) {
	connect-send('login');
}

#| Call on logout
multi sub MAIN(Bool :$logout) {
	connect-send('logout');
}

#| Set the start time of today
multi sub MAIN(Str :$start) {
	put-time($start, 'start');
}

#| Set the end time of today
multi sub MAIN(Str :$end) {
	put-time($end, 'end');
}

sub put-time (Str $time, Str $what) {
	if $time && $time ~~ /(\d\d?) ':'? (\d**2)/ {
        my $time = "$0:$1";
		connect-send("$what $time");
		exit 0;
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
						say $v;
						done;
					}
				}
				.close;
			}
		}
	});
}
