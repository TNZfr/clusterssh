#!/usr/bin/bash

#-------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print "Syntax : cls RevokeKey Pattern | ALL"
    print ""
    print "Pattern : Pattern name node, cf cls TestPattern"
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

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

TmpPass=/tmp/csdk-$$
TmpExpe=$TmpPass/Expect.log
TmpSSH=$TmpPass/RemoteCommand.log

mkdir $TmpPass

# Deploiement de la cle publique
# ------------------------------
cd $CS_CURRENT/node
for Node in $CS_NodeList
do
    printf "Node \033[37;44m $Node \033[m\n"

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
	Empreinte=""
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

	AskPassword=$(grep "${UserNode}'s password:" $TmpExpe|wc -l)
	if [ $AskPassword -gt 0 ]
	then 
	    print "\033[47;30m public key already revoked \033[m"
	    continue
	fi

	# Suppression de la cle publique distante
	# ---------------------------------------
	LocalPubKey=~/.ssh/id_rsa.pub
	if [ ! -f $LocalPubKey ]
	then
	    print "\033[1;33;41m Local public key not found \033[m"
	    continue
	fi

	if  [ -f $CS_CURRENT/revoke.deny ] && \
	    [ "$(grep $User $CS_CURRENT/revoke.deny) 2>/dev/null" != "" ]
	then
	    print "\033[1;33;41m Revoke public key for user $User denied \033[m"
	    continue
	fi

	(ssh $UserNode <<EOF
            cd ~/.ssh
            grep -v "$(cat $LocalPubKey)"   authorized_keys > authorized_keys.revoke_$User
            cp authorized_keys              authorized_keys.$(date +%Y%m%d-%Hh%Mm%Ss)
            mv authorized_keys.revoke_$User authorized_keys
EOF
	) > $TmpSSH 2>&1
	Status=$?
	print "Status = $Status"

    done
    print ""
done

# Suppression des traces
# ----------------------
rm -rf $TmpPass

exit $Status
