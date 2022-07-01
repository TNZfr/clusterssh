#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PubKeyAdd Ref1[,Ref2 ...]|ALL PubKeyFile"
    print ""
    print "Ref        : Target referential's name."
    print "             ALL apply on all referential present in CS_DEPOT"
    print "PubKeyFile : File containing public key to add"
    print ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 2 ]
then
    Aide
    exit 1
fi

# Liste des referentiels sur lesquels ajouter la cle
# --------------------------------------------------
ListeReferentiel=$(echo $1|tr [','] [' '])
if [ "$(echo $ListeReferentiel|tr [:upper:] [:lower:])" = "all" ]
then
    ListeReferentiel=$(cd $CS_DEPOT;ls -1d */node | cut -d/ -f1)
fi

PubKeyFile=$2
[ ! -f $PubKeyFile ] && echo "ERROR : File not found $PubKeyFile" && exit 1

# Fichiers contenant les cles deployees
# -------------------------------------
CSPK_ACTIVE=$CS_CURRENT/PubKey.Active && [ ! -f $CSPK_ACTIVE ] && touch $CSPK_ACTIVE
CSPK_REVOKE=$CS_CURRENT/PubKey.Revoke && [ ! -f $CSPK_REVOKE ] && touch $CSPK_REVOKE
CSPK_FINGER=$CS_CURRENT/PubKey.Finger && [ ! -f $CSPK_REVOKE ] && touch $CSPK_FINGER

# Mise a jour des fichiers
# ------------------------
for Referentiel in $ListeReferentiel
do
    CS_CURRENT=$CS_DEPOT/$Referentiel
    [ ! -d $CS_CURRENT ] && echo "Unknown referential : $Referentiel" && continue
    
    cat $PubKeyFile|while read Enreg
    do
	PubKey=$(echo $Enreg|cut -d' ' -f1,2)
	Owner=$( echo $Enreg|cut -d' ' -f3-)

	# Controle des revocations
	Revoked=$(grep "^$PubKey" $CSPK_REVOKE)
	if [ "$Revoked" != "" ]
	then
	    # Suppression du fichier des revocations
	    grep -v "$Revoked"         $CSPK_REVOKE > ${CSPK_REVOKE}.tmp
	    mv   -f ${CSPK_REVOKE}.tmp $CSPK_REVOKE
	    echo "Public key for [$Owner] previously revoked, re-activation ..."
	fi

	# Controle des doublons
	AlreadyActive=$(grep "^$PubKey" $CSPK_ACTIVE)
	if [ "$AlreadyActive" != "" ]
	then
	    ActiveOwner=$(echo $AlreadyActive|cut -d' ' -f3-)
	    echo "DUPLICATE KEY : key for [$Owner] already exists for [$ActiveOwner]"
	else
	    echo $Enreg >> $CSPK_ACTIVE
	    echo "Public key for [$Owner] added for $Referentiel"
	    echo $Enreg | ssh-keygen -lf - >> $CSPK_FINGER
	fi
    done
done

# Suppression des doublons des empreintes
# ---------------------------------------
sort  $CSPK_FINGER|uniq > $CSPK_FINGER.tmp
mv -f $CSPK_FINGER.tmp    $CSPK_FINGER

exit 0
