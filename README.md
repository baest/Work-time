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

curl http://localhost:10000/set/-1/0900-1800
curl http://localhost:10000/set/-1/no-lunch

curl http://localhost:10000/load --data-binary @data/timer.csv -H 'Content-type:text/plain; charset=utf-8' 

## TODO

# http://localhost:10000/end/-1/1710 is buggy if the date has changed (set the
time to 1710 on today, not yesterday)

# /-1/ can't create records, like
curl http://localhost:10000/set/-1/0900-1800

- how to set lunch on /set/\* 
    - FIXED?
	
- test all urls works

- provide stat automatically. Like current status every week/month
	- test

- provide stat get functionality
	- test
