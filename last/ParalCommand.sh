#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls ParalCommand [User@]Pattern Command"
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

SSHCommand="$(echo $*|cut -f2- -d' ')"

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
    User=$(echo $UserNode|cut -d@ -f1)
    Node=$(echo $UserNode|cut -d@ -f2)
    UserNodeShort=$(echo $UserNode|cut -f1 -d.)
    CS_ParalLog=$TmpDir/Paral-$UserNodeShort.log
    (
	(
	    LogParalEntete_debut $Node $User $SSHCommand

	    ssh -q $UserNode "$SSHCommand"
	    Status=$?

	    LogParalEntete_fin

	    echo "$Status,$UserNodeShort" >> $TmpDir/Paral.status

	) >>  $CS_ParalLog 2>&1 
	cat   $CS_ParalLog
	rm -f $CS_ParalLog
    ) &
done

# attente de fin des traitements pour la consolidation des status
wait
Fin_PC=$(TopHorloge)

echo "-------------------------------------------------------------------------"
Status=0
NbErreur=$(grep -v "0," $TmpDir/Paral.status|wc -l)
if [ $NbErreur -ne 0 ]
then
    for StatusNode in $(grep -v "0," $TmpDir/Paral.status|sort)
    do
	Status=$(   echo $StatusNode|cut -f1 -d,)
	NodeShort=$(echo $StatusNode|cut -f2 -d,)
	print "$NodeShort \033[31;47m Code retour $Status \033[m" 
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
