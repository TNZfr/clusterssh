#!/bin/bash

#------------------------------------------------------------------------------------------------
. _libkernel.sh
#------------------------------------------------------------------------------------------------
Aide ()
{
    print ""
    print "Syntax : cls GenAliasRef"
    print ""
}

#------------------------------------------------------------------------------------------------
# main
#

CurrentRef=$(GetCurrentReferentiel)

print ""
print "Alias deployment (\033[5;37;44msudo root access required\033[m)"
echo  "----------------"
print ""
print "1. Copy hosts.alias file to target server(s) using following commands"
print "cls PutFileOwner \033[1;3mNodePattern\033[m:/etc root $CS_DEPOT/$CurrentRef/hosts.alias"
print ""
print "2. Append hosts.alias file to /etc/hosts file on required server(s)"
print "cls ExecSudoScript \033[1;3mNodePattern\033[m root $CS_EXE/DeployAliasHost.sh"
print ""
print ""
print "Node alias generation"
echo  "---------------------"
print ""
print "Current referential : \033[1;33;44m $CurrentRef \033[m"
print ""

printf "Do you want to proceed (y/N) : "; read Reponse
print ""
[ "$(print $Reponse|tr [:upper:] [:lower:])" != "y" ] && exit 0

printh "Generating aliases ..."
NbAlias=0
for Node in $CS_CURRENT/node/*
do
    NodeName=$(head -1 $Node|cut -f2 -d@)
    Found=0
    nslookup $NodeName | while read Line
    do
	case $(print $Line|cut -f1 -d:) in
	    Name)
		NameFound=$(print $(print $Line|cut -f2 -d:))
		[ "$NameFound" = $NodeName ] && Found=1
		;;
	    
	    Address)
		if [ $Found -eq 1 ]
		then
		    print $(print $Line|cut -f2 -d:) $(basename $Node) "# CLS_Alias pour $NodeName" >> $CS_CURRENT/hosts.alias
		    (( NbAlias += 1 ))
		fi
		;;
	esac
    done
done
printh "$NbAlias alias generated."
printh "Cleaning $CS_DEPOT/$CurrentRef/hosts.alias ..."

# Suppression des doublons
# ------------------------
sort  $CS_CURRENT/hosts.alias | uniq > $CS_CURRENT/hosts.alias.tmp
mv -f $CS_CURRENT/hosts.alias.tmp      $CS_CURRENT/hosts.alias

printh "Done."
print  ""

exit 0

