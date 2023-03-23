#/bin/bash
# Actualizador de archivos de idioma

# En una lista definida $projects, se busca e cada proyecto, en la carpeta locale/, cada uno de los idiomas definidos en el arreglo $locales. Dentro de ella, se buscan los archivos messages.po, y se convierten a messages.mo, para luego poder ser accedidos por gettext

# REQUERIMIENTOS
# gettext

# Lista de proyectos
projects=(blackphp negkit negkitContracts negkitProjects negkitServices sicoimWebApp mimakit fileManager inabve)

# Base de datos de cada proyecto
declare -A databases
databases[blackphp]=blackphp
databases[negkit]=negkit
databases[negkitContracts]=contracts
databases[negkitProjects]=projects
databases[negkitServices]=services
databases[sicoimWebApp]=sicoim
databases[mimakit]=mimakit
databases[fileManager]=files
databases[inabve]=inabve

# Lista de idiomas regionales
locales=(es_ES en_US)

for project in "${projects[@]}"; do
	echo "------------ Checking image references in $project"

	# Directorio temporal
	temp_directory="/store/bphp/images/$project"
	if [ ! -d $temp_directory ]; then
		mkdir -p $temp_directory
	fi
	cd $temp_directory

	# Selección de base de datos
	database=${databases[$project]}

	# Extrayendo palabras y frases de las vistas
	grep -nrw "/store/Clouds/Mega/www/$project/views/" -Ee 'images.*png' | sed -E 's/(.*src=\"public\/images\/)(.*png)(.*)/\2/' | grep -v '{{' > referenced_images.txt
	grep -nrw "/store/Clouds/Mega/www/$project/libs/" -Ee 'images.*png' | sed -E 's/(.*\"public\/images\/)(.*png)(.*)/\2/' | grep -v '\$' >> referenced_images.txt
	grep -nrw "/store/Clouds/Mega/www/$project/controllers/" -Ee 'images.*png' | sed -E 's/(.*\"public\/images\/)(.*png)(.*)/\2/' | grep -v '\$' >> referenced_images.txt

	# Extrayendo palabras y frases de las talas del sistema
	# -> Nombre de los módulos
	# -> Nombre de los métodos
	mysql --skip-column-names -u root -pldi14517 $database -e "SELECT CONCAT('outline/', module_icon, '.png') FROM app_modules WHERE status = 1 UNION ALL SELECT CONCAT(method_icon, '.png') FROM app_methods WHERE status = 1" >> referenced_images.txt

	# Ordenando las palabras en el archivo required, y eliminando las repetidas
	sort -u -o referenced_images.txt referenced_images.txt

	cd /store/Clouds/Mega/www/$project/public/images/
	find . -name '*.png' ! -path './files/*' | sed -E 's/\.\///g' > $temp_directory/images.txt
	sort -u -o $temp_directory/images.txt $temp_directory/images.txt
	difference=`diff -y --suppress-common-lines $temp_directory/referenced_images.txt $temp_directory/images.txt`
	if [ "$difference" != "" ]; then
		echo -e "REQUIRED\t\t\t\t\t\t\tUNNECESSARY"
		diff -y --suppress-common-lines $temp_directory/referenced_images.txt $temp_directory/images.txt
	fi
done
