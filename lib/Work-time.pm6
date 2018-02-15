use v6;

class Work-time {
	has Int $.id is rw = 0;
	has DateTime $.start is rw = DateTime.now;
	has DateTime $.end is rw = DateTime.now;
	has Bool $.had-lunch is rw = True;

	method next-day {
		$.start.truncated-to('day').later(day => 1);
	}

	method is-next-day (DateTime $dt) {
		return $dt.truncated-to('day') >= self.next-day;
	}

	multi method set (Str $what, DateTime $dt) {
		given $what {
			when /:i start/ {
                if self.is-next-day($dt) {
                    self.reset();
                }
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
	}

	multi method set(DateTime $dt = DateTime.now()) {
		if self.is-next-day($dt) {
			self.reset();
			$!start = $dt;
			$!end = $dt;
		}
		elsif $dt > $!end {
			$!end = $dt;
		}
	}

	method get-time (){
		return $!end.Instant - $!start.Instant - ($!had-lunch.Numeric * 30 * 60);
	}

	method get-time-pretty (){
		my $diff = self.get-time;
		# modulus doesn't return negative so append - in case of negative time
		# also modulus does weird things when negative so use absolute values
		return ($diff < 0 ?? '-' !! '') ~ sprintf '%02d:%02d', $diff / 3600, ($diff.abs % 3600) / 60;
	}

	multi method Str () {
		return join("\n", (start => $!start.Str , end => $!end.Str, had-lunch => $!had-lunch.Numeric), (diff => self.get-time-pretty));
	}

	method clone-me returns Work-time:D {
		my $clone = self.clone;
		$clone.reset();
		return $clone;
	}

    method reset {
		$!had-lunch = True;
		$!id = 0;
    }
}
