#!/bin/bash

#------------------------------------------------------------------------------------------------
CS_GetCurrentReferentiel ()
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
CS_GetRealNodeName ()
{
    Node=$1
    print $(head -1 $CS_CURRENT/node/$Node|cut -f2 -d@)
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
# Init API
#
