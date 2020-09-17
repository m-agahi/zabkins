#!/usr/bin/env python3
#

from jenkinsapi.jenkins import Jenkins

### initalizing variables
jenkins_url = 'http://192.168.145.173:8080'
username = 'monitor'
password = '118d2b0d6a8812d00ba8e9b589b2fbbced'
###

def get_server_instance():
    server = Jenkins(jenkins_url, username, password)
    return server



"""Get job details of each job that is running on the Jenkins instance"""
def get_job_details():
    # Refer Example #1 for definition of function 'get_server_instance'
    server = get_server_instance()
    for job_name, job_instance in server.get_jobs():
#        print('Job Name:%s' % (job_instance.name))
#        print('Job Description:%s' % (job_instance.get_description()))
#        print('Is Job running:%s' % (job_instance.is_running()))
#        print('Is Job enabled:%s' % (job_instance.is_enabled()))
        print("salam")

if __name__ == '__main__':
#    print get_server_instance().version
    print(get_server_instance().version)
get_job_details()
