#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls TarCompress [User@]Pattern[:RemoteDirectory] TarBasename RemoteFiles ..."
    print ""
    print "User            : User to use (cf cls TestPattern command)"
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "RemoteDirectory : Root directory on remote nodes used to extract files"
    print "TarBasename     : Basename for generated archives"
    print "RemoteFile(s)   : File list to be copied from selected nodes"
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

TarBasename=$2
RemoteFile=$(echo $*|cut -d' ' -f3-)

# Recherche de l'outil de compression
# -----------------------------------
[ $(GetLocalChar gzip) != NotAvailable ] && TarExtension=tgz || TarExtension=tar

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
StatusFinal=0
Debut_CMD=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    Debut_UN=$(TopHorloge)
    
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)
    
    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $Node"
    print "\033[34;47m User            \033[m : $User"

    ShortNodeName=$(echo $Node|cut -f1 -d.)
    TarArchive=$TarBasename.$User.$ShortNodeName.$TarExtension
    print "\033[34;47m Archive         \033[m : $TarArchive"

    case $TarExtension in
	tgz)
	    RemoteGzip=$(GetRemoteChar gzip $UserNode)
	    if [ "$RemoteGzip" = "NotAvailable" ]
	    then
		# Local compression
		print "\033[34;47m Compression     \033[m : Local - none"
		ssh -q $UserNode "cd $CS_TargetDir;tar cf - $RemoteFile" |gzip        -9c  > $TarArchive
	    else
		# Remote compression
		print "\033[34;47m Compression     \033[m : none - Remote"
		ssh -q $UserNode "cd $CS_TargetDir;tar cf - $RemoteFile  |$RemoteGzip -9c" > $TarArchive
	    fi
	    ;;

	tar)
	    # No compression
	    print "\033[34;47m Compression     \033[m : none - none"
	    ssh -q $UserNode "cd $CS_TargetDir;tar cf - $RemoteFile"  > $TarArchive
	    ;;
    esac
    Status=$?
    
    print "\033[34;47m Status          \033[m : $Status ($(AfficheDuree $Debut_UN $(TopHorloge))"
    [ $Status -ne 0 ] && StatusFinal=$Status
done

echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_CMD $(TopHorloge))"
print ""

exit $StatusFinal
