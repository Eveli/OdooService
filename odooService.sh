#!/bin/bash
#

# ENTER DATA MANUALLY

#NOMBRE_INSTANCIA="nueva"
#VERSION_ODOO=11
#PUERTO_PG=5439
#PUERTO_XMLRPC=8076
#ADMIN_PASSWD=MIRNKAD22OU

# REQUEST DATA
echo "Welcome"
echo
read -p "Hi there!! lets go!" 
read -p "Instance name: " NOMBRE_INSTANCIA
read -p "Odoo version: " VERSION_ODOO
read -p "Postgres port: " PUERTO_PG
read -p "xmlrpc port: " PUERTO_XMLRPC
read -p "admin passwd: " ADMIN_PASSWD

#INSTALL DEPENDENCES
apt install git postgresql nginx python-pip python3-pip zlib1g-dev python-lxml python3-lxml python-libxml2 python3-libxml2 libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev -y

#Verificar si se puede instalar npm en el sistema, sino hacer lo siguiente:
apt install -y curl
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -
apt install -y nodejs
ln -s /usr/bin/nodejs /usr/bin/node
npm install -g less

#POSTGRES CURRENT VERSION
VERSION_PG=$(psql -V | egrep -o '[0-9]{1,}\.[0-9]{1,}')

adduser --system --group --home /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA --shell /bin/bash  odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
su - postgres -c "pg_createcluster -p $PUERTO_PG $VERSION_PG odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA}";

#EDIT POSTGRES CLUSTER CONFIG
sed 's/^#listen_addresses/listen_addresses/' /etc/postgresql/$VERSION_PG/odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA}/postgresql.conf > /etc/postgresql/$VERSION_PG/odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA}/postgresql.conf1
mv /etc/postgresql/$VERSION_PG/odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA}/postgresql.conf1 /etc/postgresql/$VERSION_PG/odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA}/postgresql.conf
systemctl daemon-reload
pg_ctlcluster $VERSION_PG odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA} start

#CREATE POSTGRES USER (WITHOUT PASSWORD)
su - postgres -c "createuser -dRS odoo-v${VERSION_ODOO}-${NOMBRE_INSTANCIA} --cluster $VERSION_PG/odoo_v${VERSION_ODOO}_${NOMBRE_INSTANCIA}"
        
#CREATE DIRECTORY STRUCTURE 
mkdir -p /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/data /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/addons /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/logs 
cd /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src
git clone https://www.github.com/odoo/odoo --depth 1 --branch $VERSION_ODOO.0
# git clone own repo

#IF VERSION CLONE > 10: INSTALL WITH PYTHON 3
if [ $VERSION_ODOO -gt 10 ]; then
        pip3 install --no-cache-dir -r /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/doc/requirements.txt
        pip3 install --no-cache-dir -r /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/requirements.txt
else
        pip install --no-cache-dir -r /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/doc/requirements.txt
        pip install --no-cache-dir -r /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/requirements.txt
fi

#MAKE INSTANCE SERVICE
echo "[Unit]
Description=Odoo Instance for odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
Requires=postgresql.service
After=network.target postgresql.service
    
[Service]
Type=simplemotd
PermissionsStartOnly=true
SyslogIdentifier=odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
User=odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
Group=odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
ExecStart=/home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/odoo-bin --config=/etc/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.conf --addons-path=/home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/addons,/home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/addons

WorkingDirectory=/home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/
StandardOutput=journal+console
    
[Install]
WantedBy=multi-user.target" > /lib/systemd/system/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.service

#MAKE INSTANCE CONFIG FILE
echo "[options]
admin_passwd = $ADMIN_PASSWD
db_host = False 
db_port = $PUERTO_PG
db_user = odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
db_password = odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
addons_path = /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/src/odoo/addons/

data_dir = /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/data/filestore
logfile = /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/logs/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.log
xmlrpc = True
xmlrpc_interface = 127.0.0.1
xmlrpc_port = $PUERTO_XMLRPC
proxy_mode = True" > /etc/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.conf

#CHANGE PERMISSION

chmod 755 /lib/systemd/system/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.service
chown root: /lib/systemd/system/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.service
chmod 640 /etc/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.conf
chown odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA:root /etc/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.conf
chown -R odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA:root /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
mkdir /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/logs/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
touch /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/logs/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.log
chmod 755 /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/logs/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.log
chown -R odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA:odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA /home/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA/logs/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA

# RUN INSTANCE
systemctl daemon-reload
systemctl start odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
systemctl stop odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
systemctl enable odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA

#MAKE NGINX REVERSE PROXY SERVER
echo "upstream odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA {
        server 127.0.0.1:$PUERTO_XMLRPC;
}
 
server{
        listen 80;
        listen [::]:80;
 
        server_name $NOMBRE_INSTANCIA.testing.co.ve;
        
        #Redirect requests to odoo backend server
        location / {
                proxy_redirect off;
                proxy_pass http://odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA;
                proxy_set_header    Host            \$host;
                proxy_set_header    X-Real-IP       \$remote_addr;
                proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header    X-Forwarded-Proto http;        
        }

        access_log /var/log/nginx/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.log;
        error_log  /var/log/nginx/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA.error.log;
}" > /etc/nginx/sites-available/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA

#ACTIVATE NGINX REVERSE PROXY SERVER
ln -s /etc/nginx/sites-available/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA /etc/nginx/sites-enabled/odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA

systemctl daemon-reload
systemctl restart nginx

#APPEND ODOO USER TO SUDORES
sudo adduser odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA sudo

# RUN INSTANCE
systemctl start odoo-v$VERSION_ODOO-$NOMBRE_INSTANCIA
exit
