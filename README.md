# scripts-bash

Script para instalar un sitio en produción con las siguientes tecnologías

1. Linux
2. Python
3. Django
4. Postgres, Mysql o SQLite
5. Git
6. Nginx
7. PHPpgadmin

## Pasos

1. Modificar las variables del fichero **install-production-server-ngnix.sh**

- **VAR_NEW_PROJECT=0**						# 1 => Repositorio Nuevo, 0 => Clonar repositorio
- **VAR_SITE="misitio"** 					#  Nombre de mi sitio
- **VAR_USER=$(who | cut -d' ' -f 1)** 		# Validar si este comando who | cut -d' ' -f 1 trae nuestro usuario si no podemos agregarlo literal
- **VAR_REPO_ORIGIN="https://github.com/gams87/django-site-example.git" # Dirección de mi repositorio
- **VAR_REPO_NAME="django-site-example"**	# Nombre del repositorio a clonar si VAR_NEW_PROJECT=0
- **VAR_REPO_BRANCH="master"**				# Rama del repositorio
- **VAR_DEPENDENCIES="pillow"**				# Librerias Python necesarias separadas por espacio
- **VAR_DOMAIN_OR_IP="$VAR_SITE.com"**		# Mi dominio o ip

2. Modificar las variables de base de datos del fichero **install-production-server-ngnix.sh**

- **VAR_DATABASE_USE=0**					# 1 => Usa base de datos 0 => No usa base de datos
- **VAR_DATABASE_ENGINE="postgresql"**		# Motor de base de datos
- **VAR_DATABASE_USER=$VAR_SITE**			# Usuario de base de datos, en este caso el mismo que el sitio
- **VAR_DATABASE_PASSWORD="mipasswd"**		# Password de mi base de datos
- **VAR_DATABASE_PORT_WEB="8081"**			# Puerto para la administración de phppgadmin

3. Ejecutar el fichero **install-production-server-ngnix.sh**

`./install-production-server-ngnix.sh`

4. Verificar la instalación en la ruta del sitio:

`/home/<mi-usuario>/sites/<mi-sitio>`

5. Si no tenemos DNS podemos agregar en nuestro archivo /etc/hosts

`127.0.0.1	<mi-sitio>` # Donde **mi-sitio>** es el valor de VAR_DOMAIN_OR_IP


6. EN el navegador

- Sitio web: **http://VAR_DOMAIN_OR_IP**
- Base de datos: **http://VAR_DOMAIN_OR_IP:VAR_DATABASE_PORT_WEB**

*Si no hemos cambiado los puertos en las variables respectivas*