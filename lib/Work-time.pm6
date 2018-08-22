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
        warn $dt.truncated-to('day');
        warn self.next-day;
		return $dt.truncated-to('day') >= self.next-day;
	}

	multi method set (Str $what, DateTime $dt) {
        warn $dt;
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
					say "Ignoring { $dt } since it's before start { ~self }";
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

    multi method set(:$from-hour, :$from-min, :$to-hour, :$to-min) {
        my $dt = DateTime.new(date => $!start.Date, hour => $from-hour, minute => $from-min, timezone => $!end.timezone);
        $!start = $dt;

        $dt = DateTime.new(date => $!end.Date, hour => $to-hour, minute => $to-min, timezone => $!end.timezone);
        $!end = $dt;
    }

	method get-time (){
		return $!end.Instant - $!start.Instant - ($!had-lunch.Numeric * 30 * 60);
	}

	method get-time-pretty (){
		my $diff = self.get-time;
		# modulus doesn't return negative so append - in case of negative time
		# also modulus does weird things when negative so use absolute values
		my @polymod = $diff.abs.polymod: 60, 60;
		return ($diff < 0 ?? '-' !! '') ~ sprintf('%02d:%02d', @polymod[2,1]);
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
