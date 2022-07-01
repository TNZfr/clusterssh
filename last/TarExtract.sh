#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls TarExtract [User@]Pattern[:TargetDirectory] LocalArchive"
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

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
StatusFinal=0
Debut_CMD=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    Debut_UN=$(TopHorloge)
    
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)
    
    RemoteGunzip=$(GetRemoteChar gunzip $UserNode)

    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $Node"
    print "\033[34;47m User            \033[m : $User"
    print "\033[34;47m Remote directory\033[m : $CS_TargetDir"

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
    print "\033[34;47m Status          \033[m : $Status ($(AfficheDuree $Debut_UN $(TopHorloge)))"
    [ $Status -ne 0 ] && StatusFinal=$Status
done

echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_CMD $(TopHorloge))"
print ""

exit $StatusFinal
