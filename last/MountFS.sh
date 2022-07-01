#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls MountFS [User@]Pattern:[TargetDirectory] [MountDirectory]"
    print "  User           : User (optional)"
    print "  Pattern        : Pattern node name used by Execute, Connect, GetFile and PutFile commands."
    print "  MountDirectory : Directory where Mount points are created"
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

print ""
print "Current referential : \033[1;33;44m $(GetCurrentReferentiel) \033[m"
print ""

# Parsing des parametres
# ----------------------
ParsePattern $1
[ $CS_NbNode -eq 0 ] && echo "No matching servers (cf cls TestPattern)" && exit 1
[ $CS_TargetDir = "~/" ] && CS_TargetDir=""

MountDirectory=$PWD
if [ $# -gt 1 ]
then
    MountDirectory=$2
    [ ! -d $MountDirectory ] && mkdir -p $MountDirectory
    MountDirectory=$(cd $MountDirectory;pwd)
fi

cd $MountDirectory

for UserNode in $CS_UserNodeList
do
    ShortUserNode=$(echo $UserNode|cut -d. -f1)
    
    Debut=$(TopHorloge)
    printh "Creating mount point $PWD/$ShortUserNode on $UserNode:$CS_TargetDir ..."
    mkdir -p $ShortUserNode
    sshfs $UserNode:$CS_TargetDir $ShortUserNode
    printh "done (elapsed $(AfficheDuree $Debut $(TopHorloge)))"
done
print ""

exit 0
