#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls ParalTarExtract [User@]Pattern[:TargetDirectory] LocalArchive"
    print ""
    print "User            : User to use (optional)"
    print "                  Default value is the first account defined in referential"
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "TargetDirectory : Directory where files are copied (optional)"
    print "                  Default value is remote home directory"
    print "LocalArchive    : Archive to be extracted on remote node(s)"
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

LocalArchive=$2
if [ ! -f $LocalArchive ]
then
    print "Archive $LocalArchive not found."
    exit 1
fi

# Controle du format
# ------------------
case $(file $LocalArchive|cut -d: -f2|cut -d' ' -f2-4) in
    "POSIX tar archive")     Format=tar ;;
    "gzip compressed data,") Format=tgz ;;

    *)
	print "Unknown archive format $LocalArchive"
	exit 1
esac

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
	    
	    RemoteGunzip=$(GetRemoteChar gunzip $UserNode)

	    # Extraction de l'archive sur le distant
	    # --------------------------------------
	    case $Format in
		tar)
		    if [ $RemoteGunzip != NotAvailable ] && [ $(GetLocalChar gzip) != NotAvailable ]
		    then
			# Compression / Decompression
			print "\033[34;47m Compression     \033[m : Local - Remote"
			gzip -9c $LocalArchive|ssh -q $UserNode "gunzip - -c|tar xf - -C $CS_TargetDir"
			Status=$?
		    else
			# Pas de compression
			print "\033[34;47m Compression     \033[m : none - none"
			cat      $LocalArchive|ssh -q $UserNode "            tar xf - -C $CS_TargetDir"
			Status=$?
		    fi
		    ;;

		tgz)
		    if [ $RemoteGunzip != NotAvailable ]
		    then
			# Decompression distante
			print "\033[34;47m Compression     \033[m : none - Remote"
			cat        $LocalArchive|ssh -q $UserNode "gunzip - -c|tar xf - -C $CS_TargetDir"
			Status=$?

		    elif [ $(GetLocalChar gunzip) != NotAvailable ]
		    then
			# Decompression locale
			print "\033[34;47m Compression     \033[m : Local - none"
			gunzip -9c $LocalArchive|ssh -q $UserNode "            tar xf - -C $CS_TargetDir"
			Status=$?
		    else
			print "ERROR : no decompression tools available on local and remote server."
			Status=1
		    fi
		    ;;
	    esac
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
