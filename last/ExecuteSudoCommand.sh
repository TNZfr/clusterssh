#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls ExecuteSudoCommand [User@]Pattern UserID Command"
    print ""
    print "Pattern  : Pattern node name used by Execute and Copy commands."
    print "User     : User to use (cf cls TestPattern command)"
    print "UserID   : UserID used to run the script on each node."
    print "Command  : Command to be run on each node."
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#
if [ $# -lt 3 ]
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

UserID=$2
SSHCommand="$(echo $*|cut -f3- -d' ')"

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
    print "\033[34;47m Node    \033[m : $Node"
    print "\033[34;47m User    \033[m : $User -> $UserID"
    print "\033[34;47m Command \033[m : $SSHCommand"
    print ""

    Complement=""
    [ $User != root ] && Complement="sudo"

    if [ $UserID = $User ]
    then
	# Pas de sudo nécessaire on utilise le compte cible
	ssh -q $UserNode "$SSHCommand"
    else
	# On fait le sudo 
	ssh -q $UserNode $Complement su - $UserID "$SSHCommand"
    fi
    Status=$?
    [ $Status -ne 0 ] && FinalStatus=$Status
    print ""
    print "\033[34;47m Status  \033[m : $Status"
    print "\033[34;47m Elapse  \033[m : $(AfficheDuree $Debut $(TopHorloge))"
done

ehco  "-------------------------------------------------------------------------"
print "\033[32;44m Final status \033[m : $Status"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_EC $(TopHorloge))"
print ""

exit $FinalStatus
