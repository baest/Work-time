# Work-time

curl http://localhost:10000/start/1035

curl http://localhost:10000/end/1035

curl http://localhost:10000/checkin

curl http://localhost:10000/login

curl http://localhost:10000/logout

curl http://localhost:10000/no-lunch

curl http://localhost:10000/set/0900-1800
curl http://localhost:10000/set/9-18
curl http://localhost:10000/set/20180101/9-18

curl http://localhost:10000/load --data-binary @data/timer.csv -H 'Content-type:text/plain; charset=utf-8' 

## TODO

V? full set support so an earlier saved day can be updated
	# TODO how lunch
	# TODO test this feature
	

- test that client work with mock server

- test that server works with mock client

- provide stat automatically. Like current status every week/month

- provide stat get functionality
