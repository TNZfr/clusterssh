#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls Duplicate [User@]Pattern[:TargetDirectory] LocalDirectory ..."
    print ""
    print "User            : User to use (optional)"
    print "                  Default value is the first account defined in referential"
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "TargetDirectory : Directory where files are copied (optional)"
    print "                  Default value is remote home directory"
    print "LocalDirectory  : Directory(ies) to be duplicated on remote node(s)"
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

LocalDirectories=$2
if [ ! -d $LocalDirectories ]
then
    print "Directory $LocalDirectories not found."
    exit 1
fi

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
StatusFinal=0
Debut_CMD=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $(echo $UserNode|cut -f2 -d@)"
    print "\033[34;47m User            \033[m : $(echo $UserNode|cut -f1 -d@)"
    print "\033[34;47m Remote directory\033[m : $CS_TargetDir"

    # Duplication des repertoires
    # ---------------------------
    for LocalDirectory in $LocalDirectories
    do
	Debut_UN=$(TopHorloge)
	
	cd $CS_CurrentDir
	cd $LocalDirectory/..
	
	print "\033[34;47m Duplicating     \033[m : $LocalDirectory"

	if [ $(GetRemoteChar gunzip $UserNode) != NotAvailable ] && [ $(GetLocalChar gzip) != NotAvailable ]
	then
	    print "\033[34;47m Compression     \033[m : Local - Remote"
	    tar cf - $(basename $LocalDirectory)|gzip -9c|ssh -q $UserNode "gunzip - -c|tar xf - -C $CS_TargetDir"
	else
	    print "\033[34;47m Compression     \033[m : none - none"
	    tar cf - $(basename $LocalDirectory)         |ssh -q $UserNode "            tar xf - -C $CS_TargetDir"
	fi
	Status=$?
	print "\033[34;47m Status          \033[m : $Status ($(AfficheDuree $Debut_UN $(TopHorloge)))"
	[ $Status -ne 0 ] && StatusFinal=$Status
    done
done

ehco  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_CMD $(TopHorloge))"
print ""

exit $StatusFinal
