#!/usr/bin/bash

################################################################
#                                                              #
#    Author: Andrea Barbiero <andrea.barbiero1@gmail.com>      #
#                                                              #
################################################################

#########################################################################################################################
#                                  IMPORTANTE PER IL CORRETTO FUNZIONAMENTO!                                            #
#                                                                                                                       #
# DAL VOSTRO TERMINALE ANDATE NEL PATH DOVE È PRESENTE IL FILE linuxx64_12201_database.zip E LANCIATE IL COMANDO        #
# SEGUENTE python3 -m http.server QUESTO COMANDO GENERA UN SERVER HTTP IN ASCOLTO ALL'INDIRIZZO http://0.0.0.0:8000/    #
# A QUESTO PUNTO DOVETE INSERIRE NELLA VARIABILE IP (ALLA RIGA 22) L'INDIRIZZO IP DEL VOSTRO SERVER HTTP                #
# Es. ip=192.168.1.5                      #
#                                                                                                                       #  
#    DOWNLOAD DEL FILE .ZIP PER L'INSTALLAZIONE                                                                         #
#    https://drive.google.com/file/d/1pBx2F0r8fTzb1fpUzdHluD6OE457Ylwc/view?usp=sharing                                 #
######################################################################################################################### 

# inizializzare questa variabile serve per permettere al comando wget nella riga 95 di fare il download del file .zip per l'installazione 
ip="inserite il vostro indirizzo ip"

# configuro il firewall per permettere al client di connettersi al DB tramite la porta 1521
firewall-cmd --zone=public --add-port=1521/tcp
firewall-cmd --reload
firewall-cmd --zone=home --change-interface=ens33
firewall-cmd --reload
firewall-cmd --set-default-zone=home
firewall-cmd --reload
firewall-cmd --zone=home --add-port=1521/tcp --permanent
firewall-cmd --reload
firewall-cmd --complete-reload
iptables-save | grep 1521



# Installo i pacchetti necessari e le librerie
yum install -y binutils.x86_64 compat-libcap1.x86_64 gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 \
glibc-devel.i686 glibc-devel.x86_64 ksh compat-libstdc++-33 libaio.i686 libaio.x86_64 libaio-devel.i686 libaio-devel.x86_64 \
libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.i686 libstdc++-devel.x86_64 libXi.i686 libXi.x86_64 \
libXtst.i686 libXtst.x86_64 make.x86_64 sysstat.x86_64 wget unzip net-tools smartmontools unixODBC unixODBC-devel elfutils-libelf-devel

# Creo l'utente Oracle con password "oracle" (in modo non interattivo) ed i gruppi dba e oinstall, poi aggiungo l'utente oracle a tutti e due i gruppi
groupadd oinstall
groupadd dba
useradd -m -g oinstall -G dba -p passwd -s /bin/bash -d /home/oracle oracle
echo "oracle:oracle" | chpasswd

# Aggiungo i seguenti parametri in /etc/sysctl.conf
echo 'kernel.sem = 250 32000 100 128' >> /etc/sysctl.conf
echo 'kernel.shmmax = 8589934592 #8GB' >> /etc/sysctl.conf
echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max = 4194304' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 1048576' >> /etc/sysctl.conf
echo 'fs.aio-max-nr = 1048576' >> /etc/sysctl.conf
echo 'fs.file-max = 6815744' >> /etc/sysctl.conf
echo 'vm.hugetlb_shm_group = 1001' >> /etc/sysctl.conf

# Modifico il file /etc/security/limits.conf aggiungendo i seguenti parametri:
echo '--shell limits for users oracle' >> /etc/security/limits.conf
echo 'oracle soft nofile 1024' >> /etc/security/limits.conf
echo 'oracle hard nofile 65536' >> /etc/security/limits.conf
echo 'oracle soft nproc 2047' >> /etc/security/limits.conf
echo 'oracle hard nproc 16384' >> /etc/security/limits.conf
echo 'oracle soft stack 10240' >> /etc/security/limits.conf
echo 'oracle hard stack 32768' >> /etc/security/limits.conf

sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config

# Aggiungo quanto segue ad /etc/profile:
cat <<EOT >> /etc/profile
if [ $USER = "oracle" ]; then
  if [ $SHELL = "/bin/ksh" ]; then
    ulimit -p 16384
    ulimit -n 65536
  else
    ulimit -u 16384 -n 65536
  fi
fi
EOT


# Creo i path per l'installazione
mkdir /u01

# Assegno l'utente oracle come proprietario del path e come gruppo oinstall in modo recursivo tramite -R
chown -R oracle:oinstall /u01/

# Mi sposto nel path /home/oracle
cd /home/oracle/

# Scarico il pacchetto di installazione nella directory /home/oracle
wget http://${ip}:8000/linuxx64_12201_database.zip

# Assegno l'utente oracle come proprietario del file e come gruppo oinstall
chown -R oracle:oinstall /home/oracle/linuxx64_12201_database.zip

# Estraggo il contenuto del file .zip
unzip linuxx64_12201_database.zip

# Assegno l'utente oracle come proprietario del path e come gruppo oinstall in modo tale che anche i file estratti hanno i stessi permessi
chown -R oracle:oinstall /home/oracle/

# Scrivo le variabili d'ambiente per iniziare l'installazione
cat <<EOT >> /home/oracle/.bash_profile
export ORACLE_BASE=/u01/app/oracle
unset ORACLE_HOME
unset TNS_ADMIN
EOT

# Modifico tramite sed il file con i parametri per l'installazione
sed -i 's/oracle.install.option=/oracle.install.option=INSTALL_DB_SWONLY/g' /home/oracle/database/response/db_install.rsp
sed -i 's/UNIX_GROUP_NAME=/UNIX_GROUP_NAME=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's|INVENTORY_LOCATION=|INVENTORY_LOCATION=/u01/app/oraInventory|g' /home/oracle/database/response/db_install.rsp
sed -i 's|ORACLE_HOME=|ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1|g' /home/oracle/database/response/db_install.rsp
sed -i 's|ORACLE_BASE=|ORACLE_BASE=/u01/app/oracle/product|g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.InstallEdition=/oracle.install.db.InstallEdition=EE/g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.OSDBA_GROUP=/oracle.install.db.OSDBA_GROUP=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.OSOPER_GROUP=/oracle.install.db.OSOPER_GROUP=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.OSBACKUPDBA_GROUP=/oracle.install.db.OSBACKUPDBA_GROUP=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.OSDGDBA_GROUP=/oracle.install.db.OSDGDBA_GROUP=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.OSKMDBA_GROUP=/oracle.install.db.OSKMDBA_GROUP=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's/oracle.install.db.OSRACDBA_GROUP=/oracle.install.db.OSRACDBA_GROUP=oinstall/g' /home/oracle/database/response/db_install.rsp
sed -i 's/SECURITY_UPDATES_VIA_MYORACLESUPPORT=/SECURITY_UPDATES_VIA_MYORACLESUPPORT=false/g' /home/oracle/database/response/db_install.rsp
sed -i 's/DECLINE_SECURITY_UPDATES=/DECLINE_SECURITY_UPDATES=true/g' /home/oracle/database/response/db_install.rsp

# Da utente Oracle lancio l'installazione
su - oracle<<EOF
./database/runInstaller -silent -responseFile /home/oracle/database/response/db_install.rsp -ignoreSysPrereqs -showProgress
sleep 3m
exit
EOF

# Eseguo gli script indicati durante l'installazione di oracle12c
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/12.2.0/dbhome_1/root.sh

# Imposto le variabili d'ambiente definitive per l'utente oracle
sed -i 's|unset ORACLE_HOME||g' /home/oracle/.bash_profile
sed -i 's/unset TNS_ADMIN//g' /home/oracle/.bash_profile

cat <<EOT >> /home/oracle/.bash_profile
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1
export ORACLE_SID=ORCL
export ORATAB=/etc/oratab
export NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
export TZ=Europe/Rome
unset TNS_ADMIN
export PATH=/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/u01/app/oracle/product/12.2.0/dbhome_1/bin
EOT

# Lancio il comando per la creazione del database
su - oracle<<EOF
dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbName ORCL -sid ORCL -createAsContainerDatabase false -emConfiguration NONE -sysPassword oracle123 -systemPassword oracle123 -datafileDestination /u01/app/oradata -storageType FS -characterSet AL32UTF8 -totalMemory 2048 -recoveryAreaDestination /u01/FRA -sampleSchema true
EOF

# Avvio il listner 
runuser -l oracle -c 'lsnrctl start'

# Verifico che la connessione al DB è avvenuta con successo
runuser -l oracle -c 'sqlplus /nolog<<EOF
connect /as sysdba'

# Elimino le password per SYS e SYSTEM dalle variabili d'ambiente
sed -i 's|export sysPass=oracle123||g' /home/oracle/.bash_profile
sed -i 's|export systemPass=oracle123||g' /home/oracle/.bash_profile

# Quando il programma di installazione termina dobbiamo attendere circa 1/2 minuti per connetterci con un client al db, perchè Oracle stà avviando l'istanza
echo 'Ci siamo quasi...'
sleep 2m

echo 'Ok, ora puoi provare a connetterti al DB'


