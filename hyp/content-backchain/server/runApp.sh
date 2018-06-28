function installNodeModules() {
	echo
	if [[ ! -d node_modules ]]; then
		echo "============== Installing node modules ============="
		npm install
	fi
	echo
}

function registerUsers(){
	echo "============== Enrolling Users ============="
	sleep 5
	ORG1_TOKEN=$(curl -s -X POST \
  		http://localhost:4000/users \
	  	-H "content-type: application/x-www-form-urlencoded" \
  		-d 'username=OrchestratorUser&orgName=OrchestratorOrg')
	ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
	
	ORG2_TOKEN=$(curl -s -X POST \
  		http://localhost:4000/users \
	  	-H "content-type: application/x-www-form-urlencoded" \
  		-d 'username=ParticipantUser&orgName=ParticipantOrg')
	ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")


	displayInfo
}

function startServer(){
	PORT=4000 node app &> server.log
}

function displayInfo(){
	echo
	echo "OrchestratorOrg User token - $ORG1_TOKEN"
	echo
	echo "ParticipantOrg User token - $ORG2_TOKEN"
	echo
	echo "Url - http://localhost:4000"
}

installNodeModules

startServer & registerUsers 








