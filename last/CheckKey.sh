#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print "Syntax : cls CheckKey [Pattern | ALL]"
    print ""
    print "Pattern : Cf cls TestPattern"
    print "ALL     : All node of the referential"
    print ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -eq 0 ]
then
    Aide
    exit 1
fi

# Analyse des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

# Recuperation de la liste des utilisateurs
# -----------------------------------------
TmpPass=/tmp/csdk-$$
TmpExpe=$TmpPass/Expect.log

mkdir $TmpPass

# Deploiement de la cle publique
# ------------------------------
cd $CS_CURRENT/node
for Node in $CS_NodeList
do
    printf "Node \033[37;44m $Node \033[m $(GetRealNodeName $Node)"

    # Presence serveur
    # ----------------
    (
	telnet $(GetRealNodeName $Node) 22 << EOF
quit
EOF
    ) 2>$TmpPass/ping 1>/dev/null

    Alive=$(grep "Connection closed by foreign host." $TmpPass/ping|wc -l)
    if [ $Alive -eq 0 ]
    then
	printf " : "
	cat $TmpPass/ping
	continue
    fi
    print ""

    # Controle de l'empreinte RSA
    # ---------------------------
    Empreinte=""
    KnownHosts=$HOME/.ssh/known_hosts
    [ -f $KnownHosts ] && Empreinte=$(grep $(GetRealNodeName $Node) $KnownHosts)

    if [ "$Empreinte" = "" ]
    then
	printf "\033[47;34m recording fingerprint \033[m "
	ssh-keyscan -t rsa $(GetRealNodeName $Node) >> $KnownHosts
    fi

    # Traitement des utilisateurs distants
    # ------------------------------------
    for UserNode in $(eval echo $(cat $Node))
    do
	User=$(echo $UserNode|cut -f1 -d@)

        # Si le compte est precise, on filtre
        [ "$CS_User" != "" ] && [ "$CS_User" != "$User" ] && continue

	printf "\t%-10.10s : " $User

	# Test de deploiement de la cle
	# -----------------------------
	(expect <<EOF
set timeout 2
spawn ssh -q $UserNode exit
expect "${UserNode}'s password:"
send   "\003"
sleep 1
interact
EOF
	) > $TmpExpe 2>&1

	CleAbsente=$(grep "${UserNode}'s password:" $TmpExpe|wc -l)
	if [ $CleAbsente -eq 0 ]
	then 
	    print "public key deployed."
	else
	    print "\033[47;30m public key to be deployed \033[m"
	fi
    done
    print ""
done

# Suppression des traces
# ----------------------
rm -rf $TmpPass

exit 0
