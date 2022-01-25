#!/bin/bash
INTRA="bledda"

if [ "$(uname)" = "Darwin" ]
then
	echo "Error :"
	echo "This script not functional on macOS"
	exit
fi

echo -en "Loading intra information\r"

echo -en "Loading : Get token access ....\r"
REQ_RESULT=$(curl --silent -d "grant_type=client_credentials" -d "client_id=$UID_42" -d "client_secret=$SECRET" -X POST https://api.intra.42.fr/oauth/token)

if [ "$(echo $REQ_RESULT | jq .error)" != "null" ]
then
	echo -en "Error :              "
	echo $(echo $REQ_RESULT | jq .error_description | cut -d "\"" -f 2)
	exit
fi

TOKEN=$(echo $REQ_RESULT | jq .access_token | cut -d "\"" -f 2)

echo -en "Loading : Get value user ......\r"
REQ_RESULT=$(curl --silent -H "Authorization: Bearer $TOKEN" "https://api.intra.42.fr/v2/users/$INTRA")

echo -en "Loading : Traitement ..........\r"
LOCATION=$(echo $REQ_RESULT | jq .location)
PTS=$(echo $REQ_RESULT | jq .correction_point)
WALLET=$(echo $REQ_RESULT | jq .wallet)
LEVEL=$(echo $REQ_RESULT | jq .cursus_users[1].level)
BLACKHOLE=$(echo $REQ_RESULT | jq .cursus_users[1].blackholed_at | cut -d "\"" -f 2)

CURRENT_DATE=$(date --iso-8601=seconds)

declare -a CURRENT_PROJECT

diff_date () {
	echo $(( ($(date -d $1 +%s) - $(date -d $2 +%s)) / 86400 ))
}

i=0
j=0
while true
do
	PROJECT=$(echo $REQ_RESULT | jq .projects_users[$i])
	i=$i+1;
	if [ "$PROJECT" = "null" ]
	then
		break
	fi
	STATUS=$(echo $PROJECT | jq .status | cut -d "\"" -f 2)
	if [ "$STATUS" != "finished" ]
	then
		CURRENT_PROJECT[$j]=$PROJECT
		j=$j+1
	fi
done

echo -e "----------- USER INFORMATION -----------"

echo -e "LEVEL \t\t: $LEVEL"
echo -e "BLACKHOLE \t: $(diff_date $BLACKHOLE $CURRENT_DATE) days"
echo -e "WALLET \t\t: $WALLET"
echo -e "PTS \t\t: $PTS"
echo -e "LOCATION \t: $LOCATION"

echo -e "----------------------------------------\n"

echo "---------- CURRENT PROJECT -------------"
for i in ${!CURRENT_PROJECT[*]}
do
	PROJECT=${CURRENT_PROJECT[$i]}
	STATUS=$(echo $PROJECT | jq .status | cut -d "\"" -f 2)
	NAME=$(echo $PROJECT | jq .project.name | cut -d "\"" -f 2)
	REGISTER=$(echo $PROJECT | jq .created_at | cut -d "\"" -f 2)
	DIFF_DATE=$(diff_date $CURRENT_DATE $REGISTER)
	if [ "$STATUS" = "in_progress" ]
	then
		echo -e "NAME \t\t: $NAME"
		echo -e "REGISTER \t: $DIFF_DATE days"
		echo -e "----------------------------------------\n"
	fi
done
