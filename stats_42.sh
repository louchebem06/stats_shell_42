#!/bin/bash
INTRA="bledda"

echo -en "Loading intra information\r"

REQ_RESULT=$(curl --silent -d "grant_type=client_credentials" -d "client_id=$UID_42" -d "client_secret=$SECRET" -X POST https://api.intra.42.fr/oauth/token)

TOKEN=$(echo $REQ_RESULT | jq .access_token | cut -d "\"" -f 2)

REQ_RESULT=$(curl --silent -H "Authorization: Bearer $TOKEN" "https://api.intra.42.fr/v2/users/$INTRA")

LOCATION=$(echo $REQ_RESULT | jq .location)
PTS=$(echo $REQ_RESULT | jq .correction_point)
WALLET=$(echo $REQ_RESULT | jq .wallet)
LEVEL=$(echo $REQ_RESULT | jq .cursus_users[1].level)
BLACKHOLE=$(echo $REQ_RESULT | jq .cursus_users[1].blackholed_at | cut -d "\"" -f 2)

if [ "$(uname)" = "Darwin" ]
then
	CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ");
else
	CURRENT_DATE=$(date --iso-8601=seconds)
fi

declare -a CURRENT_PROJECT

diff_date () {
	if [ "$(uname)" = "Darwin" ]
	then
		echo "Fix Mac OS in progress"
	else
		echo $(( ($(date -d $1 +%s) - $(date -d $2 +%s)) / 86400 ))
	fi
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

echo -en "                                                            \r"

echo "----------- USER INFORMATION -----------"

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

