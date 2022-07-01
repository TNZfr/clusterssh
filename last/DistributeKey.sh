#!/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print "Syntax : cls DistributeKey [Pattern | ALL]"
    print ""
    print "Pattern : Cf cls TestPattern"
    print "ALL     : All node of the referential"
    print ""
}

#-------------------------------------------------------------------------------
TestInstall ()
{
    Product=$1

    which $Product > /dev/null 2>&1
    Status=$?
    [ $Status -eq 0 ] && return

    print "$Product package not installed."
    exit 1
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -eq 0 ]
then
    Aide
    exit 1
fi

# Controle des rep-requis
# -----------------------
TestInstall expect
TestInstall telnet

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

TmpPass=/tmp/csdk-$$
TmpExpe=$TmpPass/Expect.log

mkdir $TmpPass

# Deploiement de la cle publique
# ------------------------------
cd $CS_CURRENT/node
for Node in $CS_NodeList
do
    printf "Node \033[37;44m $Node \033[m"

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

    # Traitement des utilisateurs distants
    # ------------------------------------
    for UserNode in $(eval echo $(cat $Node))
    do
	User=$(echo $UserNode|cut -f1 -d@)

        # Si le compte est precise, on filtre
        [ "$CS_User" != "" ] && [ "$CS_User" != "$User" ] && continue

	printf "\t%-10.10s : " $User

        # Controle de l'empreinte RSA
        # ---------------------------
	KnownHosts=$HOME/.ssh/known_hosts
	[ -f $KnownHosts ] && Empreinte=$(grep $(GetRealNodeName $Node) $KnownHosts)

	if [ "$Empreinte" = "" ]
	then
	    printf "\033[47;34m recording fingerprint \033[m "
	    ssh-keyscan -t rsa $(GetRealNodeName $Node) >> $KnownHosts
	fi
    	
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

	CleAbsente=$(grep "password:" $TmpExpe|wc -l)
	if [ $CleAbsente -eq 0 ]
	then 
	    print "public key deployed."
	    continue
	fi

	# Deploiement de la cle publique
	# ------------------------------
	if [ ! -f $TmpPass/$User ]
	then
	    printf "\033[34;47mPassword ?\033[m : " 
	    stty -echo; read CSDK_PASSWORD; stty echo
	    echo $CSDK_PASSWORD > $TmpPass/$User
	fi

	# Deploiement de la cle
	# ---------------------
	CSDK_Password=$(cat $TmpPass/$User)
	CSDK_PublicKey="$(cat $HOME/.ssh/id_rsa.pub)"
	printf "Sending ... "

	(expect <<EOF
set timeout 5
spawn ssh -q $UserNode 
expect "${UserNode}'s password: "
send   "$CSDK_Password\r"
expect "$ "
send   "mkdir -p .ssh; chmod 700 .ssh \r"
expect "$ "
send   "echo $CSDK_PublicKey >> .ssh/authorized_keys \r"
expect "$ "
send   "chmod 600 .ssh/authorized_keys \r"
expect "$ "
interact
EOF
	) > $TmpExpe 2>&1
	Status=$?

	if [ $Status -eq 0 ]
	then
	    print "Key sent."
	else
	    print "\033[31;47m wrong password (key not sent) \033[m"
	fi
    done
    print ""
done

# Suppression des traces
# ----------------------
rm -rf $TmpPass ~/.ssh/ssh-copy-id_id.*

exit 0
