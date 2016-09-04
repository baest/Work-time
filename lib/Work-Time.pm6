use v6;

class Work-time {
	has DateTime $.start is rw = DateTime.now;
	has DateTime $.end is rw = DateTime.now;

	method next-day {
		$.start.truncated-to('day').later(day => 1);
	}

	method is-next-day (DateTime $dt) {
		return $dt.truncated-to('day') >= self.next-day;
	}

	multi method set (Str $what, DateTime $dt) {
		given $what {
			when /:i start/ {
				$!start = $dt;
			}
			when /:i end/ {
				if $dt < $!start {
					say "Ignoring { $dt } since it's before { self.start }";
					return;
				}
				$!end = $dt;
			}
		}

		return self;
	}

	multi method set(DateTime $dt = DateTime.now()) {
		if self.is-next-day($dt) {
			$!start = $dt;
			$!end = $dt;
		}
		elsif $dt > $!end {
			$!end = $dt;
		}

		return self;
	}

	method get-time (){
		return $!end.Instant - $!start.Instant;
	}

	method get-time-pretty (){
		my $diff = self.get-time;
		return sprintf '%02d:%02d', $diff / 3600, ($diff % 3600) / 60;
	}

	multi method Str {
		return join("\n", (start => $!start.Str, end => $!end.Str), (diff => self.get-time-pretty));
	}
}
