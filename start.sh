#!/bin/bash
#
# Originial inspiration for this configuration:
# https://testdriven.io/blog/github-actions-docker/
#

GITHUB_ORG=$GITHUB_ORG
GITHUB_TOKEN=$GITHUB_TOKEN
RUNNER_NAME=${RUNNER_NAME:-"${GITHUB_ORG}-$(hostname)"}

# Unfortunately no 'token' in the JIT response.
# This leaves no easy way to clean up runners that never recieved
# a job. The JIT runner will get purged automatically but only 
# after a job dispatch/completion. If you stop the containers
# manually it will leave a runner configured on your org :(
# 
cleanup() {
	echo "Performing cleanup tasks..."
	#  echo "Removing runner..."
	#  ./config.sh remove --unattended --token ${RUNNER_TOKEN}

	# Clean up any lingering credentials
	rm -rf ~/.ssh

	# Clean up previous work
	rm -rf ~/actions-runner/_work && mkdir -p ~/actions-runner/_work/_tool
}

# Managing starting/waiting for Docker to start
start_docker(){
	# Attempt to start Docker
	sudo service docker start

	# Check running or attempt again after 5 seconds
	if $(sudo service docker status); then
	  return
	else
	  echo "Attempting to start Docker again..."
	  sleep 5
	  sudo service docker start
	fi

	# Exit if still not started
	sudo service docker status || exit
}

echo "Starting Docker..."
start_docker;

echo "Request JIT config from GitHub..."
api_response=$(curl -sX POST \
	-H "Accept: application/vnd.github+json" \
  	-H "Authorization: Bearer ${GITHUB_TOKEN}"\
  	-H "X-GitHub-Api-Version: 2022-11-28" \
  	https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/generate-jitconfig \
	-d "{\"name\":\"${RUNNER_NAME}\",\"runner_group_id\":1,\"labels\":[\"self-hosted\",\"x64\",\"linux\",\"ubuntu-latest\",\"no-gpu\"],\"work_folder\":\"_work\"}"
	)

encoded_jit_config=$(echo ${api_response} | jq .encoded_jit_config --raw-output)

cd /home/github/actions-runner

trap 'cleanup; exit 0' 0
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

#echo "DEBUG: ${api_response}"

./run.sh --jitconfig ${encoded_jit_config} & wait $!
