#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls CheckRef EnvName ..."
    print "         cls CheckRef all"
    print ""
    print "EnvName : Environment name to check"
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

TmpPass=/tmp/clscr-$$
KnownHosts=$HOME/.ssh/known_hosts

case $(echo $1|tr [:upper:] [:lower:]) in
    all)
	cd $CS_DEPOT
	for NodeDir in $(ls -1d */node)
	do
	    EnvList="$EnvList $(dirname $NodeDir)"
	done
	;;

    *) 
	EnvList=$*
esac

# Generation des environnements uniques
# -------------------------------------
for CS_ENV in $EnvList
do
    CS_ROOT=$CS_DEPOT/$CS_ENV
    if [ ! -d $CS_ROOT ]
    then
	print "Unknown referential : $CS_ENV"
	continue
    fi

    # Controle de la presence des serveurs de l'environnement
    printh "Checking referential $CS_ENV ..."

    cd $CS_ROOT/node

    NbPresent=0
    NbErreur=0

    NbServeur=$(ls -1 * 2>/dev/null|wc -l)
    printh "$NbServeur server(s) found."
    [ $NbServeur -lt 1 ] && continue

    mkdir $TmpPass
    for Node in *
    do
	NodeName=$(cat $Node|head -1|cut -f2 -d@)
	(
	    telnet $NodeName 22 << EOF
quit
EOF
	) 2>$TmpPass/$NodeName 1>/dev/null &
    done
    wait
    printh "Check done."

    for Result in $TmpPass/*
    do
        Alive=$(grep "Connection closed by foreign host." $Result|wc -l)
	if [ $Alive -eq 1 ]
	then
	    ((NbPresent += 1))

	    # Controle de l'empreinte RSA
	    NodeName=$(basename $Result)
	    grep $NodeName $KnownHosts >/dev/null 2>&1
	    StatusEmpreinte=$?

	    if [ $StatusEmpreinte -ne 0 ]
	    then
		printf "\033[47;34m recording fingerprint \033[m "
		ssh-keyscan -t rsa $NodeName >> $KnownHosts
	    fi
	else
	    print "\033[34;47m $(basename $Result) \033[m"
	    cat $Result
	    print ""
	    (( NbErreur += 1 ))
	fi
    done

    # Affichage des resultats
    print ""
    print  "For $CS_ENV environment :"
    printf " %3d responding server(s).\n" $NbPresent
    printf " %3d missing server(s).\n"    $NbErreur
    print  ""
    printh "Done."

    # Nettoyage
    rm -rf $TmpPass
done
exit 0
