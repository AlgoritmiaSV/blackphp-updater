#!/bin/bash
# BlackPHP

# Sincroniza archivos de BlackPHP con los diferentes proyectos derivados a fin de mantener el Framework actualizado en todos los proyectos.

# REQUERIMIENTOS
# jq (Paquete para lectura y creación de archivos JSON)

# Se comprueba que se haya pasado por parámetro el nombre de la carpeta con la cual se quiere sincronizar, de lo contrario, sincronizará con una lista definida.
if [ "$#" = "0" ]; then
	for folder in negkit sicoimWebApp acrossdesk mimakit velnet21WebApp
	do
		echo "------------ RSYNC BlackPHP > $folder"
		$0 $folder
	done
	exit 1
fi

# Nos dirigimos a la carpeta donde se encuentran los proyectos (Opcional)
cd /store/Clouds/Mega/www/
# Cantidad de archivos a modificar (Si es cero, no se actualiza)
files=0
# Comprueba que el directorio que se le ha pasado por parámetro, existe. De lo contrario, crea uno con una instalación limpia.
if [ ! -d "$1" ]
then
	# Instalación nueva. Crea un directorio
	mkdir $1
	# Cuenta los archivos a transferir con rsync --stats (el parámetro n es esencial para no ejecutar de una vez)
	files=`rsync -avn --stats --exclude ".git/" --exclude "db/" --exclude "README.md" --exclude ".gitignore" --exclude "entities/" blackphp/ $1/ | grep "files transferred" | cut -c 38-`
	#Realiza la sincronización
	rsync -av --exclude ".git/" --exclude "db/" --exclude "README.md" --exclude ".gitignore" --exclude "entities/" blackphp/ $1/
else
	# Comprueba la cantidad de archivos a transferir
	files=`rsync -avn --stats --exclude ".git/" --exclude "db/" --include "controllers/devUtils.php" --include "controllers/error.php" --exclude "controllers/*" --exclude "public/icons" --exclude "public/images" --exclude "favicon.ico" --exclude "models/" --exclude "README.md" --exclude "views/" --exclude ".gitignore" --exclude "entities/" --exclude "locale/" blackphp/ $1/ | grep "files transferred" | cut -c 38-`
	# Si la cantidad de archivos a transferir es mayor que cero, realiza la sincronización, de lo contrario, imprime "Up to date".
	if [ $files -gt "0" ]; then
		rsync -av --exclude ".git/" --exclude "db/" --include "controllers/devUtils.php" --include "controllers/error.php" --exclude "controllers/*" --exclude "public/icons" --exclude "public/images" --exclude "favicon.ico" --exclude "models/" --exclude "README.md" --exclude "views/" --exclude ".gitignore" --exclude "entities/" --exclude "locale/" blackphp/ $1/
	else
		echo "    Up to date";
	fi

#	echo "    Rsync Delete node_modules"
#	rsync -av --delete blackphp/node_modules/ $1/node_modules/
#	echo "    Rsync Delete vendor"
#	rsync -av --delete blackphp/vendor/ $1/vendor/
#	echo "    Rsync Delete external"
#	rsync -av --delete blackphp/public/external/ $1/public/external/
fi
# Si al final de la operación sí hubo transferencia de archivos, ya sea a un proyecto existente o uno nuevo, entonces se agrega el archivo black_php.json en el destino, con información acerca de la fecha y hora de la última actualización.
if [ $files -gt "0" ]; then
	last_update=`date +"%Y-%m-%d %H:%M:%S"`
	version=`jq -r ".version" $1/blackphp_info.json`
	number=`jq -r ".number" $1/blackphp_info.json`
	jq -n --arg last_update "$last_update" \
			--arg version "$version" \
			--arg number "$number" \
	'{"last_update": "\($last_update)", "version": "\($version)", "number": "\($number)"}' > $1/blackphp_info.json
	echo "    Version: $version; $files files updated."
fi
