#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
# main
#

print ""
print "\033[34;47m FileSystem mounted via SSHFS \033[m"
print ""

mount|grep fuse.sshfs|while read Line
do
    RemoteRoot=$(echo $Line|cut -d' ' -f1|cut -d: -f2)
    if [ "$RemoteRoot" = "" ]
    then
	RemoteRoot="~/"
    elif [ $(echo $RemoteRoot|cut -c1) != "/" ]
    then
	RemoteRoot="~/$RemoteRoot"
    fi
    
    MountPoint=$(echo $Line|cut -d' ' -f3)
    print "Account / Server : $(echo $Line|cut -d' ' -f1|cut -d: -f1)"
    print "Remote directory : $RemoteRoot"
    print "Mount point      : $(echo $Line|cut -d' ' -f3)"
    print ""
done

print ""
exit 0
