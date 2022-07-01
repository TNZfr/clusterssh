#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PubKeyJournal User@Pattern [CSVOutputFile]"
    print ""
    print "  User@Pattern  : Cf Test Pattern"
    print "  CSVOutputFile : Results provided in CSV file"
    print ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    Aide
    exit 1
fi

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

CSPK_FINGER=$CS_CURRENT/PubKey.Finger && [ ! -f $CSPK_REVOKE ] && touch $CSPK_FINGER
CSFile=""
if [ $# -gt 1 ]
then
    CSVFile=$(readlink -f $2)
    echo "Date,Remote Server,Remote User,from,Calling User" > $CSVFile
fi

# Affichage des journaux de connexions
# ------------------------------------
TmpDir=/tmp/cls-pubkeyjournal-$$
mkdir $TmpDir
cd    $TmpDir
for CompteServeur in $CS_UserNodeList
do
    # 1. Recuperation journaux (auth.log ou secure)
    echo "Download authentification system log from $CompteServeur ..."
    JournalFound=$(ssh -q $CompteServeur "cd /var/log; ls -1 auth.log secure 2>/dev/null")
    if [ "$JournalFound" = "" ]
    then
	echo "No remote system log file found."
	continue
    fi

    > RemoteAuthent.log
    for Journal in $(ssh -q $CompteServeur "ls -1tr /var/log/${JournalFound}*")
    do
	if [ "${Journal%.gz}" = "$Journal" ]
	then
	    # Non compresse
	    ssh -q $CompteServeur "grep \"Accepted publickey\" $Journal"      >> RemoteAuthent.log
	else
	    # Compresse
	    ssh -q $CompteServeur "zcat $Journal|grep \"Accepted publickey\"" >> RemoteAuthent.log
	fi
    done

    # 2. Recherche des empreintes des cles publiques
    cat RemoteAuthent.log|while read Enreg
    do
	ConnDate=$(    echo $Enreg|cut -d' ' -f1-3)
	RemoteServer=$(echo $Enreg|cut -d' ' -f4  )
	RemoteUser=$(  echo $Enreg|cut -d' ' -f9  )
	SourceAddr=$(  echo $Enreg|cut -d' ' -f11 )
	FingerPrint=$( echo $Enreg|cut -d' ' -f16 )
	
	CallingUser=$(grep "$FingerPrint" $CSPK_FINGER|cut -d' ' -f3-|tr ['\n'] [','])

	if [ "$CSVFile" = "" ]
	then
	    echo $ConnDate $RemoteServer $RemoteUser account used from $SourceAddr by $CallingUser
	else
	    echo "$ConnDate,$RemoteServer,$RemoteUser,$SourceAddr,$CallingUser" >> $CSVFile
	fi
    done
done    

# Nettoyage
rm -rf $TmpDir

exit 0
