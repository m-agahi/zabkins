#!/bin/bash

inputfile=$1
server="192.168.145.173:8080"
username="monitor"
token="119cf029e9a6e0d1ed8445137a6f17d658"
url="http://$username:$token@$server"
jq='jq-linux64'

> /tmp/jenkins_api.json
> /tmp/jenkins_jobnames.txt
> /tmp/jenkins_job_api.json

function get_job_count {
	curl --silent --show-error $url/api/json > /tmp/jenkins_api.json
	./$jq '.jobs[].name' /tmp/jenkins_api.json | sed -e 's/^"\|"$//g' | wc -l
}

function get_job_names {
	curl --silent --show-error $url/api/json > /tmp/jenkins_api.json
	./$jq '.jobs[].name' /tmp/jenkins_api.json | sed -e 's/^"\|"$//g' > /tmp/jenkins_jobnames.txt
}

function get_job_index {
	search_string="$1"

}

function get_job_descriptions {
	while IFS= read -r line 
	do
		echo  -e "#!#" >> /tmp/jenkins_job_api.json
		line=`echo $line | sed 's| |\%20|g'`
		curl --silent --show-error $url/job/$line/api/json >> /tmp/jenkins_job_api.json
		echo  >> /tmp/jenkins_job_api.json
	done < /tmp/jenkins_jobnames.txt
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
		if [[ $line -eq $1 ]]
		then
			search_string=".healthReport[$1].score"
			echo $line | ./$jq $search_string
		fi
	done < /tmp/jenkins_job_api.json 	
}

function get_job_current_status {
	search_string=".jobs[$1].color"
	status=`./$jq $search_string /tmp/api1.json | sed -e 's/^"\|"$//g'`
	echo $status	

}

if [[ $1=="jobcount" ]]
then
	get_job_count
fi


#get_job_names
#get_job_descriptions
#get_job_success_rate 0
#get_job_current_status 0 
