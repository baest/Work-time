use v6;

class Work-time {
	has DateTime $.start = DateTime.now;
	has DateTime $.end = DateTime.now;

	method next-day {
		$.start.truncated-to('day').later(day => 1);
	}

	method is-next-day (DateTime $dt) {
		return $dt.truncated-to('day') >= self.next-day;
	}

	method set(DateTime $dt = DateTime.now()) {
		if self.is-next-day($dt) {
			$!start = $dt;
		}
		elsif $dt > $!end {
			$!end = $dt;
		}

		say ~self;
	}

	multi method Str {
		return join("\n", (start => $!start.Str, end => $!end.Str));
	}
}

my $login = Work-time.new;
sleep 1;
$login.set();

react {
	whenever IO::Socket::Async.listen('localhost', 3333) -> $conn {
		whenever $conn.Supply(:bin) -> $buf {
			await $conn.write: $buf;
			my $str = $buf.decode('UTF-8');
			given $str {
				when /checkin/ { 
					$login.set();
				}
			}
			say $str;
		}
	}
}
