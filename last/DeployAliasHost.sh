#!/bin/bash

# Controle
[ ! -f /etc/hosts.alias ] && echo "File /etc/host.alias not found" && exit 1

# Sauvegarde de la 1ere fois
[ ! -f /etc/hosts.noalias ] && cp /etc/hosts /etc/hosts.noalias

cat /etc/hosts.noalias /etc/hosts.alias > /etc/hosts

exit 0
