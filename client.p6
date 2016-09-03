use v6;

sub MAIN(Str :$start, Str :$end) {
	for $start, $end {
		if $_ && /\d**4/ {
			connect-send(($start ?? 'start' !! 'end') ~ ' ' ~ $_);
			exit 0;
		}
	}
	connect-send;

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
