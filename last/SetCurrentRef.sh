#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
# main
#

case $# in
    # -------------------------------------------------------------------------------------------
    # Affichage des referentiels disponibles
    0)
	print ""
	print "Available referential(s) :"

	cd $CS_DEPOT
	NodeDir=$(ls -1 */node/* 2>/dev/null | cut -f1 -d/ | sort | uniq)
	if [ "$NodeDir" != "" ]
	then
	    for Referentiel in $NodeDir
	    do
		printf "\t\033[34;47m%-20s\033[m : %3d node(s) defined.\n" \
		    $Referentiel $(ls -1 $Referentiel/node/*|wc -l)
	    done
	fi
	print ""

	cd
	if [ -L $CS_CURRENT ]
	then
	    print "Current referential : \033[1;33;44m $(GetCurrentReferentiel) \033[m"
	else
	    print "Current referential not defined."
	fi
	print ""
	;;
    # -------------------------------------------------------------------------------------------
    # Changement de referentiel courant
    1)
	print ""

	cd
	if [ -L $CS_CURRENT ]
	then
	    printf "Current referential .............. : \033[1;33;44m %s \033[m\n" \
		$(GetCurrentReferentiel)
	    
	else
	    print "Current referential not defined."
	fi

	if [ ! -d $CS_DEPOT/$1/node ]
	then
	    print ""
	    print "\033[33;41m Referential $1 not found. \033[m"
	    print ""
	    exit 0
	fi

	rm -f               $CS_CURRENT
	ln -sf $CS_DEPOT/$1 $CS_CURRENT

	if [ -L $CS_CURRENT ]
	then
	    printf "Current referential is now ....... : \033[1;33;44m %s \033[m\n" \
		$(GetCurrentReferentiel)
	else
	    print "Current referential is not defined."
	fi
	print ""
	;;
    # -------------------------------------------------------------------------------------------
    *)
	
esac

exit 0
