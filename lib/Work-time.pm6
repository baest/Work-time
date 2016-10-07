use v6;

class Work-time {
	has DateTime $.start is rw = DateTime.now;
	has DateTime $.end is rw = DateTime.now;
	has Bool $.had-lunch is rw = True;

	method next-day {
		$.start.truncated-to('day').later(day => 1);
	}

	method is-next-day (DateTime $dt) {
		return $dt.truncated-to('day') >= self.next-day;
	}

	multi method set (Str $what, DateTime $dt) returns Work-time:D {
		my Work-time $ret;
		given $what {
			when /:i start/ {
				$ret = self.clone-me if self.is-next-day($dt);

				$!start = $dt;
				$!end = $!start if $!start > $!end;
			}
			when /:i end/ {
				if $dt < $!start {
					say "Ignoring { $dt } since it's before { self.start }";
					return;
				}
				$!end = $dt;
			}
		}

		return $ret // self;
	}

	multi method set(DateTime $dt = DateTime.now()) returns Work-time:D {
		my Work-time $ret; 

		if self.is-next-day($dt) {
			$ret = self.clone-me;
			$!start = $dt;
			$!end = $dt;
		}
		elsif $dt > $!end {
			$!end = $dt;
		}

		return $ret // self;
	}

	method get-time (){
		return $!end.Instant - $!start.Instant - ($!had-lunch.Numeric * 30 * 60);
	}

	method get-time-pretty (){
		my $diff = self.get-time;
		return sprintf '%02d:%02d', $diff / 3600, ($diff % 3600) / 60;
	}

	multi method Str {
		return join("\n", (start => $!start.Str, end => $!end.Str, had-lunch => $!had-lunch.Numeric), (diff => self.get-time-pretty));
	}

	method clone-me returns Work-time:D {
		my $clone = self.clone;
		$!had-lunch = True;
		return $clone;
	}
}
