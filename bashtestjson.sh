#!/bin/bash

inputfile=$1
server="192.168.145.173:8080"
username="monitor"
token="119cf029e9a6e0d1ed8445137a6f17d658"
url="http://$username:$token@$server"
jq='jq-linux64'
> /tmp/jenkins/api/json
> /tmp/jenkins/jobnames.txt
> /tmp/api1.json

function get_job_names {
	curl --silent --show-error $url/api/json > /tmp/jenkins/api/json
	./$jq '.jobs[].name' /tmp/jenkins/api/json | sed -e 's/^"\|"$//g' > /tmp/jenkins/jobnames.txt
}

function get_job_index {
	search_string="$1"

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
		echo $line
		echo $1
		if $line -eq $1
		then
			search_string=".healthReport[$1].score"
			echo $line | ./$jq $search_string
		fi
	done < /tmp/api2.json 	
}

function get_job_current_status {
	search_string=".jobs[$1].color"
	status=`./$jq $search_string /tmp/api1.json | sed -e 's/^"\|"$//g'`
	echo $status	

}


get_job_names
get_job_descriptions
get_job_success_rate 0
get_job_current_status 0 
