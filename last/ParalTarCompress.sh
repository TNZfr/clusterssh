#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls ParalTarCompress [User@]Pattern[:RemoteDirectory] TarBasename RemoteFiles ..."
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

TarBasename=$2
RemoteFile=$(echo $*|cut -d' ' -f3-)

# Recherche de l'outil de compression
# -----------------------------------
if [ $(GetLocalChar gzip) != NotAvailable ]
then
    TarExtension=tgz
else
    TarExtension=tar
fi

# Repertoire des logs temporaires
# -------------------------------
TmpDir=/tmp/cls-$$
mkdir $TmpDir

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
print "Launching command on $CS_NbNode node(s) ..."
Debut_PC=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)
    UserNodeShort=$(echo $UserNode|cut -f1 -d.)
    CS_ParalLog=$TmpDir/Paral-$UserNodeShort.log
    (
	(
	    LogParalEntete_debut $Node $User $LocalArchive
	    
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
	    echo "$Status,$UserNodeShort" >> $TmpDir/Paral.status
	    LogParalEntete_fin
	    
	) >>  $CS_ParalLog 2>&1
	cat   $CS_ParalLog
	rm -f $CS_ParalLog
    ) &
done

# attente de fin des traitements pour la consolidation des status
wait
Fin_PC=$(TopHorloge)

echo "-------------------------------------------------------------------------"
Status=0
NbErreur=$(grep -v "0," $TmpDir/Paral.status|wc -l)
if [ $NbErreur -ne 0 ]
then
    for StatusNode in $(grep -v "0," $TmpDir/Paral.status|sort)
    do
	Status=$(   echo $StatusNode|cut -f1 -d,)
	NodeShort=$(echo $StatusNode|cut -f2 -d,)
	print "$NodeShort \033[31;47m Code retour $Status \033[m" 
    done
    print ""
fi
print "\033[32;44m Final status \033[m : $Status"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_PC $Fin_PC)"
print ""

# Nettoyage des fichiers temporaires
# ----------------------------------
rm -rf $TmpDir
exit $StatusFinal
