#!/bin/bash

### initial variables
agenthost="`hostname -f`"
zserver="192.168.145.209"
zport="10051"

server="192.168.145.173:8080"
username="monitor"
token="119cf029e9a6e0d1ed8445137a6f17d658"
url="http://$username:$token@$server"
jq='/etc/zabbix/scripts/jq-linux64'
jenkins_api_file="/etc/zabbix/tmp/jenkins_api.json"
jenkins_jobnames_file="/etc/zabbix/tmp/jenkins_jobnames.txt"
jenkins_job_api_file="/etc/zabbix/tmp/jenkins_job_api.json"
jenkins_return_file="/etc/zabbix/tmp/jenkins_return.txt"
jenkins_job_items="SuccessRate CurrentStatus"
### removed metrics:
#jenkins_job_items="LastBuild LastCompletedBuild LastFailedBuild" 
jenkins_stats_file="/etc/zabbix/tmp/jenkins_stats.txt"
zabbix_sender_log_file="/etc/zabbix/tmp/zsender.log"
> $jenkins_api_file
> $jenkins_jobnames_file
> $jenkins_job_api_file
> $jenkins_stats_file

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
	while IFS= read -r job_name
	do
		key_job_name=`echo $job_name | sed 's/ /_/g'`
		for job_item in $jenkins_job_items
		do
			#get json file for each job name 
			get_job_descriptions `echo $job_name | sed 's/ /\%20/g'`

			#get job status for each job name and each job item
			get_job_item_stat $job_item

			if [[ $job_item_stat = "" ]]
			then 
				job_item_stat='-1'
			fi
			# create a key based on job name and job item
			key_job_item=`echo $job_item | sed 's/ /_/g'`
			
			key=`echo $key_job_name"_"$key_job_item`

			#stores the stat for each key
			echo $agenthost jenkins.job[$key] $job_item_stat >> $jenkins_stats_file
			echo -ne '\n { "{#JOBNAME}": "'$key'" },' >> $jenkins_return_file
		done
	done < $jenkins_jobnames_file
	echo -e ']}' >> $jenkins_return_file
	sed -i -e 's|\,\]\}|\n\]\}|' $jenkins_return_file
}

function get_job_descriptions {
	> $jenkins_job_api_file
	curl --silent --show-error $url/job/$1/api/json > $jenkins_job_api_file
	echo  >> $jenkins_job_api_file
}

function job_item_stat_parser {
	### some text conversion
	job_item_stat=`echo $job_item_stat | sed -e 's/^"\|"$//g'`
	case $job_item_stat in
		red)
			job_item_stat=1;;
		blue)
			job_item_stat=10;;
		blue_anime)
			job_item_stat=5;;
		notbuilt)
			job_item_stat=-1;;
		aborted)
			job_item_stat=0;;
		aborted_anime)
			job_item_stat=5;;
	esac
}

# get status of each item and job passed to it
function get_job_item_stat {
	case $1 in
		'SuccessRate')
			search_string=".healthReport[].score";;
		'LastBuild')
			search_string=".lastBuild.number";;
		'LastCompletedBuild')
			search_string=".lastCompletedBuild.number";;
		'CurrentStatus')
			search_string=".color";;
		'LastFailedBuild')
			search_string=".lastFailedBuild.number";;
	esac
	while IFS= read -r job_api_json
	do
		job_item_stat=`echo $job_api_json | $jq $search_string`
		job_item_stat_parser
	done < $jenkins_job_api_file 	
}



function send_jobs_stats {
	zabbix_sender -vv -z $zserver -p $zport -i $jenkins_stats_file >> $zabbix_sender_log_file 2>&1
}

function return_failure_cause {
	keyf='failurecause'
	jenkins_failure_cuase='{ "data": [\n { "{#JOBF}": "'$keyf'" }]}' 
	echo $jenkins_failure_cuase
	jfc=`echo $agenthost jenkins.job[$keyf] 'reson for failure!!!'`
	zabbix_sender -vv -z $zserver -p $zport -i $jfc >> $zabbix_sender_log_file 2>&1

}

if  [[ $1 = 'jobcount' ]] 
then
	get_job_count
elif [[ $1 = 'jobnames' ]] 
then
	#get current job names and create keys based on them and send them to zabbix agent
	get_job_names
	return_job_names
	cat $jenkins_return_file
	
	#send status of each jobs based on the job items using zabbix send
	send_jobs_stats
elif [[ $1 = 'failurecause' ]]
then
	get_job_names
	return_failure_cause

fi




#function get_job_current_status {
#	job_current_status=`cat $jenkins_api_file | \
#		sed 's|{|\n{|g' | \
#		grep $1 | \
#		grep color | \
#		cut -d ":" -f 7 | \
#		cut -d '"' -f 2`
#