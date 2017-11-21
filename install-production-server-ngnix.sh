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
# Actualizacion del servidor
#=======================================================================
echo -e "\n\e[32mActualizacion del servidor\e[39m"
echo -n "Desea actualizar el servidor [yes/no] (yes): "
read VAR_INPUT
VAR_INPUT=${VAR_INPUT^^}  # Mayusculas

if [ -z $VAR_INPUT ];
then
	VAR_INPUT="YES"
fi;

if [ $VAR_INPUT = "YES" ];
then
	sudo apt-get update && sudo apt-get upgrade -y
fi;
echo -e "\e[32m[Fin de actualizacion del servidor]\e[39m" 
#=======================================================================


#=======================================================================
# Configurar locales
#=======================================================================
echo -n "Desea configurar los locales [yes/no] (yes): "
read VAR_INPUT
VAR_INPUT=${VAR_INPUT^^}  # Mayusculas

if [ -z $VAR_INPUT ];
then
	VAR_INPUT="YES"
fi;

if [ $VAR_INPUT = "YES" ];
then
	echo -e "\n\e[32mConfiguracion locale\e[39m"
	export LC_ALL="es_CR.UTF-8"
	export LC_CTYPE="es_CR.UTF-8"
	sudo dpkg-reconfigure locales
	echo -e "\e[32m[Fin de configuracion de locale]\e[39m"
fi;
#=======================================================================


#=======================================================================
# Instalacion de las dependencias
#=======================================================================
echo -e "\n\e[32mInstalando dependencias\e[39m"
sudo apt-get install libjpeg-dev libpq-dev build-essential libssl-dev libffi-dev libmysqlclient-dev -y
sudo apt-get install python3-pip python3-venv python3-dev -y
sudo apt-get install nginx -y
sudo -H pip3 install --upgrade pip
sudo -H pip install --upgrade pip
sudo -H pip3 install setuptools
sudo -H pip3 install --upgrade setuptools
sudo -H pip3 install virtualenv
clear
echo -e "\e[32m[Fin de instalacion de dependencias]\e[39m"
#=======================================================================


#=======================================================================
# Definicion de variables
#=======================================================================
echo -e "\n\e[32mDefinicion de variables\e[39m"

# ============================================================================
# Usuario (Owner)
# ============================================================================
VAR_USER=$(who -m | cut -d' ' -f 1) # Ubuntu y Debian
echo -n "Digite el nombre de usuario ($VAR_USER): "
read VAR_USER
VAR_USER=${VAR_USER,,}  # Minisculas

if [ -z $VAR_USER];
then
	VAR_USER=$(who -m | cut -d' ' -f 1)
fi;

# ============================================================================
# Proyecto
# ============================================================================
VAR_HOME=$(echo ~)
echo -n "Nombre del sitio: "
read VAR_SITE
VAR_PROJECT="$VAR_HOME/sites/site-$VAR_SITE"
mkdir -p $VAR_PROJECT
VAR_VIRTUALENV="$VAR_PROJECT/$VAR_SITE-env"

# Variables Gunicorn
VAR_GUNICORN_SERVICE="gunicorn-$VAR_SITE.service"
VAR_PAHT_GUNICORN_SERVICE="/etc/systemd/system/$VAR_GUNICORN_SERVICE"

VAR_FILE_INFO="$VAR_HOME/resume-$VAR_SITE.txt"
echo "=====================================" >> $VAR_FILE_INFO
echo "Información General del Proyecto" >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO
echo "Usuario (Owner): $VAR_USER" >> $VAR_FILE_INFO
echo "Nombre: $VAR_SITE" >> $VAR_FILE_INFO
echo "Ruta del proyecto: $VAR_PROJECT" >> $VAR_FILE_INFO
echo "Ruta de Virtualenv: $VAR_VIRTUALENV" >> $VAR_FILE_INFO
echo "Servicio Gunicorn: $VAR_GUNICORN_SERVICE" >> $VAR_FILE_INFO
echo "Ruta Gunicorn: $VAR_PAHT_GUNICORN_SERVICE" >> $VAR_FILE_INFO

# ============================================================================
# Proyecto nuevo o repositorio?
# ============================================================================
echo -n "Desea clonar un repositorio git con un proyecto Django [yes/no] (no): "
read VAR_INPUT
VAR_INPUT=${VAR_INPUT^^}  # Mayusculas

if [ -z $VAR_INPUT ];
then
	VAR_INPUT="NO"
fi;

if [ $VAR_INPUT = "YES" ];
then
	# Clonar proyecto Django con git
	echo -n "Digite la dirección del repositorio git: "
	read VAR_REPO_ORIGIN
	echo -n "Digite el nombre de la rama (master): "
	read VAR_REPO_BRANCH

	if [ -z $VAR_REPO_BRANCH ];
	then
		VAR_REPO_BRANCH="master"
	fi;

	echo -e "\n\e[32mClonando proyecto Django de repositorio\e[39m"
	cd $VAR_PROJECT
	git clone $VAR_REPO_ORIGIN

	VAR_REPO_NAME=$(ls | head -1)
	cd $VAR_REPO_NAME
	git fetch --all
	git checkout $VAR_REPO_BRANCH

	if [ $VAR_REPO_NAME != $VAR_SITE ];
	then
		cd ..
		mv $VAR_REPO_NAME $VAR_SITE
	fi;
	echo -e "\e[32m[Proyecto de Django clonado correctamente]\e[39m"
	echo "Proyecto nuevo: No" >> $VAR_FILE_INFO
	echo "Dirección del repositorio: $VAR_REPO_ORIGIN" >> $VAR_FILE_INFO
	echo "Rama del repositiorio: $VAR_REPO_BRANCH" >> $VAR_FILE_INFO
	echo "Carpeta del repositiorio original: $VAR_REPO_NAME" >> $VAR_FILE_INFO
	echo "Carpeta del repositiorio renombrada: $VAR_SITE" >> $VAR_FILE_INFO
else
	# Crear nuevo projecto Django
	echo -e "\n\e[32mCreando nuevo proyecto de Django [$VAR_SITE]\e[39m"
	cd $VAR_PROJECT
	django-admin.py startproject $VAR_SITE
	echo -e "\e[32m[Nuevo proyecto de Django creado correctamente]\e[39m"

	VAR_REPO_NAME=$(ls | head -1)
	echo "Proyecto nuevo: Si" >> $VAR_FILE_INFO
fi;

VAR_PATH_SETTINGS_DJANGO=$(find $VAR_PROJECT/ -name 'settings.py')
VAR_PATH_SETTINGS_DJANGO="$VAR_PATH_SETTINGS_DJANGO"

echo "Ruta del archivo settings.py: $VAR_PATH_SETTINGS_DJANGO" >> $VAR_FILE_INFO

#=======================================================================
# Configurar virtualenv
#=======================================================================
echo -e "\n\e[32mCreando y activando virtualenv\e[39m"
virtualenv $VAR_VIRTUALENV
source $VAR_VIRTUALENV/bin/activate
pip install --upgrade pip
pip3 install --upgrade pip
pip3 install django gunicorn

if [ -f $VAR_PROJECT/$VAR_SITE/requirements.txt ];
then
	pip3 install -r $VAR_PROJECT/$VAR_SITE/requirements.txt
fi;
echo -e "\e[32m[Virtualenv configurada correctamente]\e[39m"
#=======================================================================

#=======================================================================
# Crear e iniciar servicio para Gunicorn
#=======================================================================
echo -e "\n\e[32mCreando e iniciando el servicio para Gunicorn\e[39m"
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
echo "WorkingDirectory=$VAR_PROJECT" >> $VAR_GUNICORN_SERVICE
echo "ExecStart=$VAR_VIRTUALENV/bin/gunicorn --workers 3 --bind unix:$VAR_PROJECT/$VAR_SITE.sock $VAR_PATH_SETTINGS_DJANGO.wsgi:application" >> $VAR_GUNICORN_SERVICE
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


# ============================================================================
# Variables Nginx
# ============================================================================
echo "" >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO
echo "Información de Nginx" >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO

VAR_SITE_NGNIX="$VAR_SITE.conf"
VAR_PATH_NGNIX="/etc/nginx/sites-available"
VAR_PATH_SITE_NGNIX="$VAR_PATH_NGNIX/$VAR_SITE_NGNIX"


echo -n "Digite la ip o el dominio del sitio: "
read VAR_DOMAIN_OR_IP
VAR_DOMAIN_OR_IP=${VAR_DOMAIN_OR_IP,,}  # Minusculas

echo -n "Digite el puerto para el sitio (80): "
read VAR_SITE_PORT

if [ -z $VAR_SITE_PORT ];
then
	VAR_SITE_PORT="80"
fi;

echo "Ruta de archivo de configuración Ngnix para el sitio: $VAR_PATH_SITE_NGNIX" >> $VAR_FILE_INFO

#=======================================================================
# Configurar Nginx
#=======================================================================
echo -e "\n\e[32mConfigurando Ngnix\e[39m"
echo -e "\n\e[32mCreando el fichero de configuracion Ngnix para el sitio [$VAR_SITE_NGNIX]\e[39m"
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
echo "	location /static/ { root $VAR_PROJECT/$VAR_SITE; }" >> $VAR_SITE_NGNIX
echo "	location /media/ { root $VAR_PROJECT/$VAR_SITE; }" >> $VAR_SITE_NGNIX
echo "	location / {" >> $VAR_SITE_NGNIX
echo "		include proxy_params;" >> $VAR_SITE_NGNIX
echo "		proxy_pass http://unix:$VAR_PROJECT/$VAR_SITE.sock;" >> $VAR_SITE_NGNIX
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
clear
echo -e "\e[32m[Ngnix configurado correctamente]\e[39m"
#=======================================================================


# ============================================================================
# Base de datos
# ============================================================================
echo -e "\n\e[32mInstalando y configurando base de datos\e[39m"
echo "" >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO
echo "Información de Base de datos" >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO

echo -n "Desea configurar una base de datos [yes/no] (no): "
read VAR_INPUT
VAR_INPUT=${VAR_INPUT^^}  # Mayusculas

if [ -z $VAR_INPUT ];
then
	VAR_INPUT="NO"
fi;

VAR_DATABASE_USE=0
if [ $VAR_INPUT = "YES" ];
then
	VAR_DATABASE_USE=1
	echo -n "Digite el motor de base de datos [postgres=1, mysql=2] (1): "
	read VAR_DATABASE_ENGINE
	VAR_DATABASE_ENGINE=${VAR_DATABASE_ENGINE,,}  # Minusculas

	if [ -z $VAR_DATABASE_ENGINE ];
	then
		VAR_DATABASE_ENGINE="1"
	fi;

	if [ $VAR_DATABASE_ENGINE = "2" ];
	then
		VAR_DATABASE_ENGINE="mysql"
	else
		VAR_DATABASE_ENGINE="postgres"
	fi;

	echo -n "Digite el nombre de la base de datos ($VAR_SITE): "
	read VAR_DATABASE_NAME

	if [ -z $VAR_DATABASE_NAME ];
	then
		VAR_DATABASE_NAME=$VAR_SITE
	fi;

	echo -n "Digite el nombre de usuario de base de datos ($VAR_SITE): "
	read VAR_DATABASE_USER

	if [ -z $VAR_DATABASE_USER ];
	then
		VAR_DATABASE_USER=$VAR_SITE
	fi;

	echo "Motor: $VAR_DATABASE_ENGINE" >> $VAR_FILE_INFO
	echo "Base de datos: $VAR_PATH_SITE_NGNIX" >> $VAR_FILE_INFO
	echo "Usuario: $VAR_DATABASE_USER" >> $VAR_FILE_INFO

	
	if [ $VAR_DATABASE_ENGINE = "mysql" ];
	then
		sudo -H pip3 install mysql-connector
		sudo apt-get install mysql-server phpmyadmin -y
		sudo php5enmod mcrypt
		sudo service php5-fpm restart
		sudo ln -s /usr/share/phpmyadmin /usr/share/nginx/html
		sudo mysql_secure_installation
		echo -e ""
		echo -e "============================================================================"
		echo -e "Ejecute los siguientes comandos =>"
		echo -e "CREATE DATABASE $VAR_SITE CHARACTER SET utf8;"
		echo -e "CREATE USER '$VAR_DATABASE_USER'@'localhost' IDENTIFIED BY '$VAR_DATABASE_PASSWORD';"
		echo -e "GRANT ALL PRIVILEGES ON * . * TO '$VAR_DATABASE_USER'@'localhost';"
		echo -e "FLUSH PRIVILEGES;"
		echo -e "============================================================================"
		mysql -u root -p
	fi;
	
	if [ $VAR_DATABASE_ENGINE = "postgres" ];
	then
		sudo apt-get install postgresql postgresql-contrib phppgadmin php7.0 php7.0-fpm -y
		
		echo -e ""
		echo -e "============================================================================"
		echo -e "Ejecute el siguiente comando (\\q => Para salir):"
		echo -e "CREATE USER $VAR_DATABASE_USER WITH PASSWORD '$VAR_DATABASE_PASSWORD';" \\q
		echo -e "============================================================================"
		sudo -u postgres psql
		# sudo -u postgres psql -c "CREATE USER $VAR_DATABASE_USER WITH PASSWORD '$VAR_DATABASE_PASWORD';"

		echo -e "CREATE DATABASE $VAR_DATABASE_NAME;"
		sudo -u postgres psql -c "CREATE DATABASE $VAR_DATABASE_NAME;"
		
		echo -e "ALTER ROLE $VAR_DATABASE_USER SET client_encoding TO 'utf8';"
		sudo -u postgres psql -c "ALTER ROLE $VAR_DATABASE_USER SET client_encoding TO 'utf8';"
		
		echo -e "ALTER ROLE $VAR_DATABASE_USER SET default_transaction_isolation TO 'read committed';"
		sudo -u postgres psql -c "ALTER ROLE $VAR_DATABASE_USER SET default_transaction_isolation TO 'read committed';"
		
		echo -e "ALTER ROLE $VAR_DATABASE_USER SET timezone TO 'UTC';"
		sudo -u postgres psql -c "ALTER ROLE $VAR_DATABASE_USER SET timezone TO 'UTC';"
		
		echo -e "GRANT ALL PRIVILEGES ON DATABASE $VAR_DATABASE_NAME TO $VAR_DATABASE_USER;"
		sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $VAR_DATABASE_NAME TO $VAR_DATABASE_USER;"
		
		echo -e "ALTER DATABASE $VAR_DATABASE_NAME OWNER TO $VAR_DATABASE_USER;"
		sudo -u postgres psql -c "ALTER DATABASE $VAR_DATABASE_NAME OWNER TO $VAR_DATABASE_USER;"

		echo -e "\n\e[32mConfigurando phppgadmin\e[39m"
		echo -n "Digite el puerto para phpppgadmin (8081): "
		read VAR_DATABASE_PORT_WEB

		if [ -z $VAR_DATABASE_PORT_WEB ];
		then
			VAR_DATABASE_PORT_WEB="8081"
		fi;

		echo "Puerto de administración para phppgadmin: $VAR_DATABASE_PORT_WEB" >> $VAR_FILE_INFO

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
		sudo mkdir -p /var/log/phppgadmin
	fi;
fi
clear
echo -e "\e[32m[Fin de instalacion de bases de datos]\e[39m"
#=======================================================================


#=======================================================================
# Crear las migraciones a base de datos
#=======================================================================
echo -e "\n\e[32mMigraciones de base de datos y collectstatic\e[39m"
cd $VAR_PROJECT/$VAR_SITE
python manage.py collectstatic

echo -n "Desea ejecutar las migraciones de base de datos [yes/no] (yes): "
read VAR_INPUT
VAR_INPUT=${VAR_INPUT^^}  # Mayusculas

if [ -z $VAR_INPUT ];
then
	VAR_INPUT="YES"
fi;

if [ $VAR_SITE_PORT = "YES" ];
then
	python manage.py makemigrations
	python manage.py migrate
fi;

deactivate
clear
echo -e "\n\e[32mFin de migraciones de base de datos y collectstatic\e[39m"
#=======================================================================

#=======================================================================
# Mensaje de ejecucion
#=======================================================================
echo -e "\n\e[32mFelicidades! Script ejecutado correctamente\e[39m"
echo ""  >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO
echo "Direccines" >> $VAR_FILE_INFO
echo "=====================================" >> $VAR_FILE_INFO

if [ $VAR_SITE_PORT = "80" ];
then
	echo -e "Sitio web: http://$VAR_DOMAIN_OR_IP"
	echo "Dirección web del sitio: http://$VAR_DOMAIN_OR_IP" >> $VAR_FILE_INFO
else
	echo -e "Sitio web: http://$VAR_DOMAIN_OR_IP:$VAR_SITE_PORT"
	echo "Dirección web del sitio: http://$VAR_DOMAIN_OR_IP:$VAR_SITE_PORT" >> $VAR_FILE_INFO
fi;

if [ $VAR_DATABASE_USE -eq 1 ];
then
	if [ $VAR_DATABASE_ENGINE = "mysql" ];
	then
		echo -e "http://<SERVER-IP-OR-DOMAIN>/phpmyadmin"
		echo "Dirección web de base de datos: http://<SERVER-IP-OR-DOMAIN>/phpmyadmin" >> $VAR_FILE_INFO
	fi;
	
	if [ $VAR_DATABASE_ENGINE = "postgresql" ];
	then
		echo -e "Base de datos: http://$VAR_DOMAIN_OR_IP:$VAR_DATABASE_PORT_WEB"
		echo "Dirección web de base de datos: http://$VAR_DOMAIN_OR_IP:$VAR_DATABASE_PORT_WEB" >> $VAR_FILE_INFO
	fi;
fi;
#=======================================================================