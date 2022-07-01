#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls ExecuteScript [User@]Pattern Script"
    print ""
    print "Pattern : Pattern node name used by Execute and Copy commands."
    print "User    : User to use (cf cls TestPattern command)"
    print "Script  : Script to execute on each select node."
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#
if [ $# -lt 2 ]
then
    Aide
    exit 1
fi

print ""
print "Current referential : \033[1;33;44m $(GetCurrentReferentiel) \033[m"
print ""

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

Script="$(echo $*|cut -f2- -d' ')"

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
Debut_EC=$(TopHorloge)
FinalStatus=0
for UserNode in $CS_UserNodeList
do
    Debut=$(TopHorloge)

    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)

    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node   \033[m : $Node"
    print "\033[34;47m User   \033[m : $User"
    print "\033[34;47m Script \033[m : $Script"
    print ""
    ssh -q $UserNode "$(cat $Script)"
    Status=$?
    [ $Status -ne 0 ] && FinalStatus=$Status
    print ""
    print "\033[34;47m Status  \033[m : $Status"
    print "\033[34;47m Elapse  \033[m : $(AfficheDuree $Debut $(TopHorloge))"
done
echo  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $Status"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_EC $(TopHorloge))"
print ""

exit $FinalStatus
