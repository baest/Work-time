use v6;
use Test;
use lib 'lib';
use Persist;
use Cro::HTTP::Test;
use Server;

#my $db = 'test.db';
#
#$db.IO.unlink;
#
#isa-ok(my $persist = Persist.new(:file($db)), 'Persist','Grab file');
#
#ok $db.IO ~~ :e, 'DB file exists';

my $s = Server.new;

test-service $s.routes(), {
	test get('/set/20180101/9-18'),
		content-type => 'text/plain',
		body => /'start	2018-01-01T09:00:00+02:00'/;
}

done-testing;

