#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PubKeyFinger Ref1[,Ref2 ...]|ALL"
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
CSPK_FINGER=$CS_CURRENT/PubKey.Finger && > $CSPK_FINGER

# Mise a jour des fichiers
# ------------------------
for Referentiel in $ListeReferentiel
do
    CS_CURRENT=$CS_DEPOT/$Referentiel
    [ ! -d $CS_CURRENT ] && echo "Unknown referential : $Referentiel" && continue
    echo "Getting fingerprint for $Referentiel ..."

    # Recuperation de la liste des compte@serveur
    ListeCompteServeur=$(cat $CS_CURRENT/node/*|sort|uniq)

    # 1. Recuperation des empreintes pour tous les comptes de tous les serveurs
    for CompteServeur in $ListeCompteServeur
    do
	echo "- Collecting $CompteServeur fingerprint(s) ..."
	ssh -q $CompteServeur "cat .ssh/authorized_keys|ssh-keygen -lf -" >> $CSPK_FINGER
    done

    # 2. Nettoyage du fichier des empreintes
    sort  ${CSPK_FINGER}|uniq  > ${CSPK_FINGER}.tmp
    mv -f ${CSPK_FINGER}.tmp     ${CSPK_FINGER}
done

# Nettoyage
rm -rf $CSPK_TMP

exit 0
