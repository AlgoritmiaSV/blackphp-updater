#!/bin/bash
#Cargando configuración inicial
script_path=`realpath $0`
script_dir=`dirname $script_path`
#temp_path=`jq -r ".temp_path" $script_dir/config.json`
config_files=$script_dir/projects
cd $config_files

# Si se ejecuta sin parámetros, se hace un volcado de todas las bases de datos definidas en el arreglo; sino, se realiza sólo de las que han sido especificadas.
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
project_folder=`basename $project_path`
git_path=/store/Gits/mvc/$project_folder

echo "------------ Update git local in $project_name"
cd $git_path
git pull --rebase
rsync -rc --delete --info=NAME1 $git_path/.git/ $project_path/.git/
