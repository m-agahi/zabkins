#!/bin/bash

inputfile=$1
server="192.168.145.173:8080"
username="monitor"
token="119cf029e9a6e0d1ed8445137a6f17d658"
url="http://$username:$token@$server"
> /tmp/api2.json


function get_job_names {
	curl --silent --show-error $url/api/json > /tmp/api1.json
	./jq-linux64 '.jobs[].name' /tmp/api1.json | sed -e 's/^"\|"$//g' > /tmp/jobnames.txt
}


function get_job_descriptions {
	while IFS= read -r line 
	do
		echo  -e "#!#" >> /tmp/api2.json
		line=`echo $line | sed 's| |\%20|g'`
		curl --silent --show-error $url/job/$line/api/json >> /tmp/api2.json
		echo  >> /tmp/api2.json
	done < /tmp/jobnames.txt
}

function get_job_success_rate {
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
}

get_job_names
get_job_descriptions
get_job_success_rate