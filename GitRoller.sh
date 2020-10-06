#!/bin/bash
echo
echo ========================================
echo GitRoller v.1.0 "	" By:Mansoor R
echo ========================================
echo

#Defining paths:
#PATH_TRUFFLEHOG="/opt/github/truffleHog/truffleHog/truffleHog.py"

#Displaying help :
if [ $# -eq 0 ] || [ $1 == "-h" ] || [ $1 == "--help" ]
then
	echo Usage : supply organisation/user name
	echo Ex "  " : ./GitRoller hackerone
	exit
fi

export GHUSER=$1

if [ -d "$GHUSER"_git ]; then
	echo Please remove directory "$GHUSER"_git and then proceed further.
  	exit
  else	
 	mkdir "$GHUSER"_git
  	cd "$GHUSER"_git
fi

echo	Organisation: "	"$GHUSER
echo
echo

function fetchRepoList()
{
	echo "==> Gathering Repos from github ..."
	i=1
	while [ true ]
	do
		#Fetching Public repos of particular user:
		curl  "https://api.github.com/users/$GHUSER/repos?per_page=100&page=$i" -s | grep -w clone_url > temp_output.txt
		#Fetching Public repos of particular organisationg:
		#curl  "https://api.github.com/orgs/$GHUSER/repos?per_page=100&page=$i" -s | grep -w clone_url > temp_output.txt
		if [ ! -s temp_output.txt ];	#File is empty
		then
			break
		fi
		cat temp_output.txt | grep -o '[^"]\+://.\+.git' >> "$GHUSER"_repos.txt
		i=$[$i+1]
	done
	
	if [ -s "$GHUSER"_repos.txt ];then
		repo_no=$(cat "$GHUSER"_repos.txt | wc -l)

		echo "(+) $repo_no Public Repos found for $GHUSER and  are successfully saved into file: "$GHUSER"_repos.txt"
	else
		echo "(-) Public Repos for $GHUSER not found"
		exit
	fi
	
	[[ -f "temp_output.txt" ]] && rm temp_output.txt
}

function fireTruffleHog()
{
	echo "==> Scanning Repos with TuffleHog ..."
	for repo in $(cat "$GHUSER"_repos.txt);
	do
		echo
		echo ------------------------------------------------------------------------------------
		echo Repository: $repo
		echo ------------------------------------------------------------------------------------
		trufflehog --regex --entropy=False $repo | tee  temp_output2.txt
		#$PATH_TRUFFLEHOG --regex --entropy=False $repo | tee  temp_output2.txt
		if [ -s temp_output2.txt ];then
			echo ------------------------------------------------------------------------------------ >> "$GHUSER"_trufflehog.txt
			echo Repository: $repo >> "$GHUSER"_trufflehog.txt
			echo ------------------------------------------------------------------------------------ >> "$GHUSER"_trufflehog.txt
			cat temp_output2.txt >> "$GHUSER"_trufflehog.txt
			rm temp_output2.txt		
		fi
	done
	echo
	if [ -s "$GHUSER"_trufflehog.txt ];then
		echo "(+) Secrets for $GHUSER are successfully saved into file: "$GHUSER"_trufflehog.txt"
	else
		echo "(-) No secrets are found for $GHUSER"
	fi
	[[ -f "temp_output2.txt" ]] && rm temp_output2.txt
}

#Fetching repo list of org:
fetchRepoList
echo

#Firing trufflehog on org's reposo:
fireTruffleHog


#Bell
echo -e "\a"
[[ $(command -v notify-send) ]] && notify-send "GitRoller: Scanning Completed for $GHUSER " 
echo THANKS FOR USING GitRoller !!
