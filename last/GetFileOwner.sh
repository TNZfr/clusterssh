#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls GetFileOwner [User@]Pattern UserID RemoteFile [TargetDirectory]"
    print ""
    print "User            : User to use (optional)"
    print "                  Default value is the first account defined in referential"
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "UserID          : UserID used on remote servers"
    print "RemoteFile      : Command to execute on each select node."
    print "TargetDirectory : Directory where files are copied (file.ShortNodeName)"
    print "                  (optional, default value is current directory)"       
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#
if [ $# -lt 3 ]
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

UserID=$2
RemoteFile=$3
TargetDirectory=$PWD
[ $# -gt 3 ] && TargetDirectory=$4

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
DataFifo=/tmp/cls.$HOSTNAME.$$

StatusFinal=0
Debut_GF=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    Debut_TF=$(TopHorloge)
    
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)
    UserNodeShort=$(echo $UserNode|cut -d. -f1)
    
    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $Node"
    print "\033[34;47m User            \033[m : $User -> $UserID"
    print "\033[34;47m Remote file     \033[m : $RemoteFile"
    print "\033[34;47m Local directory \033[m : $TargetDirectory"

    Complement=""
    [ $User != root ] && Complement="sudo"

    LocalFile=$TargetDirectory/$(basename $RemoteFile).$UserNodeShort

    # Copie de la liste des fichiers trouves
    # --------------------------------------
    if [ $UserID = $User ]
    then
	# Pas de sudo nécessaire on utilise le compte cible
	scp -q $UserNode:$RemoteFile $LocalFile
	Status=$?
	print "\033[34;47m Status and file \033[m : $Status, $LocalFile ($(AfficheDuree $Debut_TF $(TopHorloge)))"
	[ $Status -ne 0 ] && StatusFinal=$Status
	continue
    fi

    # Creation du FIFO de travail
    ssh -q $UserNode "mkfifo $DataFifo; chmod a+rw $DataFifo"
    
    # Ecriture du fichier dans le fifo
    (
	ssh -q $UserNode $Complement su - $UserID "cat $RemoteFile > $DataFifo"
    ) &

    # Lecture de la fifo pour copie locale
    ssh -q $UserNode cat $DataFifo > $LocalFile
    Status=$?

    # Suppression du FIFO de travail
    ssh -q $UserNode rm -f $DataFifo

    print "\033[34;47m Status and file \033[m : $Status, $LocalFile ($(AfficheDuree $Debut_TF $(TopHorloge)))"
    [ $Status -ne 0 ] && StatusFinal=$Status
done

echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_GF $(TopHorloge))"
print ""

exit $StatusFinal
