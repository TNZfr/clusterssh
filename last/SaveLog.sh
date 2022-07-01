#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
# main
#

if [ "$CS_ACCOUNTING" = "" ]
then
    print ""
    print "*** Accounting disabled, no files to be saved. ***"
    print ""
    exit 0
fi

CS_LOGTGZ=CLSLOG-$(uname -n)-${LOGNAME}-$(date +%Y%m%d-%Hm%Mm%Ss).tgz

cd $CS_ACCOUNTING
tar cfz $CS_LOGTGZ *.log && rm -f *.log

print ""
print "Archive file \033[33;44m $CS_ACCOUNTING/$CS_LOGTGZ \033[m created."
print ""

exit 0
