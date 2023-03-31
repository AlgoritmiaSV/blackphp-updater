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
project_folder=`basename $project_path`
temp_dir=$temp_path/images/$project_folder

echo "------------ Checking image references in $project_folder"

# Directorio temporal
if [ ! -d "$temp_dir" ]; then
	mkdir -p "$temp_dir"
fi
cd $temp_dir

# Extrayendo palabras y frases de las vistas
grep -nrw "$project_path/views/" -Ee 'images.*png' | sed -E 's/(.*src=\"public\/images\/)(.*png)(.*)/\2/' | grep -v '{{' > referenced_images.txt
grep -nrw "$project_path/libs/" -Ee 'images.*png' | sed -E 's/(.*\"public\/images\/)(.*png)(.*)/\2/' | grep -v '\$' >> referenced_images.txt
grep -nrw "$project_path/controllers/" -Ee 'images.*png' | sed -E 's/(.*\"public\/images\/)(.*png)(.*)/\2/' | grep -v '\$' >> referenced_images.txt

# Extrayendo palabras y frases de las talas del sistema
# -> Nombre de los módulos
# -> Nombre de los métodos
mysql --skip-column-names -h $db_host -u $db_user -p$db_password $database -e "SELECT CONCAT('outline/', module_icon, '.png') FROM app_modules WHERE status = 1 UNION ALL SELECT CONCAT(method_icon, '.png') FROM app_methods WHERE status = 1" >> referenced_images.txt

# Ordenando las palabras en el archivo required, y eliminando las repetidas
sort -u -o referenced_images.txt referenced_images.txt

cd $project_path/public/images/
find . -name '*.png' ! -path './files/*' | sed -E 's/\.\///g' > $temp_dir/images.txt
sort -u -o $temp_dir/images.txt $temp_dir/images.txt
difference=`diff -y --suppress-common-lines $temp_dir/referenced_images.txt $temp_dir/images.txt`
if [ "$difference" != "" ]; then
	echo -e "REQUIRED\t\t\t\t\t\t\tUNNECESSARY"
	diff -y --suppress-common-lines $temp_dir/referenced_images.txt $temp_dir/images.txt
fi
