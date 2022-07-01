#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#-------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls Ansible [User@]Pattern AnsibleCommand ..."
    print ""
    print "User            : User to use (cf cls TestPattern command)"
    print "Pattern         : Pattern node name used by Execute and Copy commands."
    print "                  Default value is remote home directory"
    print "AnsibleCommand  : ansible command and options."
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

TmpDir=/tmp/cls-ansible-$$
mkdir $TmpDir

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1

AnsibleParamOption=$(echo $*|cut -d' ' -f2-)

# Fabrication du fichier hosts ansible
echo $CS_UserNodeList|tr [' '] ['\n'] > $TmpDir/Hosts

# Controle de la presence interpreteur python
print "Checking ansible pre-requisites ..."
for UserNode in $CS_UserNodeList
do
    [ $(GetRemoteChar python $UserNode) != NotAvailable ] && continue

    printf "\033[31;47m Missing dependency \033[m : python parser unavailable for $UserNode\n"
    grep -v $UserNode $TmpDir/Hosts   > $TmpDir/Hosts.tmp
    mv   -f           $TmpDir/Hosts.tmp $TmpDir/Hosts
done
print "Done."

# Execution de la commande Ansible
ansible --inventory $TmpDir/Hosts all $AnsibleParamOption
Status=$?

# Fini
rm -rf $TmpDir
exit $Status
