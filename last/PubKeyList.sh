#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print "Syntax : cls PubKeyList Ref1[,Ref2 ...]|ALL [Options]"
    print ""
    print "Ref        : Target referential's name."
    print "             ALL apply on all referential present in CS_DEPOT"
    print "Options    :"
    print "    None : list all defined access and revoked users for referential(s)"
    print "    AccessType=REVOKED|GRANTED, default ALL, based on local access files"
    print "    "
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

# Fichiers contenant les cles deployees
# -------------------------------------
CSPK_ACTIVE=$CS_CURRENT/PubKey.Active && [ ! -f $CSPK_ACTIVE ] && touch $CSPK_ACTIVE
CSPK_REVOKE=$CS_CURRENT/PubKey.Revoke && [ ! -f $CSPK_REVOKE ] && touch $CSPK_REVOKE

for Referentiel in $ListeReferentiel
do
    CS_CURRENT=$CS_DEPOT/$Referentiel
    [ ! -d $CS_CURRENT ] && echo "Unknown referential : $Referentiel" && continue

    echo  "------------------------------------------------------------"
    print "Public key management for \033[47;34m $Referentiel \033[m"
    
    echo "--- Granted access(es) ---"
    cat $CSPK_ACTIVE|cut -d' ' -f3-
    echo ""

    echo "--- Revoked access(es) ---"
    cat $CSPK_REVOKE|cut -d' ' -f3-
    echo ""  
done
