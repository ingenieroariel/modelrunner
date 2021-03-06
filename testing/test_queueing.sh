#!/bin/bash

# Test the following
#
# time  action         job1    | job2   | job 3   
# ------------------------------------------------
# t1   queue job1 ->   QUEUED  |        |
#  |   queue job2 ->   RUNNING |QUEUED  |QUEUED  
#  |   queue job3 ->   RUNNING |QUEUED  |QUEUED  
#  |   kill job2  ->   RUNNING |KILLED  |QUEUED  
#  |   kill job1  ->   KILLED  |KILLED  |RUNNING
# t6                                    |COMPLETE

# fail on any command failure
set -e

# get test server as param
if [ $# -lt 1 ]
then
  echo "Usage: ${0##*/} test_server_url"
  exit 1
fi 

# needs to be set so that api_functions work
MR_SERVER=$1
# temp dir to store all working data
MR_TMP_DIR=$(mktemp -d)
# get the source dir for testing so we can source the api_functions
MR_TEST_SRC_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $MR_TEST_SRC_DIR/api_functions.sh

trap mr_cleanup EXIT

echo "creating 1st job"
job_1_id=$(mr_create_job test_queue_kill_`date +%Y-%m-%d_%H:%M:%S` "test" "@testing/sleep_count_30.zip")
# wait for job 1 to start, kill it and wait for it to fail
mr_wait_for_status $job_1_id "RUNNING" 10

# Ensure that we can kill a queued job
echo "created job $job_1_id (RUNNING), now queue 2nd job"
job_2_id=$(mr_create_job test_queue_kill_`date +%Y-%m-%d_%H:%M:%S` "test" "@testing/sleep_count_8.zip")

echo "waiting for job $job_2_id to go QUEUED"
mr_wait_for_status $job_2_id "QUEUED" 2 

echo "job $job_1_id is still (RUNNING), $job_2_id is QUEUED, now queue 3rd job"
job_3_id=$(mr_create_job test_queue_`date +%Y-%m-%d_%H:%M:%S` "test" "@testing/sleep_count_8.zip")
echo "created job $job_2_id"

echo "attempting to kill job $job_2_id"
mr_kill_job $job_2_id

echo "waiting for job $job_2_id to go KILLED"
mr_wait_for_status $job_2_id "KILLED" 2

echo "killing job $job_1_id"
mr_kill_job $job_1_id
mr_wait_for_status $job_1_id "KILLED" 7

# now wait for job 3 to finish
echo "waiting for job $job_3_id to go COMPLETE"
mr_wait_for_status $job_3_id "COMPLETE" 10

# disable the trap now
trap - EXIT
mr_cleanup
echo "SUCCESS"
