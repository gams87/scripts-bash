# scripts-bash

Script para instalar un sitio en produción con las siguientes tecnologías

1. Python
2. Django
3. Postgres, Mysql o SQLite
4. Git
5. Nginx
6. PHPpgadmin

## Pasos

1. Modificar las variables del fichero **install-production-server-ngnix.sh**

- VAR_NEW_PROJECT=0 	# 1 => Repositorio Nuevo, 0 => Clonar repositorio
- VAR_SITE="misitio" 	#  Nombre de mi sitio
- VAR_USER=$(who | cut -d' ' -f 1) # Validar si este comando who | cut -d' ' -f 1 trae nuestro usuario sino podemos agregarlo literal
- VAR_REPO_NAME="misitio"				# Nombre del repositorio a clonar si VAR_NEW_PROJECT=0
- VAR_REPO_ORIGIN="https://github.com/gams87/django-site-example.git" # Dirección de repositorio
- VAR_REPO_BRANCH="master"				# Rama del repositorio
- VAR_DEPENDENCIES="pillow"	# Librerias Python necesarias separadas por espacio
- 

2. Modificar las variables de base de datos del fichero **install-production-server-ngnix.sh**

- VAR_DATABASE_USE=0					# 1 => Usa base de datos 0 => No usa base de datos
- VAR_DATABASE_ENGINE="postgresql"		# Motor de base de datos
- VAR_DATABASE_USER=$VAR_SITE			# Usuario de base de datos, en este caso el mismo que el sitio
- VAR_DATABASE_PASSWORD="mipasswd"		# Password de mi base de datos
- VAR_DATABASE_PORT_WEB="8081"			# Puerto para la administración de phppgadmin

3. Ejecutar el fichero **install-production-server-ngnix.sh**

`./install-production-server-ngnix.sh`

4. La ruta del sitio:

`/home/<mi-usuario>/sites/<mi-sitio>`	