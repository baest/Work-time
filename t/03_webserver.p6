use v6;
use Test;
use lib 'lib';
use Persist;
use Cro::HTTP::Test;
use Server;

my $db = 'test.db';

$db.IO.unlink;

isa-ok(my $persist = Persist.new(:file($db)), 'Persist','Grab file');

ok $db.IO ~~ :e, 'DB file exists';

my $s = Server.new(:$persist);

#TODO test rest of
#curl http://localhost:10000/start/1035
#curl http://localhost:10000/end/1035
#curl http://localhost:10000/checkin
#curl http://localhost:10000/login
#curl http://localhost:10000/logout
#curl http://localhost:10000/no-lunch
#curl http://localhost:10000/load --data-binary @data/timer.csv -H 'Content-type:text/plain; charset=utf-8' 

test-service $s.routes(), {
	test get('/set/20180101/9-18'),
		content-type => 'text/plain',
		body-text => /'start'\s+'2018-01-01T09:00:00+02:00'\s+'end'\s+'2018-01-01T18:00:00+02:00'/;

	test get('/set/20180102/0901-1859'),
		content-type => 'text/plain',
		body-text => /'start'\s+'2018-01-02T09:01:00+02:00'\s+'end'\s+'2018-01-02T18:59:00+02:00'/;

	my $dt = DateTime.now;

	test get('/set/10-11'),
		content-type => 'text/plain',
		body-text => /'start'\s+$($dt.Date.Str)'T10:00:00+'\d+':00'\s+'end'\s+$($dt.Date.Str)'T11:00:00+'\d+':00'/;

	test get('/set/0615-1637'),
		content-type => 'text/plain',
		body-text => /'start'\s+$($dt.Date.Str)'T06:15:00+'\d+':00'\s+'end'\s+$($dt.Date.Str)'T16:37:00+'\d+':00'/;
}

is $persist.get-current-account, '5:20', 'Current flex is correct';

ok $db.IO.unlink, 'Remove file';

done-testing;
