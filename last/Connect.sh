#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls Connect [User@]Pattern"
    print ""
    print "User    : User to use (cf cls TestPattern command)"
    print "Pattern : Pattern node name used by Execute and Copy commands."
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

# Parsing parametres
# ------------------
ParsePattern $1

cd $CS_CURRENT/node
case $CS_NbNode in
    0)
        print ""
        print "\033[33;41;1m ERROR \033[m : No node found."
        print ""
	exit 1
	;;

    1)
	# On passe a la suite
	Node="$(echo $CS_NodeList)"
	;;

    *)
	TestPattern.sh $1
	print "Change your pattern selection to be more restrictive."
	print ""
	exit 1
	;;
esac

# Controle des utilisateurs disponibles
# -------------------------------------
UserNodeList="$(eval echo $(cat $Node)|sed 's/ /\n/g')"
NbUser=$(cat $Node|wc -l)

if [ "$CS_User" != "" ] && [ $NbUser -gt 0 ]
then
    for UserNode in $UserNodeList
    do
	User=$(echo $UserNode|cut -f1 -d@)
	if [ "$User" = "$CS_User" ]
	then
	    UserNodeList=$UserNode
	    NbUser=1
	    break
	fi
    done

    if [ "$User" != "$CS_User" ]
    then
        print ""
        print "\033[33;41;1m ERROR \033[m : Account $CS_User not available on $Node"
        print ""
	exit 1
    fi
fi

# Connexion au serveur distant
# ----------------------------
case $NbUser in
    0)
        print ""
        print "\033[33;41;1m ERROR \033[m : No account available on $Node"
        print ""
	;;

    1)
	cd $CS_CurrentDir
	print "Server real name ... : \033[34;47m $(echo $UserNodeList|cut -f2 -d@) \033[m"
	
	if [ "$(GetRemoteChar xauth $UserNodeList)" != "NotAvailable" ]
	then
	    # X11 forwarding
	    Option="-X"
	    print "X11 forwarding       : ENABLED"
	else
	    # Pas de X11
	    Option=""
	    print "X11 forwarding       : disabled"
	fi
	print ""
	ssh $Option $UserNodeList
	;;

    *)
	print ""
	print "Several accounts available. Can be precised using following commands :"
	for UserNode in $UserNodeList
	do
	    User=$(echo $UserNode|cut -f1 -d@)
	    print "\tcls Connect $User@$Pattern"
	done
	print ""
	UserNode=$(eval echo $(cat $Node|head -1))
	User=$(echo $UserNode|cut -f1 -d@)
	print "Server real name ... : \033[34;47m $(echo $UserNode|cut -f2 -d@) \033[m"
	print "Default account used : \033[34;47m $User \033[m"

	cd $CS_CurrentDir
	if [ "$(GetRemoteChar xauth $UserNode)" != "NotAvailable" ]
	then
	    # X11 forwarding
	    Option="-X"
	    print "X11 forwarding       : ENABLED"
	else
	    # Pas de X11
	    Option=""
	    print "X11 forwarding       : disabled"
	fi
	print ""
	ssh $Option $UserNode
esac

exit 0
