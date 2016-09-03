use v6;

sub MAIN(Str :$time) {
	if $time && $time ~~ /\d**4/ {
		connect-send($time);
	}
	else {
		connect-send;
	}

	exit 1;
}

sub connect-send (Str $data = 'checkin') {
	await IO::Socket::Async.connect('localhost', 3333).then( -> $conn {
		if $conn.status {
			given $conn.result {
				.print($data);
#				react {
#					whenever .Supply() -> $v {
#						done;
#					}
#				}
				.close;
			}
		}
	});
}
