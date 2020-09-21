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
jenkins_return_file="/etc/zabbix/tmp/jenkins_return.txt"
jenkins_job_items="success.rate"
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
#		get_job_descriptions `echo $line | sed 's/ /\%20/g'`
		for item in $jenkins_job_items
		do
#			item=`echo $item | sed 's/_/ /g'`
			data=`echo $line.$item`
		done
		echo -ne '\n { "{#JOBNAME}": "'$data'" },' >> $jenkins_return_file
	done < $jenkins_jobnames_file
	echo -e ']}' >> $jenkins_return_file
	sed -i -e 's|\,\]\}|\n\]\}|' $jenkins_return_file
}

function get_job_descriptions {
	> $jenkins_job_api_file
	curl --silent --show-error $url/job/$1/api/json > $jenkins_job_api_file
	echo  >> $jenkins_job_api_file
	get_job_success_rate
}

function get_job_success_rate {
	while IFS= read -r line_1
	do
		search_string=".healthReport[].score"
		success_rate=`echo $line_1 | $jq $search_string`
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


#agenthost="`hostname -f`"
#zserver="myzabbix"
#zport="10051"

#cat /dev/null > /tmp/zdata.txt
#for item in "carrot" "banana" "lettuce" "tomato"; do
# randNum="$(( (RANDOM % 30)+1 ))"
# echo $agenthost instock[$item] $randNum >> /tmp/zdata.txt
#done

# push all these trapper values back to zabbix
#zabbix_sender -vv -z $zserver -p $zport -i /tmp/zdata.txt >> /tmp/zsender.log 2>&1

