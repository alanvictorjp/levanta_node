#!/bin/bash
################################################################################
# Script do tipo daemon, fica analisando o processo node, caso caia por
# um motivo qualquer, sera levantado novamente, juntamente com todas as
# sessoes desponiveis em ${myzap_dir}/tokens/.
#
# Autor:        Alan Victor M. Leite
# Criacao:      10/07/2021
# Modificacao:  22/09/2021
################################################################################

# Variaveis locais
myzap_dir='/myzap/myzap/'
myzap_log='/myzap/myzap.log'
porta_node='3333'

# Variaveis constantes
################################################################################
named=$(basename $0)
node=$(which node)
curl=$(which curl)
logfile=/var/log/$named
null=/dev/null
pidfile=/var/run/$(basename $0).pid
myzap_dir=$(echo $myzap_dir | sed 's/\/$//')

# Cores
################################################################################
codigo="\033["
vermelhoClaro="1;31m";
verdeClaro="1;32m";
branco="1;37m";
finall="\033[0m"
eco_verde_claro() {	echo -ne "${codigo}${verdeClaro}$*${finall}"; }
eco_vermelho_claro() {	echo -ne "${codigo}${vermelhoClaro}$*${finall}"; }

# testes
################################################################################
[ ! -f $logfile ] && { touch $logfile ; }
[ -z $node ] && {  eco_vermelho_claro "\nNode nao instalado!\n"; exit ; }
[ -z $curl ] && {  eco_vermelho_claro "\nCurl nao instalado!\n"; exit ; }

################################################################################

# funcoes
################################################################################

_help() { eco_verde_claro "\n Argumento invalido!\n\n"; }
_is_running() { [[ -f $pidfile ]] && { return 0 ; } || { return 1 ; } }
_restart() { _stop ; _start; }

_stop() {
	_is_running && {
		kill -9 $(cat $pidfile) &> $null;
		sleep 0.5
		rm -rf $pidfile &> $null && {
			eco_verde_claro "\n $named parado!\n\n";
			return 0;
		} || {
			eco_vermelho_claro "\n PIDfile nao encontrado!\n\n"
			return 1;
		}
	} || {
		eco_vermelho_claro "\n $named nao estava rodando!\n\n";
		return 1;
	}
}

_start() {
	_is_running && {
		eco_vermelho_claro "\n $named estava rodando!\n\n";
		return 1;
	} || {
		_daemon;
		sleep 0.5
		eco_verde_claro "\n $named iniciado!\n\n";
		return 0;
	}
}


_status() {
	_is_running && {
		eco_verde_claro "\n $named esta rodando!\n";
		eco_verde_claro " PID: $(cat $pidfile)\n\n";
	} || {
		eco_vermelho_claro "\n $named nao esta rodando!\n\n";
	}
}
################################################################################

# daemon
################################################################################
_daemon() {

#	export LC_ALL=C
	while : ; do

			saida=$(ps x | grep -q 'node.*index.j[s]$' ; echo $?);
			if [[ $saida -ne '0' ]] ; then
				cd $myzap_dir ; $node --unhandled-rejections=strict index.js &> $myzap_log &
				sleep 5
				var=$(ls ${myzap_dir}/tokens/ | sed 's/\.data\.json//')
				for i in $var ; do
					$curl http://localhost:${porta_node}/start?sessionName=$i &> $null
					sleep 1
				done
			fi

			sleep 1

	done &
	echo $! > $pidfile
}

################################################################################
case $1 in
	start)		_start ;;
	stop)		_stop ;;
	restart)	_restart ;;
	status)		_status ;;
	*)			_help ;;
esac
################################################################################
