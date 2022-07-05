# install_oracle12c_centos7

script per automatizzare l'installazione di Oracle 12c  nella modalità silente

# Pre-requisiti
Essere in possesso del file linuxx64_12201_database.zip

# Nel file /etc/hosts deve essere settato l'indirizzo ip assegnato al server come nell'esempio di seguito

root@centos12c:~# cat /etc/hosts

192.168.1.10   centos12c centos12c.localdomain

::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Verificare che la versione del S.O. e del Kernel siano le seguenti
root@centos12c:~# uname -a

Linux centos12c.localdomain 3.10.0-1160.el7.x86_64 #1 SMP Mon Oct 19 16:18:59 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux

# Nel file install_oracle12c_centos7.sh dovete impostare il vostro indirizzo ip nella variabile ip e salvare il file.

# A questo punto potete copiare il file install_oracle12c_centos7.sh nella cartella /root ed eseguire i comandi seguenti come utente root

chmod +x install_oracle12c_centos7.sh

./install_oracle12c_centos7.sh

--------------------------------------------------------------------------------------------------------------------------------------

# CONNETTERSI AL DATABASE

Host: indirizzo ip del server Oracle 12c

Porta: 1521

Database: ORCL

utente: system

password: oracle123
