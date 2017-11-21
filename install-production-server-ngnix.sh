#!/bin/bash

#=======================================================================
# Instalador de Django, Gunicorn, Ngnix y Postgres para producion
#=======================================================================
#
# Autor: Alejandro Morera
# Email: galejandromorera@gmail.com
# Fecha: 2-Jun-2016
# Actualizado 1-Nov-2017
# ---
# Descripcion: Script que instala una aplicacion django nuevo o desde
# un repositocio GIT y la configura para ser mostrada por un servidor
# Nginx para producion.
# ---
# Ejecucion:
#	1. Configuracion de variables
#	2. Actualizacion del servidor
#	3. Configurar locale
#	4. Instalacion de dependencias
#	5. Instalacion de base de datos
#	6. Crear y activar virtualenv
#	7. Crear o clonar projecto de Django
#	8. Crear las migraciones a base de datos
#	9. Crear e iniciar servicio para Gunicorn
#	10. Configurar Nginx
#	11. Mensaje de ejecucion
#
#=======================================================================


#=======================================================================
# 1. Definicion de variables
#=======================================================================
echo -e "\n\e[32m1. Definicion de variables\e[39m"

# Variables proyecto
VAR_NEW_PROJECT=0 # 1 => true | 0 => false
VAR_PROJECT="site-misitio"
VAR_SITE="misitio"
VAR_USER=$(who | cut -d' ' -f 1) # Ubuntu
# VAR_USER=$(who -m | cut -d' ' -f 1) # Debian 

# Variables repositorio
VAR_REPO_NAME="django-site-example"
VAR_REPO_ORIGIN="https://github.com/gams87/django-site-example.git"
VAR_REPO_BRANCH="master"

# Variables virtualenv
VAR_DEPENDENCIES="pillow psycopg2"
VAR_ENV="-env"
VAR_PROJECTENV=$VAR_SITE$VAR_ENV

# Variables Gunicorn
VAR_GUNICORN_SERVICE="gunicorn-$VAR_SITE.service"
VAR_PAHT_GUNICORN_SERVICE="/etc/systemd/system/$VAR_GUNICORN_SERVICE"

# Variables Nginx
VAR_SITE_NGNIX="$VAR_SITE.conf"
VAR_PAHT_NGNIX="/etc/nginx/sites-available"
VAR_PAHT_SITE_NGNIX="$VAR_PAHT_NGNIX/$VAR_SITE_NGNIX"
VAR_DOMAIN_OR_IP="$VAR_SITE.com"
VAR_SITE_PORT="80"

# Base de datos
VAR_DATABASE_USE=1 # 1 => true 0 => false
VAR_DATABASE_ENGINE="postgresql"
VAR_DATABASE_USER=$VAR_SITE
VAR_DATABASE_PASSWORD="123456"
VAR_DATABASE_PORT_WEB="8081"
echo -e "\e[32m[Variables definidas correctamente]\e[39m"
#=======================================================================
cd ~
mkdir sites
VAR_PROJECT="sites/$VAR_PROJECT"
#=======================================================================


#=======================================================================
# 2. Actualizacion del servidor
#=======================================================================
echo -e "\n\e[32m2. Actualizacion del servidor\e[39m"
sudo apt-get update && sudo apt-get upgrade -y
echo -e "\e[32m[Fin de actualizacion del servidor]\e[39m" 
#=======================================================================



#=======================================================================
# 3. Configurar locale
#=======================================================================
echo -e "\n\e[32m2. Configuracion locale\e[39m"
export LC_ALL="es_CR.UTF-8"
export LC_CTYPE="es_CR.UTF-8"
sudo dpkg-reconfigure locales
echo -e "\e[32m[Fin de configuracion de locale]\e[39m"
#=======================================================================



#=======================================================================
# 4. Instalacion de las dependencias
#=======================================================================
echo -e "\n\e[32m3. Instalando paquetes\e[39m"
sudo apt-get install libjpeg-dev libpq-dev build-essential libssl-dev libffi-dev -y
sudo apt-get install python3-pip python3-venv python3-dev -y
sudo apt-get install nginx -y
sudo -H pip3 install --upgrade pip
sudo -H pip install --upgrade pip
sudo -H pip3 install setuptools
sudo -H pip3 install --upgrade setuptools
sudo -H pip3 install virtualenv
echo -e "\e[32m[Fin de instalacion de paquetes]\e[39m"
#=======================================================================



#=======================================================================
# 5. Instalacion de base de datos
#=======================================================================
echo -e "\n\e[32m3. Instalando base de datos\e[39m"
if [ $VAR_DATABASE_USE -eq 1 ];
then
	if [ $VAR_DATABASE_ENGINE = "mysql" ];
	then
		sudo -H pip3 install mysql-connector
		sudo apt-get install mysql-server phpmyadmin -y
		echo -e "CREATE DATABASE $VAR_SITE CHARACTER SET utf8;"
		mysql -uroot -e "CREATE DATABASE '$VAR_SITE' CHARACTER SET utf8;"
		echo -e "CREATE USER '$VAR_DATABASE_USER'@'localhost' IDENTIFIED BY '$VAR_DATABASE_PASSWORD';"
		mysql -uroot -e "CREATE USER '$VAR_DATABASE_USER'@'localhost' IDENTIFIED BY '$VAR_DATABASE_PASSWORD';"
		echo -e "GRANT ALL PRIVILEGES ON * . * TO '$VAR_DATABASE_USER'@'localhost';"
		mysql -uroot -e "GRANT ALL PRIVILEGES ON * . * TO '$VAR_DATABASE_USER'@'localhost';"
		echo -e "FLUSH PRIVILEGES;"
		mysql -uroot -e "FLUSH PRIVILEGES;"
		sudo php5enmod mcrypt
		sudo service php5-fpm restart
		sudo ln -s /usr/share/phpmyadmin /usr/share/nginx/html
		sudo mysql_secure_installation
	fi;
	
	if [ $VAR_DATABASE_ENGINE = "postgresql" ];
	then
		sudo apt-get install postgresql postgresql-contrib phppgadmin php7.0 php7.0-fpm -y

		echo -e "CREATE DATABASE $VAR_SITE;"
		sudo -u postgres psql -c "CREATE DATABASE $VAR_SITE;"

		echo -e "Copie y pegue esta linea:"
		echo -e "CREATE USER $VAR_DATABASE_USER WITH PASSWORD '$VAR_DATABASE_PASSWORD';"
		echo -e "Luego compie y pegue => \\q"
		sudo -u postgres psql
		#sudo -u postgres psql -c "CREATE USER $VAR_DATABASE_USER WITH PASSWORD '$VAR_DATABASE_PASWORD';"
		
		echo -e "ALTER ROLE $VAR_DATABASE_USER SET client_encoding TO 'utf8';"
		sudo -u postgres psql -c "ALTER ROLE $VAR_DATABASE_USER SET client_encoding TO 'utf8';"
		
		echo -e "ALTER ROLE $VAR_DATABASE_USER SET default_transaction_isolation TO 'read committed';"
		sudo -u postgres psql -c "ALTER ROLE $VAR_DATABASE_USER SET default_transaction_isolation TO 'read committed';"
		
		echo -e "ALTER ROLE $VAR_DATABASE_USER SET timezone TO 'UTC';"
		sudo -u postgres psql -c "ALTER ROLE $VAR_DATABASE_USER SET timezone TO 'UTC';"
		
		echo -e "GRANT ALL PRIVILEGES ON DATABASE $VAR_SITE TO $VAR_DATABASE_USER;"
		sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $VAR_SITE TO $VAR_DATABASE_USER;"
		
		echo -e "ALTER DATABASE $VAR_SITE OWNER TO $VAR_DATABASE_USER;"
		sudo -u postgres psql -c "ALTER DATABASE $VAR_SITE OWNER TO $VAR_DATABASE_USER;"
		
		# sudo -u postgres psql

		echo -e "\n\e[32m3. Configurando phppgadmin\e[39m"
		VAR_PHPPGADMIN_NAME_FILE="phppgadmin.conf"
		VAR_PAHT_PHPPGADMIN_NGNIX="$VAR_PAHT_NGNIX/$VAR_PHPPGADMIN_NAME_FILE"
		
		if [ -h "/var/www/$VAR_PHPPGADMIN_NAME_FILE" ];
		then
			sudo rm -f /var/www/$VAR_PHPPGADMIN_NAME_FILE
		fi;

		sudo ln -s /usr/share/phppgadmin /var/www

		if [ -f $VAR_PHPPGADMIN_NAME_FILE ];
		then
			sudo rm -f $VAR_PHPPGADMIN_NAME_FILE
		fi;

		touch $VAR_PHPPGADMIN_NAME_FILE
		echo "server {" > $VAR_PHPPGADMIN_NAME_FILE
		echo "	listen $VAR_DATABASE_PORT_WEB;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	server_name $VAR_DOMAIN_OR_IP;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	root  /var/www/phppgadmin;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	index index.html index.html index.php;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	access_log /var/log/phppgadmin/access.log;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	error_log /var/log/phppgadmin/error.log;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	location ~ \.php$ {" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		autoindex on;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		try_files \$uri =404;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		fastcgi_split_path_info ^(.+\.php)(/.+)$;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		fastcgi_index index.php;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		fastcgi_param SCRIPT_FILENAME /var/www/phppgadmin\$fastcgi_script_name;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "		include /etc/nginx/fastcgi_params;" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "	}" >> $VAR_PHPPGADMIN_NAME_FILE
		echo "}" >> $VAR_PHPPGADMIN_NAME_FILE

		if [ -f $VAR_PAHT_PHPPGADMIN_NGNIX ];
		then
			sudo rm -f $VAR_PAHT_PHPPGADMIN_NGNIX
		fi;

		sudo cp $VAR_PHPPGADMIN_NAME_FILE $VAR_PAHT_PHPPGADMIN_NGNIX
		sudo rm $VAR_PHPPGADMIN_NAME_FILE

		if [ -h /etc/nginx/sites-enabled/$VAR_PHPPGADMIN_NAME_FILE ];
		then
			sudo rm -f /etc/nginx/sites-enabled/$VAR_PHPPGADMIN_NAME_FILE
		fi;

		sudo ln -s $VAR_PAHT_PHPPGADMIN_NGNIX /etc/nginx/sites-enabled/$VAR_PHPPGADMIN_NAME_FILE
		sudo mkdir /var/log/phppgadmin
	fi;
else
	echo -e "\e[32mNo ha seleccionado ninguna base de datos para instalar\e[39m"
fi;
echo -e "\e[32m[Fin de instalacion de bases de datos]\e[39m"
#=======================================================================



#=======================================================================
# 6. Configurar virtualenv
#=======================================================================
echo -e "\n\e[32m5. Creando y activando virtualenv\e[39m"

if [ -d ~/$VAR_PROJECT ];
then
	rm -rf ~/$VAR_PROJECT
fi;

mkdir ~/$VAR_PROJECT
cd ~/$VAR_PROJECT

# pyvenv $VAR_PROJECTENV
virtualenv $VAR_PROJECTENV
source $VAR_PROJECTENV/bin/activate
pip install --upgrade pip
pip3 install --upgrade pip
pip3 install django gunicorn
pip3 install $VAR_DEPENDENCIES
echo -e "\e[32m[Virtualenv configurada correctamente]\e[39m"
#=======================================================================



#=======================================================================
# 7. Crear o clonar projecto de Django
#=======================================================================
if [ $VAR_NEW_PROJECT -eq 1 ];
then
	# Crear nuevo projecto Django
	echo -e "\n\e[32m7. Creando nuevo proyecto de Django [$VAR_SITE]\e[39m"
	cd ~/$VAR_PROJECT
	django-admin.py startproject $VAR_SITE
	echo -e "\e[32m[Nuevo proyecto de Django creado correctamente]\e[39m"
else
	# Clonar proyecto Django con git
	echo -e "\n\e[32m7. Clonando proyecto de Django [$VAR_REPO_NAME]\e[39m"
	cd ~/$VAR_PROJECT
	git clone $VAR_REPO_ORIGIN
	cd $VAR_REPO_NAME
	git fetch --all
	git checkout $VAR_REPO_BRANCH
	echo -e "\e[32m[Proyecto de Django clonado correctamente]\e[39m"
fi;
#=======================================================================



#=======================================================================
# 8. Crear las migraciones a base de datos
#=======================================================================
echo -e "\n\e[32m8. Creando las migraciones a base de datos\e[39m"
python manage.py collectstatic
python manage.py makemigrations
python manage.py migrate
cd ..
deactivate
echo -e "\e[32m[Migraciones a base de datos correctamente]\e[39m"
#=======================================================================



#=======================================================================
# 9. Crear e iniciar servicio para Gunicorn
#=======================================================================
echo -e "\n\e[32m9. Creando e iniciando el servicio para Gunicorn\e[39m"
if [ -f $VAR_GUNICORN_SERVICE ];
then
	sudo rm -f $VAR_GUNICORN_SERVICE
fi;

touch $VAR_GUNICORN_SERVICE
echo "[Unit]" > $VAR_GUNICORN_SERVICE
echo "Description=gunicorn daemon $VAR_SITE" >> $VAR_GUNICORN_SERVICE
echo "After=network.target" >> $VAR_GUNICORN_SERVICE
echo "" >> $VAR_GUNICORN_SERVICE
echo "[Service]" >> $VAR_GUNICORN_SERVICE
echo "User=$VAR_USER" >> $VAR_GUNICORN_SERVICE
echo "Group=www-data" >> $VAR_GUNICORN_SERVICE
echo "WorkingDirectory=/home/$VAR_USER/$VAR_PROJECT/$VAR_SITE" >> $VAR_GUNICORN_SERVICE
echo "ExecStart=/home/$VAR_USER/$VAR_PROJECT/$VAR_PROJECTENV/bin/gunicorn --workers 3 --bind unix:/home/$VAR_USER/$VAR_PROJECT/$VAR_SITE.sock $VAR_SITE.wsgi:application" >> $VAR_GUNICORN_SERVICE
echo "" >> $VAR_GUNICORN_SERVICE
echo "[Install]" >> $VAR_GUNICORN_SERVICE
echo "WantedBy=multi-user.target" >> $VAR_GUNICORN_SERVICE

if [ -f $VAR_PAHT_GUNICORN_SERVICE ];
then
	sudo rm -f $VAR_PAHT_GUNICORN_SERVICE
fi;

sudo cp $VAR_GUNICORN_SERVICE $VAR_PAHT_GUNICORN_SERVICE
sudo rm $VAR_GUNICORN_SERVICE

sudo systemctl start $VAR_GUNICORN_SERVICE
sudo systemctl daemon-reload
sudo systemctl enable $VAR_GUNICORN_SERVICE
echo -e "\e[32m[Servicio Gunicorn creado e iniciado correctamente]\e[39m"
#=======================================================================



#=======================================================================
# 10. Configurar Nginx
#=======================================================================
echo -e "\n\e[32m10. Creando el fichero de configuracion Ngnix para el sitio [$VAR_SITE_NGNIX]\e[39m"
if [ -f $VAR_SITE_NGNIX ];
then
	sudo rm -f $VAR_SITE_NGNIX
fi;

touch $VAR_SITE_NGNIX
echo "server {" > $VAR_SITE_NGNIX
echo "	listen $VAR_SITE_PORT;" >> $VAR_SITE_NGNIX
echo "	server_name $VAR_DOMAIN_OR_IP;" >> $VAR_SITE_NGNIX
echo "" >> $VAR_SITE_NGNIX
echo "	location = /favicon.ico { access_log off; log_not_found off; }" >> $VAR_SITE_NGNIX
echo "	location /static/ { root /home/$VAR_USER/$VAR_PROJECT/$VAR_SITE; }" >> $VAR_SITE_NGNIX
echo "	location /media/ { root /home/$VAR_USER/$VAR_PROJECT/$VAR_SITE; }" >> $VAR_SITE_NGNIX
echo "	location / {" >> $VAR_SITE_NGNIX
echo "		include proxy_params;" >> $VAR_SITE_NGNIX
echo "		proxy_pass http://unix:/home/$VAR_USER/$VAR_PROJECT/$VAR_SITE.sock;" >> $VAR_SITE_NGNIX
echo "	}" >> $VAR_SITE_NGNIX
echo "}" >> $VAR_SITE_NGNIX

if [ -f $VAR_PAHT_SITE_NGNIX ];
then
	sudo rm -f $VAR_PAHT_SITE_NGNIX
fi;

sudo cp $VAR_SITE_NGNIX $VAR_PAHT_SITE_NGNIX
sudo rm $VAR_SITE_NGNIX

if [ -h /etc/nginx/sites-enabled/$VAR_SITE_NGNIX ];
then
	sudo rm -f /etc/nginx/sites-enabled/$VAR_SITE_NGNIX
fi;

sudo ln -s $VAR_PAHT_SITE_NGNIX /etc/nginx/sites-enabled/$VAR_SITE_NGNIX
sudo nginx -t
sudo systemctl restart nginx.service
sudo systemctl restart $VAR_GUNICORN_SERVICE
echo -e "\e[32m[Ngnix configurado correctamente]\e[39m"
#=======================================================================


#=======================================================================
# 11. Mensaje de ejecucion
#=======================================================================
echo -e "\n\e[32mFelicidades! Script ejecutado correctamente\e[39m"
if [ $VAR_SITE_PORT = "80" ];
then
	echo -e "Sitio web: http://$VAR_DOMAIN_OR_IP"
else
	echo -e "Sitio web: http://$VAR_DOMAIN_OR_IP:$VAR_SITE_PORT"
fi;

if [ $VAR_DATABASE_USE -eq 1 ];
then
	if [ $VAR_DATABASE_ENGINE = "mysql" ];
	then
		http://<SERVER-IP-OR-DOMAIN>/phpmyadmin
	fi;
	
	if [ $VAR_DATABASE_ENGINE = "postgresql" ];
	then
		echo -e "Base de datos: http://$VAR_DOMAIN_OR_IP:$VAR_DATABASE_PORT_WEB"
	fi;
fi;
#=======================================================================