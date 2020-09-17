#!/bin/bash

inputfile=$1
server="192.168.145.173:8080"
username="monitor"
token="119cf029e9a6e0d1ed8445137a6f17d658"
curl --silent --show-error http://$username:$token@$server/api/json > /tmp/api1.json
./jq-linux64 '.jobs[].name' /tmp/api1.json | sed -e 's/^"\|"$//g' > /tmp/jobnames.txt
> /tmp/api2.json
while IFS= read -r line 
do
	echo  -e "#!#" >> /tmp/api2.json
	line=`echo $line | sed 's| |\%20|g'`
	curl --silent --show-error http://$username:$token@$server/job/$line/api/json >> /tmp/api2.json
	echo  >> /tmp/api2.json
	 
#curl --silent --show-error http://monitor:119cf029e9a6e0d1ed8445137a6f17d658@192.168.145.173:8080/api/json 

done < /tmp/jobnames.txt

while IFS= read -r line
do
	if echo $line | grep -qe "^#.*" 
	then
		continue
	elif echo $line | grep -qe "^$"
	then
		continue
	fi
	echo $line | ./jq-linux64 '.healthReport[].score' 
done < /tmp/api2.json 	
