#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls GetGlobalInfo [User@]Pattern Command"
    print ""
    print "Pattern : Pattern node name used by Execute and Copy commands."
    print "User    : User to use (cf cls TestPattern command)"
    print "Command : Command to execute on each select node."
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

if [ $(echo "$2"|tr [:upper:] [:lower:]) = "-f" ]
then
    # Script
    SSHCommand=""
    SSHScript=$3
else
    # Commande
    SSHCommand="$(echo $*|cut -f2- -d' ')"
    SSHScript=""
fi

# Repertoire des logs temporaires
# -------------------------------
TmpDir=/tmp/cls-$$
mkdir $TmpDir

# Execution de la commande sur la liste des serveurs
# --------------------------------------------------
print "Launching command on $CS_NbNode node(s) ..."
Debut_PC=$(TopHorloge)
for UserNode in $CS_UserNodeList
do
    User=$(     echo $UserNode|cut -d@ -f1)
    Node=$(     echo $UserNode|cut -d@ -f2)
    NodeShort=$(echo $UserNode|cut -f1 -d.)

    (
	(
	    if [ "$SSHCommand" != "" ]
	    then
		ssh -q $UserNode $SSHCommand
		Status=$?
	    else
		ssh -q $UserNode "$(cat $SSHScript)"
		Status=$?
	    fi

	    echo "$Status,$NodeShort" >> $TmpDir/Paral.status

	) >>  $TmpDir/Paral-$NodeShort.log 2>&1 
    ) &
done

# attente de fin des traitements pour la consolidation des status
wait
Fin_PC=$(TopHorloge)

echo "-------------------------------------------------------------------------"
PlusLong=$(grep "0," $TmpDir/Paral.status|cut -f2 -d,|wc -L)
for StatusNode in $(grep "0," $TmpDir/Paral.status|sort)
do
    Status=$(   echo $StatusNode|cut -f1 -d,)
    NodeShort=$(echo $StatusNode|cut -f2 -d,)
    printf "\033[37;44m %-${PlusLong}s \033[m : %s\n" $NodeShort "$(head -1 $TmpDir/Paral-$NodeShort.log)"
done
echo "-------------------------------------------------------------------------"
Status=0
NbErreur=$(grep -v "0," $TmpDir/Paral.status|wc -l)
if [ $NbErreur -ne 0 ]
then
    PlusLong=$(grep -v "0," $TmpDir/Paral.status|cut -f2 -d,|wc -L)
    for StatusNode in $(grep -v "0," $TmpDir/Paral.status|sort)
    do
	Status=$(   echo $StatusNode|cut -f1 -d,)
	NodeShort=$(echo $StatusNode|cut -f2 -d,)
	printf "%-${PlusLong}s \033[31;47m Code retour $Status \033[m\n" $NodeShort
    done
    print ""
fi
print "\033[32;44m Final status \033[m : $Status"
print "\033[32;44m Total elapse \033[m : $(AfficheDuree $Debut_PC $Fin_PC)"
print ""

# Nettoyage des fichiers temporaires
# ----------------------------------
rm -rf $TmpDir
exit $Status
