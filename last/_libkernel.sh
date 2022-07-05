#!/bin/bash

#------------------------------------------------------------------------------------------------
function print
{
    # Migration shell : ksh -> bash
    printf "$*\n"
}

#------------------------------------------------------------------------------------------------
function printh
{
    print "$(date +%d/%m/%Y-%Hh%Mm%Ss) : $*"
}

#------------------------------------------------------------------------------------------------
function SupprimeFichierTemp
{
    rm -f /tmp/clussh*-$$.*
}

#------------------------------------------------------------------------------------------------
GetCurrentReferentiel ()
{
    ReferentielDirectory=$(echo $(ls -l $CS_CURRENT))
    if [ "$(echo $ReferentielDirectory|cut -f9 -d' ')"  = "->" ]
    then
	ReferentielDirectory=$(echo $ReferentielDirectory|cut -f10 -d' ')
    else
	ReferentielDirectory=$(echo $ReferentielDirectory|cut -f11 -d' ')
    fi
    print $(basename $ReferentielDirectory)
}

#------------------------------------------------------------------------------------------------
GetRealNodeName ()
{
    Node=$1
    print $(cat $CS_CURRENT/node/$Node|head -1|cut -f2 -d@)
}

#------------------------------------------------------------------------------------------------
ParsePattern ()
{
# ------------------------------------------------------
# Variables renseignees par cette fonction
# ------------------------------------------------------
# CS_User        : utilisateur selectionne
# CS_PatternList : Liste des selections
# CS_NodeList    : Liste des serveurs correspondants
# CS_NbNode      : Nombre de serveurs correspondants
# CS_UserNodeList: Liste des elements de connexion (user@node)
# CS_TargetDir   : Repertoire cible
# CS_CurrentDir  : Repertoire avant appel de la fonction
# ------------------------------------------------------

    # Initialisation des variables
    CS_User=""
    CS_PatternList=""
    CS_NodeList=""
    CS_NbNode=0
    CS_UserNodeList=""
    CS_TargetDir="~/"
    CS_CurrentDir=$PWD

    # Si pas de referentiel courant -> SORTIE
    [ ! -L $CS_CURRENT ] && printf "\033[31mNo current referetial defined\033[m, Cf cls SetCurrentRef\n" && exit 1

    # Liste des serveurs repondant au pattern
    cd $CS_CURRENT/node

    Param1=$(echo $1)
    CS_TargetDir=$(echo $Param1|cut -f2 -d:)
    if [ "$CS_TargetDir" != "$Param1" ]
    then 
	Param1=$(echo $Param1|cut -f1 -d:)
    else
	CS_TargetDir="~/"
    fi

    CS_User=$(       echo $Param1|cut -f1 -d@)
    CS_PatternList=$(echo $Param1|cut -f2 -d@)
    [ "$CS_User" = "$CS_PatternList" ] && CS_User=""

    CS_PatternList=$(echo $CS_PatternList|tr [','] [' '])

    # Recherche des serveurs cible
    for Pattern in $CS_PatternList
    do
	if [ $(echo $Pattern|tr [:upper:] [:lower:]) = "all" ]
	then
	    CS_NodeList=*
	    break
	fi
	CS_NodeList="$CS_NodeList $(ls -1 $Pattern* 2>/dev/null)"
    done
    CS_NodeList=$(echo $CS_NodeList)

    if [ "$CS_NodeList" = "" ]
    then
	cd $CS_CurrentDir
	return
    fi
    CS_NbNode=$(ls -1 $CS_NodeList 2>/dev/null|wc -l)

    # Definition des user@node
    if [ "$CS_User" = "" ]
    then
	CS_UserNodeList=$(eval echo $(head -1 $CS_NodeList|grep @))
	cd $CS_CurrentDir
	return	
    fi    

    if [ $(echo $CS_User|tr [:upper:] [:lower:]) = "all" ]
    then
	CS_UserNodeList=$(cat $CS_NodeList|tr ['\n'] [' '])
	cd $CS_CurrentDir
	return	
    fi

    for Node in $CS_NodeList
    do
	UserNodeList="$(eval echo $(cat $Node))"
	if [ $(echo $CS_User|tr [:upper:] [:lower:]) = all ]
	then
	    UserNode=$(echo $UserNodeList)
	else
	    UserNode=$(echo $UserNodeList|tr [' '] ['\n']|grep ^$CS_User@)
	fi
	CS_UserNodeList="$CS_UserNodeList $UserNode"
    done
    CS_UserNodeList=$(echo $CS_UserNodeList|sort|uniq)

    cd $CS_CurrentDir
}

#------------------------------------------------------------------------------------------------
TopHorloge ()
{
    date +%s.%N
}

#------------------------------------------------------------------------------------------------
AfficheDuree ()
{
    # Parametres au format SECONDE.NANO (date +%s.%N)
    _Debut=$1
    _Fin=$2

    AD_Duree=$(echo "scale=6; $_Fin - $_Debut"|bc)
    [ "${AD_Duree:0:1}" = "." ] && AD_Duree="0$AD_Duree"
    
    _Seconde=$(echo $AD_Duree|cut -d. -f1)
    _Milli=$(  echo $AD_Duree|cut -d. -f2)
    _Milli=${_Milli:0:3}

    (( _Jour   = $_Seconde / 86400 )) ; (( _Seconde = $_Seconde % 86400 ))
    (( _Heure  = $_Seconde /  3600 )) ; (( _Seconde = $_Seconde %  3600 ))
    (( _Minute = $_Seconde /    60 )) ; (( _Seconde = $_Seconde %    60 ))

    [ $_Jour   -gt 0 ] && printf "${_Jour}j ${_Heure}h ${_Minute}m ${_Seconde}s.$_Milli\n" && return
    [ $_Heure  -gt 0 ] && printf "${_Heure}h ${_Minute}m ${_Seconde}s.$_Milli\n" && return
    [ $_Minute -gt 0 ] && printf "${_Minute}m ${_Seconde}s.$_Milli\n" && return
    echo "${_Seconde}s.$_Milli"
}

#------------------------------------------------------------------------------------------------
LogParalEntete_debut ()
{
    echo  "-------------------------------------------------------------------------"
    print "\033[34;47m Node    \033[m : $1"
    print "\033[34;47m User    \033[m : $2"
    print "\033[34;47m Command \033[m : $(echo $*|cut -d' ' -f3-)"
    print "\033[34;47m Begin   \033[m : $(date +'%d/%m/%Y %Hh%Mm%Ss')"
    print ""
    LogParal_debut=$(TopHorloge)
}

#------------------------------------------------------------------------------------------------
LogParalEntete_fin ()
{
    LogParal_fin=$(TopHorloge)
    print ""
    print "\033[34;47m Status  \033[m : $Status"
    print "\033[34;47m End     \033[m : $(date +'%d/%m/%Y %Hh%Mm%Ss') ($(AfficheDuree $LogParal_debut $LogParal_fin))"
}

#------------------------------------------------------------------------------------------------
GetRemoteChar ()
{
    _Commande=$1
    _UserNode=$2

    # Repertoire de stockage des caracteristiques
    CS_CHARDIR=$CS_CURRENT/char
    [ ! -d $CS_CHARDIR ] && mkdir -p $CS_CHARDIR

    # Fichier de stockage des caracteristiques
    CS_CHARDAT=$CS_CHARDIR/$(echo $_UserNode|cut -d@ -f2)
    [ ! -f $CS_CHARDAT ] && touch $CS_CHARDAT

    _Recherche=$(grep $_Commande $CS_CHARDAT)
    if [ "$_Recherche" = "" ]
    then
	_Remote=$(ssh -q $_UserNode which $_Commande 2>/dev/null)
	[ "$(echo $_Remote|cut -c1)" != "/" ] && _Remote="NotAvailable"
	
	echo  $_Remote
	echo "$_Commande $_Remote" >> $CS_CHARDAT
    else
	echo $_Recherche|cut -d' ' -f2-
    fi
}

#------------------------------------------------------------------------------------------------
GetLocalChar ()
{
    _Commande=$1

    _Recherche=$(which $_Commande 2>/dev/null)
    [ "${_Recherche:0:1}" != "/" ] && _Recherche="NotAvailable"
    echo $_Recherche
}
