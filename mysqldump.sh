#!/bin/bash

# Volcado de tablas y datos iniciales en las bases de datos de los proyectos

# Realiza un volcado de la estructura de las bases de datos y los datos iniciales a archivos separados por cada proyecto. Se consideran datos iniciales en una base de datos, los contenidos en todas las tablas que inician con app_*

#Cargando configuración inicial
script_path=`realpath $0`
script_dir=`dirname $script_path`
temp_path=`jq -r ".temp_path" $script_dir/config.json`
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
db_host=`jq -r ".db_host" $1`
db_user=`jq -r ".db_user" $1`
db_password=`jq -r ".db_password" $1`
database=`jq -r ".database" $1`
db_prefix=`jq -r ".db_prefix" $1`
project_folder=`basename $project_path`

# Se guardan todos los volcados en una carpeta temporal, para luego comparar si hubieron cambios. Esto, para evitar que la sincronización en la nuble se repita si solo cambia la fecha de actualización.
temp_dir=$temp_path/mysqldump/$project_folder

# Comprueba si existe en el arreglo; sino, devolverá un error.
if [ ! -d "$temp_dir" ]; then
	mkdir -p $temp_dir
fi

echo "------------ MYSQLDUMP > $database to $project_folder"

# Navegamos hacia la carpeta db dentro del proyecto seleccionado
destiny_path=$project_path/db/mysql/
if [ ! -d "$destiny_path" ]; then
	mkdir -p $destiny_path
fi
cd $destiny_path
# Volcado de la estructura
# -> Se omite el valor de AUTO_INCREMENT
# -> Se omite el valor de DEFINER
# -> Se establece el valor de sql_mode en ''
# -> Se establece el valor de collation_connection en utf8mb4_general_ci
mysqldump -h $db_host -u $db_user -p$db_password -d --skip-dump-date $database | sed 's/ AUTO_INCREMENT=[0-9]*//g' | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | sed -E "s/(SET sql_mode\s+= ')(.*)(')/\1\3/" | sed "s/\`$database\`\.//g" | sed -E 's/utf8([a-z0-9_]+)_ci/utf8mb4_general_ci/g' > $temp_dir/db_structure.sql

# Volcado de los valores de todas las tablas que inician con app_*
db_prefix=`echo $db_prefix | sed 's/_/\\\\_/g'`
mysqldump -h $db_host -u $db_user -p$db_password -t --skip-dump-date --skip-triggers $database $(mysql -h $db_host -u $db_user -p$db_password -D $database -Bse "SHOW TABLES LIKE '"$db_prefix"app\_%'") > $temp_dir/initial_data.sql

# Se comprueba que exista un archivo previo de la estructura, y que es diferente. Si el archivo no existe, se crea.
result=`rsync -c --info=NAME1 "$temp_dir/db_structure.sql" ./db_structure.sql`
if [ "$result" != "" ]; then
	echo $result
	$script_dir/camel_case_orm_generator.sh "$1"
fi
# Se comprueba que exista un archivo previo de los datos iniciales, y que es diferente. Si el archivo no existe, se crea.
rsync -c --info=NAME1 "$temp_dir/initial_data.sql" ./initial_data.sql
