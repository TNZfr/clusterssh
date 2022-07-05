#!/bin/bash

#------------------------------------------------------------------------------------------------
function AcctFile
{
CommandName=$1

    # --------------------------------
    # Gestion de la LOG de la commande
    # --------------------------------
    CS_FICACC="/dev/null"
    if [ -n "$CS_ACCOUNTING" ] && [ -d $CS_ACCOUNTING ]
    then
	CS_FICACC=$CS_ACCOUNTING/$(date +%Y%m%d-%Hh%Mm%Ss)-$CommandName.log
	printf "\n\033[33;44m Command \033[m : clussh $Commande $Parametre\n\n" > $CS_FICACC
	chmod a+rw $CS_FICACC
    fi
}

#------------------------------------------------------------------------------------------------
function LoadConfiguration
{
    CS_RC=~/.clussh/_clusshrc.sh

    if [ ! -f $CS_RC ]
    then
	echo ""
	echo " +------------------------------------------------------+"
	printf " | \033[1;5;33;41m        *** Missing configuration file ***          \033[m |\n"
	echo " +------------------------------------------------------+"
	echo " | Run following command to solve the issue :           |"
	printf " | \033[34;47mcls Configure\033[m                                        |\n"
	echo " +------------------------------------------------------+"
	echo ""
	exit
    fi

    # Chargement de la configuration
    . $CS_RC

    # Gestion multi utilisateurs
    if [ ! -L $CS_CURRENT ]
    then
	Last=$(cd $CS_LOCAL; ls -1dtr ref-* 2>/dev/null|tail -1)
	if [ "$Last" != "" ]
	then
	    ln -s $(readlink -f $CS_LOCAL/$Last) $CS_CURRENT
	    for RefPID in $(cd $CS_LOCAL; ls -1d ref-*|cut -d'-' -f2)
	    do
		[ ! -d /proc/$RefPID ] && rm -f $CS_LOCAL/ref-$RefPID
	    done
	fi
    fi
}

#-------------------------------------------------------------------------------
function RunCommand
{
    CommandName=$1

    if [ $# -eq 2 ] && [ $2 = NO_ACCOUNTING ]
    then
	CS_FICACC="/dev/null"
    else
	# Mise en oeuvre accounting
	AcctFile ${CommandName}
    fi

    if [ $CS_FICACC = "/dev/null" ]
    then
	${CommandName}.sh $Parametre
	Status=$?
    else
	StatusFile=/tmp/status-$$
	(${CommandName}.sh $Parametre;echo $? > $StatusFile) | tee -a $CS_FICACC
	Status=$(cat $StatusFile; rm -f $StatusFile)
    fi

    return $Status
}

#-------------------------------------------------------------------------------
# main
#

if [ $# -eq 0 ]
then
    echo  ""
    printf " \033[30;42m CLS v5.2 \033[m : Cluster management using SSH\n"
    echo  ""
    echo  ""
    printf " \033[37;44m Syntax   \033[m : cls Command Parameters ...\n"
    echo  ""
    echo  ""
    printf "\033[34;47mTool management\033[m\n"
    echo              "---------------"
    echo "Configure              : Set tool configuration parameters"
    echo "TestRemoteCommand (TRC): Generate capacities database for remote nodes"
    echo "SaveLog            (SL): Save logs in directory defined by CS_ACCOUNTING"
    echo ""
    printf "\033[34;47mReferential management\033[m\n"
    echo              "----------------------"
    echo "SetCurrentRef    (SR): Set current referential"
    echo "GenerateRef      (GR): Compile CSV to usable format"
    echo "GenAliasRef     (GAR): Generate hosts.alias for referential"
    echo "CheckRef         (CR): Check referential nodes"
    echo ""
    printf "\033[34;47mOperator key management\033[m\n"
    echo              "-----------------------"
    echo "DistributeKey    (DK): Distribute RSA public key"
    echo "CheckKey         (CK): Check RSA public key distribution"
    echo "RevokeKey            : Suppress RSA public key from the referential"
    echo ""
    printf "\033[34;47mPublic Keys management\033[m\n"
    echo              "----------------------"
    echo "PubKeyAdd       (PKA): Add a user public key to the referential ActiveKey file."
    echo "PubKeyRevoke    (PKR): Add a user public key to the referential RevokeKey file."
    echo "PubKeySynchro   (PKS): Synchronize all remote authorized_keys with ActiveKey and RevokeKey files."
    echo "PubKeyList      (PKL): List remote or local access definition."
    echo "PubKeyFinger    (PKF): Update public key fingerprint database (Cf PubKeyJournal)"
    echo "PubKeyJournal   (PKJ): List user connections on selected nodes."
    echo ""
    echo "PubKeyDeploy    (PKD): Deploy public key from file(s)"
    echo "PubKeyUndeploy  (PKU): Undeploy public key from file(s)"
    echo ""
    printf "\033[34;47mCommon usage\033[m\n"
    echo              "------------"
    echo "List             (LS): List all alias of current referential"
    echo "TestPattern      (TP): Test node pattern(s) syntax on current referential"
    echo ""
    echo "Connect          (CO): Connect on the selected node (only one)"
    echo "GetFile          (GF): Get files from selected nodes"
    echo "PutFile          (PF): Put files to selected nodes"
    echo "ExecuteCommand   (EC): Execute command on selected nodes"
    echo "ExecuteScript    (ES): Execute local script on selected nodes"
    echo ""
    printf "\033[34;47mAdvanced commands\033[m\n"
    echo              "-----------------"
    echo "GetGlobalInfo   (GGI): Synthesis of 1 info line"
    echo "Ansible         (ANS): Invoke ansible tools using ClusterSSH dynamic inventory"
    echo ""
    echo "TarCompress     (TCO): Generate local archives of files from selected nodes"
    echo "TarExtract      (TEX): Extract an archive on selected nodes"
    echo "Duplicate       (DUP): Directory(ies) duplication on selected nodes"
    echo ""
    echo "ListFS          (LFS): List all local FS mounted via SSHFS"
    echo "MountFS         (MFS): Mount a local FS for each selected nodes (via SSHFS)"
    echo "UnmountFS       (UFS): Unmount local FS (mounted via SSHFS)"
    echo ""
    printf "\033[34;47mComposed and sudo commands\033[m\n"
    echo              "--------------------------"
    echo "ParalCommand     (PC),  ParalScript      (PS),  ExecSudoCommand  (ESC), ParalSudoCommand (PSC)"
    echo "ExecSudoScript   (ESS), ParalSudoScript  (PSS), GetFileOwner     (GFO), PutFileOwner     (PFO)"
    echo "ParalTarCompress (PTC), ParalTarExtract  (PTE)"
    echo ""
    printf "\033[34;47mNode pattern syntax\033[m : [Username@]NodePattern1[,NodePatternX][:RemoteDir]\n"
    echo              "-------------------"
    echo "    Username    : Force the usernane used for command. Default is the first username defined."
    echo "                  Reserved keyword all specify all accounts defined on selected nodes."
    echo "    NodePattern : Beginning of NodeName accepting shell wilcard characters."
    echo "                  Reserved keyword \"all\" select all defined nodes in current referential."
    echo "    RemoteDir   : Used for PutFile command, corresponding to scp command syntax"
    echo ""
    exit 0
fi

# ------------------------------------------------------
# Cas des AIX : rajout du repertoire GNU quand il existe
# ------------------------------------------------------
AIX_GNU_BIN=/opt/freeware/bin
[ -d $AIX_GNU_BIN ] && export PATH=$AIX_GNU_BIN:$PATH

# -------------------------------------
# Definition du repertoire des binaires
# -------------------------------------
export CS_EXE=$(dirname $(readlink -f $0))
export PATH=$CS_EXE:$PATH

# ---------------------
# Parsing des commandes
# ---------------------
Parametre=""
Commande=$(echo $1|tr [:upper:] [:lower:])
[ $# -gt 1 ] && Parametre="$(echo $*|cut -f2- -d' ')"

# Cette commande cree le fichier _clusshrc.sh
# --------------------------------------------
if [ "$Commande" = "configure" ]
then
    Configure.sh $Parametre
    exit $?
fi

# --------------------------------
# Chargement des variables locales
# --------------------------------
LoadConfiguration

case $Commande in

    # Commandes pour le referentiel
    # -----------------------------
    "setcurrentref" |"sr" ) RunCommand SetCurrentRef ;;
    "generateref"   |"gr" ) RunCommand GenerateRef   ;;
    "genaliasref"   |"gar") RunCommand GenAliasRef   ;;
    "checkref"      |"cr" ) RunCommand CheckRef      ;;

    # Commandes pour les cles SSL
    # ---------------------------
    "distributekey" |"dk") RunCommand DistributeKey ;;
    "checkkey"      |"ck") RunCommand CheckKey      ;;
    "revokekey"          ) RunCommand RevokeKey     ;;

    # Commandes pour la gestion des cles publiques
    # --------------------------------------------
    "pubkeyadd"     |"pka") RunCommand PubKeyAdd      ;;
    "pubkeyrevoke"  |"pkr") RunCommand PubKeyRevoke   ;;
    "pubkeysynchro" |"pks") RunCommand PubKeySynchro  ;;
    "pubkeylist"    |"pkl") RunCommand PubKeyList     ;;
    "pubkeyfinger"  |"pkf") RunCommand PubKeyFinger   ;;
    "pubkeyjournal" |"pkj") RunCommand PubKeyJournal  ;;
    "pubkeydeploy"  |"pkd") RunCommand PubKeyDeploy   ;;
    "pubkeyundeploy"|"pku") RunCommand PubKeyUndeploy ;;

    # Commandes utilisateur
    # ---------------------
    "list"            |"ls") TestPattern.sh all; Status=$? ;;
    "testpattern"     |"tp") RunCommand TestPattern NO_ACCOUNTING;;
    "getfile"         |"gf") RunCommand GetFile     ;;
    "putfile"         |"pf") RunCommand PutFile     ;;
    "connect"         |"co") RunCommand Connect     NO_ACCOUNTING;;

    "executecommand"  |"ec") RunCommand ExecuteCommand ;;
    "paralcommand"    |"pc") RunCommand ParalCommand   ;;
    "executescript"   |"es") RunCommand ExecuteScript  ;;
    "paralscript"     |"ps") RunCommand ParalScript    ;;

    # Commandes avancees
    # ------------------
    "execsudocommand" |"esc") RunCommand ExecuteSudoCommand ;;
    "paralsudocommand"|"psc") RunCommand ParalSudoCommand   ;;
    "execsudoscript"  |"ess") RunCommand ExecuteSudoScript  ;;
    "paralsudoscript" |"pss") RunCommand ParalSudoScript    ;;
    "getglobalinfo"   |"ggi") RunCommand GetGlobalInfo      ;;
    "getfileowner"    |"gfo") RunCommand GetFileOwner       ;;
    "putfileowner"    |"pfo") RunCommand PutFileOwner       ;;
    "ansible"         |"ans") RunCommand Ansible            ;;
    
    "tarcompress"     |"tco") RunCommand TarCompress        ;;
    "tarextract"      |"tex") RunCommand TarExtract         ;;
    "duplicate"       |"dup") RunCommand Duplicate          ;;
    "paraltarcompress"|"ptc") RunCommand ParalTarCompress   ;;
    "paraltarextract" |"pte") RunCommand ParalTarExtract    ;;

    "listfs"          |"lfs") RunCommand ListFS             ;;
    "mountfs"         |"mfs") RunCommand MountFS            ;;
    "unmountfs"       |"ufs") RunCommand UnmountFS          ;;
    
    # Les autres commandes
    # --------------------
    "testremotecommand"|"trc") RunCommand TestRemoteCommand    ;;
    "savelog"          |"sl" ) RunCommand SaveLog NO_ACCOUNTING;;

    *)
	echo "Commande $1 inconnue."
esac

exit $Status
