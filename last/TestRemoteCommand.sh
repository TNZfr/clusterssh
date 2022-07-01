#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls TestRemoteCommand Pattern [Command#1 Command#2 ... ]"
    print ""
    print "Pattern : Pattern node name used by Execute and Copy commands."
    print "Command : Command list to be tested"
    print ""
    print "Default command tested : xauth gzip gunzip python"
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#
Aide

print ""
print "Current referential : \033[1;33;44m $(GetCurrentReferentiel) \033[m"
print ""

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

[ $# -gt 1 ] && CommandList=$(echo $*|cut -d' ' -f2-) || CommandList=""

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
StatusFinal=0
Debut_CMD=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)
    
    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node            \033[m : $Node"
    print "\033[34;47m User            \033[m : $User"

    # Reset du cache, on supprime le fichier
    rm -f $CS_CURRENT/char/$Node

    for Command in xauth gzip gunzip python $CommandList
    do
	RemoteCommand=$(GetRemoteChar  $Command $UserNode)
	printf " Command %-8s : %s \n" $Command $RemoteCommand
    done
done

echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $StatusFinal"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_CMD $(TopHorloge))"
print ""

exit $StatusFinal
