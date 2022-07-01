#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls PubKeySynchro User@Pattern PubKeyFile ..."
    print ""
    print "User@Pattern : Cf Test Pattern"
    print "PubKeyFile   : Public key file"
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

TmpDir=/tmp/cls-pubkeydeploy-$$
mkdir $TmpDir

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

FileList=$(echo $*|cut -d' ' -f2-)
cat $FileList|sort|uniq > $TmpDir/PubKeyList

# Mise a jour de l'authorized_keys
# --------------------------------
cd $TmpDir
for CompteServeur in $CS_UserNodeList
do
    # 1. Recuperation authorized_keys
    echo "Updating public key file for $CompteServeur ..."
    scp -q $CompteServeur:.ssh/authorized_keys .
    Status=$?
    [ $Status -ne 0 ] && echo "authorized_keys missing for $CompteServeur from $Referentiel" && continue

    cp authorized_keys authorized_keys.original
    
    # 2. Ajout des comptes manquants
    cat PubKeyList|while read Enreg
    do
	Present=$(grep "${Enreg}" authorized_keys)
	if [ "$Present" != "" ]
	then
	    Owner=$(echo $Enreg|cut -d' ' -f3-)
	    echo "  Undeploying $Owner ..."

	    grep -v "$Present" authorized_keys     > authorized_keys.tmp
	    mv -f              authorized_keys.tmp   authorized_keys
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

# Nettoyage
rm -rf $TmpDir

exit 0
