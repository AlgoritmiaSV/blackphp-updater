#!/bin/bash
# BlackPHP

# Sincroniza archivos de BlackPHP con los diferentes proyectos derivados a fin de mantener el Framework actualizado en todos los proyectos.

# REQUERIMIENTOS
# jq (Paquete para lectura y creación de archivos JSON)

#Cargando configuración inicial
script_path=`realpath $0`
script_dir=`dirname $script_path`
blackphp_path=`jq -r ".blackphp_path" $script_dir/config.json`
config_files=$script_dir/projects
cd $config_files

# Se comprueba que se haya pasado por parámetro el nombre de la carpeta con la cual se quiere sincronizar, de lo contrario, sincronizará con una lista definida.
if [ "$#" = "0" ]; then
	for config_file in `ls -I _PROJECT_EXAMPLE.json`
	do
		$0 "$config_files/$config_file"
	done
	exit 1
fi

if [ ! -f "$1" ]; then
	echo "File $1 not exists!"
	exit 1
fi
project_name=`jq -r ".project_name" $1`
project_path=`jq -r ".project_path" $1`
if [ "$blackphp_path" = "$project_path" ]; then
	exit 1
fi
echo "------------ RSYNC BlackPHP > $project_name"
cd $blackphp_path/

# Establecemos fecha de actualización
last_update=`jq -r ".last_update" app_info.json`
modified=`find . -type f -newermt "$last_update" ! -name "app_info.json" ! -path "./node_modules/*" ! -path "./composer/*" ! -path "./.git/*" ! -path "./.vscode/*" | wc -l`
if [ $modified -gt "0" ]; then
	last_update=`date +"%Y-%m-%d %H:%M:%S"`
	version=`jq -r ".version" app_info.json`
	number=`jq -r ".number" app_info.json`
	number=$((number+1))
	copyright=`jq -r ".copyright" app_info.json`
	website=`jq -r ".website" app_info.json`
	jq -n --arg last_update "$last_update" \
			--arg version "$version" \
			--arg number "$number" \
			--arg copyright "$copyright" \
			--arg website "$website" \
	'{"system_name": "BlackPHP", "version": "\($version)", "number": "\($number)", "last_update": "\($last_update)", "copyright": "\($copyright)", "website": "\($website)"}' > app_info.json
fi

# Cantidad de archivos a modificar (Si es cero, no se actualiza)
files=0

# Comprueba que el directorio que se le ha pasado por parámetro, existe. De lo contrario, crea uno con una instalación limpia.
if [ ! -d "$project_path" ]
then
	# Instalación nueva. Crea un directorio
	mkdir -p $project_path
fi
# Comprueba si hay archivos en el directorio (Si no hay archivos, procede como instalación nueva)
existing_files=`ls $project_path | wc -l`
if [ "$existing_files" = "0" ]; then
	# Instalación nueva. Crea un directorio
	mkdir -p $project_path
	# Cuenta los archivos a transferir con rsync --stats (el parámetro n es esencial para no ejecutar de una vez)
	files=`rsync -avn --stats --exclude ".git/" --exclude ".vscode" --exclude "db/" --exclude "README.md" --exclude ".gitignore" --exclude "entities/" --exclude "app_info.json" $blackphp_path/ $project_path/ | grep "files transferred" | cut -c 38-`
	#Realiza la sincronización
	rsync -av --exclude ".git/" --exclude ".vscode" --exclude "db/" --exclude "README.md" --exclude ".gitignore" --exclude "entities/"  --exclude "app_info.json" $blackphp_path/ $project_path/
else
	# Comprueba la cantidad de archivos a transferir
	files=`rsync -rcn --stats --exclude ".git/" --exclude ".vscode" --exclude "db/" --include "controllers/devUtils.php" --include "controllers/error.php" --include "controllers/Resources.php" --exclude "controllers/*" --exclude "public/icons" --exclude "public/images" --exclude "favicon.ico" --exclude "models/" --exclude "README.md" --exclude "views/*" --exclude ".gitignore" --exclude "entities/" --exclude "locale/" --exclude "app_info.json" --exclude "/config.php" --exclude "public/manifest.json" $blackphp_path/ $project_path/ | grep "files transferred" | cut -c 38-`
	# Si la cantidad de archivos a transferir es mayor que cero, realiza la sincronización, de lo contrario, imprime "Up to date".
	files=`echo $files | sed -e 's/,//'`
	if [ $files -gt "0" ]; then
		rsync -rc --exclude ".git/" --exclude ".vscode" --exclude "db/" --include "controllers/devUtils.php" --include "controllers/error.php" --include "controllers/Resources.php" --exclude "controllers/*" --exclude "public/icons" --exclude "public/images" --exclude "favicon.ico" --exclude "models/" --exclude "README.md" --exclude "views/*" --exclude ".gitignore" --exclude "entities/" --exclude "locale/" --exclude "app_info.json" --exclude "/config.php" --exclude "manifest.json" --exclude "/node_modules" --exclude "/vendor" --info=NAME1 $blackphp_path/ $project_path/
		rsync -a --delete --info=NAME1 $blackphp_path/node_modules/ $project_path/node_modules/
		rsync -a --delete --info=NAME1 $blackphp_path/vendor/ $project_path/vendor/
	fi
fi
# Si al final de la operación sí hubo transferencia de archivos, ya sea a un proyecto existente o uno nuevo, entonces se agrega el archivo black_php.json en el destino, con información acerca de la fecha y hora de la última actualización.
if [ $files -gt "0" ]; then
	rsync $blackphp_path/app_info.json $project_path/blackphp_info.json
	echo "    $files files updated."
fi
