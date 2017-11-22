# Script install Django and Ngnix

Script para instalar un sitio en producción o diferentes ambietes como desarrollo y pruebas con las siguientes tecnologías:

1. Linux (Ubuntu Server 16.04 o Ubuntu Server 17.10)
2. Python3
3. Django
4. Virtualenv
5. Postgres o Mysql
6. Git
7. Nginx
8. Phppgadmin o Phpmyadmin
9. Pip

## Pasos

1. Ejecutar el fichero **install-production-server-ngnix.sh**

`./install-production-server-ngnix.sh`

2. Verificar la instalación en la ruta del sitio:

`/home/<mi-usuario>/sites/<mi-sitio>`

3. Si nuestro repositorio contiene en la raiz un archivo de `requirements.txt` instala las dependencias incluidas en el archivo.

4. Si no tenemos DNS podemos agregar un registro en nuestros clientes linux en **/etc/hosts** en cliente Windows **C:\Windows\System32\drivers\etc\hosts**

`127.0.0.1	<mi-sitio>`

5. En el navegador

- Sitio web: **http://VAR_DOMAIN_OR_IP**
- Base de datos: **http://VAR_DOMAIN_OR_IP:VAR_DATABASE_PORT_WEB**

*Si no hemos cambiado los puertos en las variables respectivas*

Para mas información:
- Email: **galejandromorera@gmail.com**
- **[Tutorial](http://gams87.pythonanywhere.com/entry/detail/instalar-django-linux-nginx-y-base-de-datos/ "Tutorial")**