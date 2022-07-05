#!/bin/bash
#
#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Saisie ()
{
NomVariable=$1
Defaut=$2
Commentaire=$3

    print  "\033[34;47mIndication .............. :\033[m $Commentaire"
    print  "\033[34;47mDefault value ........... :\033[m $Defaut"
    printf "\033[34;47mValue for %-15s :\033[m " $NomVariable; read Valeur
    print ""

    if [ "$Valeur" = "" ]
    then
	print "export $NomVariable=\"$Defaut\"" >> $CS_RC
    else
	print "export $NomVariable=\"$Valeur\"" >> $CS_RC
    fi
}

#------------------------------------------------------------------------------------------------
TestCreateDirectory ()
{
    if [ ! -d $1 ]
    then
	printh "Creating directory : \033[34;47m$1\033[m"
	mkdir -p $1
    fi
}

#------------------------------------------------------------------------------------------------
CreateConfiguration ()
{
    if [ ! -d $CS_RCDIR ]
    then
	mkdir -m 700 $CS_RCDIR
    fi
    > $CS_RC
    chmod 700 $CS_RC

    print "#!/bin/bash
#-------------------------------------
# Variables definies par l'utilisateur
# ------------------------------------" >> $CS_RC

    Saisie CS_DEPOT      \$HOME/clussh        "Referential database"
    Saisie CS_ACCOUNTING ""                   "Accounting directory"

    print "
#-----------------------------------------------------------
# Variables deduites ou variables internes non parametrables
#-----------------------------------------------------------
export CS_LOCAL=$CS_RCDIR
export CS_CURRENT=$CS_RCDIR/ref-\$PPID
export CS_MODULE=\$CS_EXE/module
" >> $CS_RC

    printh "$CS_RC created."

    printh "Directories verification ..."
    . $CS_RC
    TestCreateDirectory $(eval echo $CS_DEPOT)
    printh "Done."
}

#------------------------------------------------------------------------------------------------
DisplayConfiguration ()
{
    print ""
    print "\033[1m*** ----------------------------------------------------------------------------\033[m"
    print "\033[1m*** Inside RC file \033[34;47m$CS_RC\033[m"
    print "\033[1m*** ----------------------------------------------------------------------------\033[m"
    cat $CS_RC | while read ligne
    do
	print "\033[1m***\033[m $ligne"
    done
    print "\033[1m*** ----------------------------------------------------------------------------\033[m"
}

#------------------------------------------------------------------------------------------------
# main
#
CS_RCDIR=$HOME/.clussh
CS_RC=$CS_RCDIR/_clusshrc.sh

# En cas de RESET, on resaisie tous les parametres
# ------------------------------------------------
if [ "$1" = "RESET" ]
then
    rm -f $CS_RC
fi

if [ ! -x $CS_RC ]
then
    CreateConfiguration
    . $CS_RC

    NbModule=$(echo $(ls -1 $CS_MODULE/*_Configure.sh 2>/dev/null|wc -l))
    if [ $NbModule -gt 0 ]
    then
	printh "$NbModule configuration script(s) found."
	for Script in $(ls -1 $CS_MODULE/*_Configure.sh)
	do
	    printh "Launch configuration script for type $(basename $Script|cut -f1 -d_)"
	    $Script
	done
    fi
fi

DisplayConfiguration
exit 0
