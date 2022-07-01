#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls TestPattern [User@]Pattern [full|env]"
    print "User    : User to test (optional)"
    print "Pattern : Pattern node name used by Execute, Connect, GetFile and PutFile commands."
    print "full    : Optional, list available and unavailable nodes for a user."
    print "env     : Optional, list CS_ variables (for api use)"
    print ""
}

#------------------------------------------------------------------------------------------------
DisplayEnv ()
{
    print ""
    print "Selected user     : CS_User=$CS_User"
    print "Pattern list      : CS_PatternList=$CS_PatternList"
    print "Server list       : CS_NodeList=$CS_NodeList"
    print "Server quantity   : CS_NbNode=$CS_NbNode"
    print "Connexion strings : CS_UserNodeList=$CS_UserNodeList"
    print "Target directory  : CS_TargetDir=$CS_TargetDir"
    print ""
}

#------------------------------------------------------------------------------------------------
DisplayList ()
{
Message="$1"; shift
Liste="$*"

  NbNode=0
  [ "$Liste" != "" ] && NbNode=$(ls -1 $Liste|wc -l)
  print "$Message : $NbNode node(s)"
  if [ "$Liste" = "" ]
  then
      print ""
      return
  fi

  if [ "$FullDisplay" = "TRUE" ]
  then
      LgMax=$(ls -1 $Liste|wc -L)
      for Node in $Liste
      do
	  printf "%-${LgMax}.${LgMax}s : %s\n" $Node $(head -1 $Node|cut -f2 -d@)
      done
  else
      ls $Liste
  fi
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

# Analyse des parametres
# ----------------------
ParsePattern $1
FullDisplay="FALSE"
[ $# -gt 1 ] && [ $(echo $2|tr [:upper:] [:lower:]) = full ] && FullDisplay="TRUE"
[ $# -gt 1 ] && [ $(echo $2|tr [:upper:] [:lower:]) = env  ] && DisplayEnv && exit 0

cd $CS_CURRENT/node

print ""
print "Current referential : \033[1;33;44m $(GetCurrentReferentiel) \033[m"
print ""

print "\033[47;34m Pattern              \033[m : $CS_PatternList"

if [ $CS_NbNode -eq 0 ]
then
    print ""
    exit 0
fi

# Utilisateur non precise, on liste tout
# --------------------------------------
if [ "$CS_User" = "" ] || [ $(echo $CS_User|tr [:upper:] [:lower:]) = all ]
then
    print "\033[47;34m Node(s) found        \033[m : $CS_NbNode"
    print ""
    LgMax=$(ls -1 $CS_NodeList|wc -L)
    for Node in $CS_NodeList
    do
	RealServer=$(head -1 $Node|cut -f2 -d@)
	printf "%-${LgMax}.${LgMax}s : %s\n" $Node "$(eval echo $(cat $Node|cut -f1 -d@)) ... $RealServer"
    done
    print ""
    exit 0
fi

# Utilisateur precise, on liste que les serveurs concernes
# --------------------------------------------------------
print "\033[47;34m Node(s) found        \033[m : $CS_NbNode"
print "\033[47;34m Account selected     \033[m : $CS_User"
print ""
[ $CS_NbNode -eq 0 ] && exit 0 

MatchList=""
UnmatchList=""
for Node in $CS_NodeList
do
    User=$(eval echo $(cat $Node)|tr [' '] ['\n']|grep ^$CS_User@|cut -f1 -d@)
    if [ "$User" = "$CS_User" ]
    then
	MatchList="$MatchList $Node"
    else
	UnmatchList="$UnmatchList $Node"
    fi
done

DisplayList "\033[47;34m Available on     \033[m" $MatchList
DisplayList "\033[47;31m Not available on \033[m" $UnmatchList

exit 0
