#!/bin/bash

### initial variables
server="192.168.145.173:8080"
username="monitor"
token="119cf029e9a6e0d1ed8445137a6f17d658"
url="http://$username:$token@$server"
jq='/etc/zabbix/scripts/jq-linux64'
jenkins_api_file="/etc/zabbix/tmp/jenkins_api.json"
jenkins_jobnames_file="/etc/zabbix/tmp/jenkins_jobnames.txt"
jenkins_job_api_file="/etc/zabbix/tmp/jenkins_job_api.json"
jenkins_return_file="/etc/zabbix/tmp/jenkins_return_file.txt"

> $jenkins_api_file
> $jenkins_jobnames_file
> $jenkins_job_api_file



function get_job_count {
	curl --silent --show-error $url/api/json > $jenkins_api_file
	job_count=`$jq '.jobs[].name' $jenkins_api_file | sed -e 's/^"\|"$//g' | wc -l`
	echo $job_count
}


function get_job_names {
	curl --silent --show-error $url/api/json > $jenkins_api_file
	$jq '.jobs[].name' $jenkins_api_file | sed -e 's/^"\|"$//g' > $jenkins_jobnames_file
}

function return_job_names {
	> $jenkins_return_file
	echo  -n '{ "data": [' > $jenkins_return_file
	while IFS= read -r line
	do
		echo -ne '\n { "{#JOBNAME}": "'$line'" },' >> $jenkins_return_file
		
	done < $jenkins_jobnames_file
	echo -e ']}' >> $jenkins_return_file
	sed -i -e 's|\,\]\}|\n\]\}|' $jenkins_return_file
	cat $jenkins_return_file
}


function get_job_index {
	search_string="$1"
}


function get_job_descriptions {
	while IFS= read -r line 
	do
		echo  -e "#!#" >> $jenkins_job_api_file
		line=`echo $line | sed 's| |\%20|g'`
		curl --silent --show-error $url/job/$line/api/json >> $jenkins_job_api_file
		echo  >> $jenkins_job_api_file
	done < $jenkins_jobnames_file
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
	done < $jenkins_job_api_file 	
}

function get_job_current_status {
	search_string=".jobs[$1].color"
	status=`./$jq $search_string $jenkins_api_file | sed -e 's/^"\|"$//g'`
	echo $status	

}

if  [ $1 = 'jobcount' ] 
then
	get_job_count
elif [ $1 = 'jobnames' ] 
then
	get_job_names
	return_job_names
fi