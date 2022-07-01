#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PubKeySynchro Ref1[,Ref2 ...]|ALL"
    print ""
    print "Ref        : Target referential's name."
    print "             ALL apply on all referential present in CS_DEPOT"
    print ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
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

# Repertoire de travail temporaire
CSPK_CurrentDir=$PWD
CSPK_TMP=/tmp/ClusterSSH-$$
mkdir -p $CSPK_TMP
cd       $CSPK_TMP

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
    echo "Synchronizing public key files for $Referentiel ..."

    # Recuperation de la liste des compte@serveur
    ListeCompteServeur=$(cat $CS_CURRENT/node/*|sort|uniq)

    # Mise a jour de l'authorized_keys
    for CompteServeur in $ListeCompteServeur
    do
	# 1. Recuperation authorized_keys
	echo "Updating public key file for $CompteServeur ..."
	scp -q $CompteServeur:.ssh/authorized_keys .
	Status=$?
	[ $Status -ne 0 ] && echo "authorized_keys missing for $CompteServeur from $Referentiel" && continue

	cp authorized_keys authorized_keys.original
	
	# 2. Ajout des comptes manquants
	cat $CSPK_ACTIVE | while read Enreg
	do
	    Present=$(grep "${Enreg} for $Referentiel" authorized_keys)
	    if [ "$Present" = "" ]
	    then
		Owner=$(echo $Enreg|cut -d' ' -f3-)
		echo "  Granting $Owner ..."		
		echo "${Enreg} for $Referentiel" >> authorized_keys
	    fi
	done

	# 3. Suppression des comptes revoques
	cat $CSPK_REVOKE | while read Enreg
	do
	    Present=$(grep "${Enreg} for $Referentiel" authorized_keys)
	    if [ "$Present" != "" ]
	    then
		Owner=$(echo $Enreg|cut -d' ' -f3-)
		echo "  Revoking $Owner ..."
		grep -v "$Present" authorized_keys     > authorized_keys.tmp
		mv   -f            authorized_keys.tmp   authorized_keys
	    fi
	done

	# 4. Renvoi de authorized_keys si modification
	if [ "$(cat authorized_keys|cksum)" != "$(cat authorized_keys.original|cksum)" ]
	then
	    scp -q authorized_keys $CompteServeur:.ssh
	    Status=$?
	    [ $Status -ne 0 ] && echo "$CompteServeur authorized_keys not updated"
	fi
	rm -f authorized_keys authorized_keys.original
    done    
done

# Nettoyage
rm -rf $CSPK_TMP

exit 0
