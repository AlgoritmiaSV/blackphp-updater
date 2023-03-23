#!/bin/bash
# BlackPHP

# Sincroniza archivos de BlackPHP con los diferentes proyectos derivados a fin de mantener el Framework actualizado en todos los proyectos.

# REQUERIMIENTOS
# jq (Paquete para lectura y creación de archivos JSON)

# Se comprueba que se haya pasado por parámetro el nombre de la carpeta con la cual se quiere sincronizar, de lo contrario, sincronizará con una lista definida.
if [ "$#" = "0" ]; then
	updated=0
	for folder in negkit negkitContracts negkitProjects negkitServices sicoimWebApp mimakit fileManager inabve
	do
		echo "------------ RSYNC BlackPHP > $folder"
		$0 $folder $updated
		updated=1
	done
	updated=0
	exit 1
fi

# Nos dirigimos a la carpeta donde se encuentran los proyectos (Opcional)
cd /store/Clouds/Mega/www/

# Establecemos fecha de actualización
if [ "$#" = "1" ] || ([ $# -gt 1 ] && [ "$2" = "0" ]); then
	last_update=`date +"%Y-%m-%d %H:%M:%S"`
	version=`jq -r ".version" blackphp/app_info.json`
	number=`jq -r ".number" blackphp/app_info.json`
	number=$((number+1))
	copyright=`jq -r ".copyright" blackphp/app_info.json`
	website=`jq -r ".website" blackphp/app_info.json`
	jq -n --arg last_update "$last_update" \
			--arg version "$version" \
			--arg number "$number" \
			--arg copyright "$copyright" \
			--arg website "$website" \
	'{"system_name": "BlackPHP", "version": "\($version)", "number": "\($number)", "last_update": "\($last_update)", "copyright": "\($copyright)", "website": "\($website)"}' > blackphp/app_info.json
fi

# Cantidad de archivos a modificar (Si es cero, no se actualiza)
files=0

# Comprueba que el directorio que se le ha pasado por parámetro, existe. De lo contrario, crea uno con una instalación limpia.
if [ ! -d "$1" ]
then
	# Instalación nueva. Crea un directorio
	mkdir $1
	# Cuenta los archivos a transferir con rsync --stats (el parámetro n es esencial para no ejecutar de una vez)
	files=`rsync -avn --stats --exclude ".git/" --exclude ".vscode" --exclude "db/" --exclude "README.md" --exclude ".gitignore" --exclude "entities/" --exclude "app_info.json" blackphp/ $1/ | grep "files transferred" | cut -c 38-`
	#Realiza la sincronización
	rsync -av --exclude ".git/" --exclude ".vscode" --exclude "db/" --exclude "README.md" --exclude ".gitignore" --exclude "entities/"  --exclude "app_info.json" blackphp/ $1/
else
	# Comprueba la cantidad de archivos a transferir
	files=`rsync -rcn --stats --exclude ".git/" --exclude ".vscode" --exclude "db/" --include "controllers/devUtils.php" --include "controllers/error.php" --include "controllers/Resources.php" --exclude "controllers/*" --exclude "public/icons" --exclude "public/images" --exclude "favicon.ico" --exclude "models/" --exclude "README.md" --exclude "views/*" --exclude ".gitignore" --exclude "entities/" --exclude "locale/" --exclude "app_info.json" --exclude "/config.php" --exclude "public/manifest.json" blackphp/ $1/ | grep "files transferred" | cut -c 38-`
	# Si la cantidad de archivos a transferir es mayor que cero, realiza la sincronización, de lo contrario, imprime "Up to date".
	files=`echo $files | sed -e 's/,//'`
	if [ $files -gt "0" ]; then
		rsync -rc --exclude ".git/" --exclude ".vscode" --exclude "db/" --include "controllers/devUtils.php" --include "controllers/error.php" --include "controllers/Resources.php" --exclude "controllers/*" --exclude "public/icons" --exclude "public/images" --exclude "favicon.ico" --exclude "models/" --exclude "README.md" --exclude "views/*" --exclude ".gitignore" --exclude "entities/" --exclude "locale/" --exclude "app_info.json" --exclude "/config.php" --exclude "manifest.json" --exclude "/node_modules" --exclude "/vendor" --info=NAME1 blackphp/ $1/
		rsync -a --delete --info=NAME1 blackphp/node_modules/ $1/node_modules/
		rsync -a --delete --info=NAME1 blackphp/vendor/ $1/vendor/
	fi
fi
# Si al final de la operación sí hubo transferencia de archivos, ya sea a un proyecto existente o uno nuevo, entonces se agrega el archivo black_php.json en el destino, con información acerca de la fecha y hora de la última actualización.
if [ $files -gt "0" ]; then
	rsync blackphp/app_info.json $1/blackphp_info.json
	echo "    $files files updated."
fi
