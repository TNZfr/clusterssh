#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PubKeyRevoke Ref1[,Ref2 ...]|ALL PubKeyFile"
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
if [ $(echo $ListeReferentiel|tr [:upper:] [:lower:]) = "all" ]
then
    ListeReferentiel=$(cd $CS_DEPOT;ls -1d */node | cut -d/ -f1)
fi

PubKeyFile=$2
[ ! -f $PubKeyFile ] && echo "ERROR : File not found $PubKeyFile" && exit 1

# Fichiers contenant les cles deployees
# -------------------------------------
CSPK_ACTIVE=$CS_CURRENT/PubKey.Active && [ ! -f $CSPK_ACTIVE ] && touch $CSPK_ACTIVE
CSPK_REVOKE=$CS_CURRENT/PubKey.Revoke && [ ! -f $CSPK_REVOKE ] && touch $CSPK_REVOKE

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

	# Controle d'activite
	Active=$(grep "^$PubKey" $CSPK_ACTIVE)
	if [ "$Active" != "" ]
	then
	    # Suppression du fichier des cles actives
	    grep -v "$Active"          $CSPK_ACTIVE > ${CSPK_ACTIVE}.tmp
	    mv   -f ${CSPK_ACTIVE}.tmp $CSPK_ACTIVE
	    echo "Public key for [$Owner] removed from active list (1/2)"
	else
	    echo "Public key for [$Owner] not active (1/2)"
	fi

	# Controle des doublons
	AlreadyRevoked=$(grep "^$PubKey" $CSPK_REVOKE)
	if [ "$AlreadyRevoked" != "" ]
	then
	    RevokedOwner=$(echo $AlreadyRevoked|cut -d' ' -f3-)
	    echo "Public key for [$Owner] already revoked (2/2), revoked name : $RevokedOwner"
	else
	    echo $Enreg >> $CSPK_REVOKE
	    echo "Public key for [$Owner] revoked for $Referentiel (2/2)"
	fi
    done
done
