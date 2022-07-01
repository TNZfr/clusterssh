#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls GetFile [User@]Pattern RemoteFile [TargetDirectory]"
    print ""
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "User            : User to use (cf cls TestPattern command)"
    print "RemoteFile      : Command to execute on each select node."
    print "TargetDirectory : Directory where files are copied (file.ShortNodeName)"
    print "                  (optional, default value is current directory)"       
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#
if [ $# -lt 2 ]
then
    Aide
    exit 1
fi

print ""
print "Current referential : \033[1;33;44m $(GetCurrentReferentiel) \033[m"
print ""

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

RemoteFile=$2
if [ $# -gt 2 ]
then
    TargetDirectory=$3
else
    TargetDirectory=$CS_CurrentDir
fi

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
StatusFinal=0
Debut_GF=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)

    ehco "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $Node"
    print "\033[34;47m User            \033[m : $User"
    print "\033[34;47m Remote file     \033[m : $RemoteFile"

    # Liste des fichiers a copier
    # ---------------------------
    FileList=$(ssh $UserNode ls $RemoteFile 2>/dev/null)
    if [ "$(echo $FileList)" = "" ]
    then 
	print "\033[34;47m Result          \033[m : \033[1m File not found on remote server \033[m"
	StatusFinal=2
	continue
    fi

    # Copie de la liste des fichiers trouves
    # --------------------------------------
    ShortUserNode=$(echo $UserNode|cut -f1 -d.)
    print "\033[34;47m Local directory \033[m : $TargetDirectory"


    for File in $FileList
    do
	Debut_TF=$(TopHorloge)
	
	TargetFile=$(basename $File).$ShortUserNode
	scp -q $UserNode:$File $TargetDirectory/$TargetFile
	Status=$?
	print "\033[34;47m Status and name \033[m : $Status, $TargetFile ($(AfficheDuree $Debut_TF $(TopHorloge)))"
	[ $Status -ne 0 ] && StatusFinal=$Status
    done
done

echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_GF $(TopHorloge))"
print ""

exit $StatusFinal
