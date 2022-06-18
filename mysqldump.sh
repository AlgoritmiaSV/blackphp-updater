#!/bin/bash

# Volcado de tablas y datos iniciales en las bases de datos de los proyectos

# Realiza un volcado de la estructura de las bases de datos y los datos iniciales a archivos separados por cada proyecto. Se consideran datos iniciales en una base de datos, los contenidos en todas las tablas que inician con app_*

# Para cada nombre de base de datos (Clave) se define un directorio (Valor)
declare -A folders
folders[blackphp]=blackphp
folders[negkit]=negkit
folders[sicoim]=sicoimWebApp
folders[acrossdesk]=acrossdesk
folders[mimakit]=mimakit
folders[velnet21]=velnet21WebApp
folders[rtinfo]=rtinfo

# Si se ejecuta sin parámetros, se hace un volcado de todas las bases de datos definidas en el arreglo; sino, se realiza sólo de las que han sido especificadas.
if [ "$#" = "0" ]; then
	$0 ${!folders[@]}
	exit 1
fi

# Se guardan todos los volcados en una carpeta temporal, para luego comparar si hubieron cambios. Esto, para evitar que la sincronización en la nuble se repita si solo cambia la fecha de actualización.
temp_dir=/store/Local/temp/mysqldump
# Por cada nombre de base de datos recibida por parámetro...
for db in "$@"; do
	# Comprueba si existe en el arreglo; sino, devolverá un error.
	if [ -v folders[$db] ]; then
		echo "------------ MYSQLDUMP > $db to ${folders[$db]}"

		# Navegamos hacia la carpeta db dentro del proyecto seleccionado
		cd /store/Clouds/Mega/www/${folders[$db]}/db/

		# Volcado de la estructura, sin el valor de AUTO_INCREMENT
		mysqldump -u root -pldi14517 -d --skip-dump-date $db | sed 's/ AUTO_INCREMENT=[0-9]*//g' > $temp_dir/db_structure.sql

		# Volcado de los valores de todas las tablas que inician con app_*
		mysqldump -u root -pldi14517 -t --skip-dump-date $db $(mysql -u root -pldi14517 -D $db -Bse "SHOW TABLES LIKE 'app_%'") > $temp_dir/initial_data.sql

		# Se comprueba que exista un archivo previo de la estructura, y que es diferente. Si el archivo no existe, se crea.
		if [ -f "db_structure.sql" ]; then
			if cmp --silent -- "db_structure.sql" "$temp_dir/db_structure.sql"; then
				echo "    Structure is up to date"
			else
				echo "    Structure changed"
				cp "$temp_dir/db_structure.sql" ./db_structure.sql
			fi
		else
			echo "    Structure created"
			cp "$temp_dir/db_structure.sql" ./db_structure.sql
		fi

		# Se comprueba que exista un archivo previo de los datos iniciales, y que es diferente. Si el archivo no existe, se crea.
		if [ -f "initial_data.sql" ]; then
			if cmp --silent -- "initial_data.sql" "$temp_dir/initial_data.sql"; then
				echo "    Data is up to date"
			else
				echo "    Data changed"
				cp "$temp_dir/initial_data.sql" ./initial_data.sql
			fi
		else
			echo "    Data created"
			cp "$temp_dir/initial_data.sql" ./initial_data.sql
		fi
	else
		echo "    ERROR > $db NOT EXISTS"
	fi
done
