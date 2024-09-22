#/bin/bash
# Actualizador de archivos de idioma

# En una lista definida $projects, se busca e cada proyecto, en la carpeta locale/, cada uno de los idiomas definidos en el arreglo $locales. Dentro de ella, se buscan los archivos messages.po, y se convierten a messages.mo, para luego poder ser accedidos por gettext

# REQUERIMIENTOS
# gettext

#Cargando configuración inicial
script_path=`realpath $0`
script_dir=`dirname $script_path`
temp_path=`jq -r ".temp_path" $script_dir/config.json`
config_files=$script_dir/projects
cd $config_files

# Si se ejecuta sin parámetros, se hace un volcado de todas las bases de datos definidas en el arreglo; sino, se realiza sólo de las que han sido especificadas.
if [ "$#" = "0" ]; then
	for config_file in `ls -I "_*"`
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
project_folder=`basename $project_path`
temp_dir=$temp_path/views/$project_folder

echo "------------ Checking image references in $project_folder"

# Directorio temporal
if [ ! -d "$temp_dir" ]; then
	mkdir -p "$temp_dir"
fi
cd $temp_dir

# Extrayendo imágenes de las vistas
grep -nrw "$project_path/libs/" -Ee 'view->render' | sed -E 's/(.*view->render\(["'\''])(.*)(["'\''].*)/\2/' | grep -v '\$' > referenced_views.txt
grep -nrw "$project_path/controllers/" -Ee 'view->render' | sed -E 's/(.*view->render\(["'\''])(.*)(["'\''].*)/\2/' | grep -v '\$' >> referenced_views.txt

# Ordenando las palabras en el archivo required, y eliminando las repetidas
sort -u -o referenced_views.txt referenced_views.txt

cd $project_path/views/
find . -name '*.html' | sed -E 's/\.\///g' | sed 's/.html//g' > $temp_dir/views.txt
sort -u -o $temp_dir/views.txt $temp_dir/views.txt
difference=`diff -y --suppress-common-lines $temp_dir/referenced_views.txt $temp_dir/views.txt`
if [ "$difference" != "" ]; then
	echo -e "REQUIRED\t\t\t\t\t\t\tUNNECESSARY"
	diff -y --suppress-common-lines $temp_dir/referenced_views.txt $temp_dir/views.txt
fi
