#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls UnmountFS MountPoint ..."
    print "  MountPoint : Active SSHFS mountpoint to be unmounted"
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

UnmountList=$*

if [ "$(echo $UnmountList|tr [:upper:] [:lower:])" = "all" ]
then
    UnmountList=$(mount|grep fuse.sshfs|cut -d' ' -f3)
fi

for MountPoint in $UnmountList
do
    MountPoint=$(readlink -f $MountPoint)

    if [ "$(mount|grep fuse.sshfs|grep $MountPoint)" = "" ]
    then
	print "\033[34;47m $MountPoint \033[m is not an active SSH FileSystem."
	continue
    fi
    fusermount -u $MountPoint && rmdir $MountPoint
done
exit 0
