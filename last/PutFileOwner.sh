#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PutFileOwner [User@]Pattern[:TargetDirectory] UserID LocalFile"
    print ""
    print "User            : User to use (optional)"
    print "                  Default value is the first account defined in referential"
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "TargetDirectory : Directory where files are copied (optional)"
    print "                  Default value is remote home directory"
    print "UserID          : UserID used on remote servers"
    print "LocalFile       : File(s) to sent on remote node(s)"
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
FileList=$(echo $*|cut -f3- -d' ')

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
StatusFinal=0
Debut_PF=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)

    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $Node"
    print "\033[34;47m User            \033[m : $User -> $UserID"
    print "\033[34;47m Remote directory\033[m : $CS_TargetDir"

    [ $User != root ] && Sudo="sudo" || Sudo=""

    if [ $UserID = $User ]
    then
	for File in $FileList
	do
	    Debut_TF=$(TopHorloge)

	    # Pas de sudo nécessaire on utilise le compte cible
	    scp -q $File $UserNode:$CS_TargetDir
	    Status=$?
	    print "\033[34;47m Status and file \033[m : $Status, $File ($(AfficheDuree $Debut_TF $(TopHorloge)))"
	    [ $Status -ne 0 ] && StatusFinal=$Status
	done
    else
	# Creation du FIFO de travail
	DataFifo=/tmp/cls.$HOSTNAME.$$
	ssh -q $UserNode "mkfifo $DataFifo; chmod 644 $DataFifo"
	
	# Copie de la liste des fichiers trouves
	for File in $FileList
	do
	    Debut_TF=$(TopHorloge)

	    # Envoi du contenu
	    cat $File | ssh -q $UserNode "cat - > $DataFifo" &

	    # Ecriture du contenu dans le fichier cible
	    ssh -q $UserNode $Sudo su - $UserID "cat $DataFifo > $CS_TargetDir/$(basename $File)"
	    Status=$?

	    print "\033[34;47m Status and file \033[m : $Status, $File ($(AfficheDuree $Debut_TF $(TopHorloge)))"
	    [ $Status -ne 0 ] && StatusFinal=$Status
	done

	# Suppression du FIFO de travail
	ssh -q $UserNode rm -f $DataFifo
    fi
done

echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_PF $(TopHorloge))"
print ""

exit $StatusFinal
