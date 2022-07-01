#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls GenerateRef CSVFile [EnvName]"
    print ""
    print "CSVFile : File describing env, nodes and users for the referential."
    print "EnvName : Environment name to proceed (row #1 in CSVFile)"
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#
if [ $# -eq 0 ]
then
    Aide
    exit 1
fi

if [ ! -f $1 ]
then
    print ""
    print "File not found : $1"
    Aide
    exit 1
fi

# Conversion en CSV Unix
# ----------------------
CS_CSVFILE=/tmp/cls-$$.csv
cat $1              | \
    tr [';']  [','] | \
    tr ['\t'] [','] | \
    tr ['\r'] ['']  > $CS_CSVFILE

if [ $# -eq 1 ]
then
    ListeEnv=$(cat $CS_CSVFILE | cut -f1 -d',' | sort | uniq | grep -v "Env")
else
    ListeEnv=$(echo $* | cut -f2- -d' ')
fi

# Generation des environnements uniques
# -------------------------------------
for CS_ENV in $ListeEnv
do
    CS_ROOT=$CS_DEPOT/$CS_ENV

    # Vidage du précedent referentiel (au cas ou)
    printh "Cleaning directory $CS_ROOT ..."
    rm -rf $CS_ROOT/node 2>/dev/null

    # Creation referentiel vide
    mkdir -p -m 755 $CS_ROOT/node
    printh "$CS_ROOT directory created."

    # Generation des noeuds pour l'environnement demande
    printh "Generating referential ..."

    # Initialisation ds fichiers du referentiel
    grep "^$CS_ENV," $CS_CSVFILE|grep ",:file:,"|cut -f3 -d','|sort|uniq| while read Filename
    do
	printh "Iniatilizing $Filename"
	> $CS_ROOT/$Filename
    done

    grep "^$CS_ENV," $CS_CSVFILE | while read NodeDef
    do
	SymbolName=$(echo $NodeDef|cut -f2 -d',')
	NodeName=$(  echo $NodeDef|cut -f3 -d',')
	[ "$SymbolName" = "" ] && SymbolName=$NodeName

	case $SymbolName in
	    :file:)
		FileName=$NodeName
		echo $NodeDef|cut -f4- -d','|sed 's/,/ /g' >> $CS_ROOT/$FileName
		;;

	    :link:)
		Source=$(echo $NodeDef|cut -f4 -d',')
		Target=$NodeName
		ln -sf $Target $CS_ROOT/$Source
		printh "link $Source created"
		;;

	    *)
		for User in $(echo $NodeDef|cut -f4- -d','|sed 's/,/ /g')
		do
		    echo $User@$NodeName >> $CS_ROOT/node/$SymbolName
		done
	esac
    done
    printh "Done."
done
rm -f $CS_CSVFILE

exit 0
