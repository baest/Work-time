# Work-time

curl http://localhost:10000/start/1035

curl http://localhost:10000/end/1035

curl http://localhost:10000/checkin

curl http://localhost:10000/login

curl http://localhost:10000/logout

curl http://localhost:10000/no-lunch

curl http://localhost:10000/load --data-binary @data/timer.csv -H 'Content-type:text/plain; charset=utf-8' 

## TODO

- auto find last entry and reuse if same day on start
	- test

- test that client work with mock server

- test that server works with mock client

- provide stat automatically. Like current status every week/month

- provide stat get functionality
