#/bin/bash
# Actualizador de archivos de idioma

# En una lista definida $projects, se busca e cada proyecto, en la carpeta locale/, cada uno de los idiomas definidos en el arreglo $locales. Dentro de ella, se buscan los archivos messages.po, y se convierten a messages.mo, para luego poder ser accedidos por gettext

# REQUERIMIENTOS
# gettext

# Lista de proyectos
projects=(blackphp negkit sicoimWebApp mimakit fileManager)

# Base de datos de cada proyecto
declare -A databases
databases[blackphp]=blackphp
databases[negkit]=negkit
databases[sicoimWebApp]=sicoim
databases[mimakit]=mimakit
databases[fileManager]=files

# Lista de idiomas regionales
locales=(es_ES en_US)

for project in "${projects[@]}"; do
	echo "------------ Update language files in $project"

	# Directorio temporal
	temp_directory="/store/bphp/locale/$project"
	if [ ! -d $temp_directory ]; then
		mkdir -p $temp_directory
	fi
	cd $temp_directory

	# Selección de base de datos
	database=${databases[$project]}

	# Extrayendo palabras y frases de las vistas
	grep -nrw "/store/Clouds/Mega/www/$project/views/" -Ee '_\([^\)]+\)' | sed -E 's/\)/\)\n/g' | grep -Ee '_\([^\)]+\)' | sed -E 's/(.*_\()([^\)]*)(\).*)/\2/' | grep -v '{{' > required.txt

	# Extrayendo palabras y frases del núcleo del sistema
	grep -nrw "/store/Clouds/Mega/www/$project/libs/" -Ee '_\([^\)]+\)'  | sed -E 's/\)/\)\n/g' | grep -Ee '_\([^\)]+\)' | sed -E 's/(.*_\(\")([^\)]*)(\"\).*)/\2/' | grep -v '/store/Clouds/' | grep -Ev '\$|_\(' >> required.txt
	grep -nrw "/store/Clouds/Mega/www/$project/utils/" -Ee '_\([^\)]+\)'  | sed -E 's/\)/\)\n/g' | grep -Ee '_\([^\)]+\)' | sed -E 's/(.*_\(\")([^\)]*)(\"\).*)/\2/' | grep -v '/store/Clouds/' >> required.txt

	# Extrayendo palabras y frases de los controladores
	grep -nrw "/store/Clouds/Mega/www/$project/controllers/" -Ee '_\([^\)]+\)'  | sed -E 's/\)/\)\n/g' | grep -Ee '_\([^\)]+\)' | sed -E 's/(.*_\(\")([^\)]*)(\"\).*)/\2/' | grep -v '/store/Clouds/' >> required.txt

	# Extrayendo palabras y frases de las talas del sistema
	# -> Nombre de los módulos
	# -> Nombre de los métodos
	# -> Descripción de los métodos
	# -> Nombre de los temas
	# -> Nombre singular y plural de los elementos
	mysql --skip-column-names -u root -pldi14517 $database -e "SELECT module_name FROM app_modules WHERE status = 1 UNION ALL SELECT method_name FROM app_methods WHERE status = 1 UNION ALL SELECT theme_name FROM app_themes UNION ALL SELECT method_description FROM app_methods WHERE status = 1 UNION ALL SELECT element_name FROM app_elements UNION ALL SELECT singular_name FROM app_elements" >> required.txt

	# Evaluando si existe la tabla app_payments
	app_payments=`mysql --skip-column-names -u root -pldi14517 information_schema -e "SELECT 1 FROM TABLES WHERE TABLE_SCHEMA = '$database' AND TABLE_NAME = 'app_payments'"`
	if [ "$app_payments" = "1" ]; then
		# Extrayendo las formas de pago de la base de datos
		mysql --skip-column-names -u root -pldi14517 $database -e "SELECT CONCAT('payments', ptype_name) FROM app_payments" >> required.txt
	fi

	# Ordenando las palabras en el archivo required, y eliminando las repetidas
	sort -u -o required.txt required.txt

	for locale in "${locales[@]}"; do
		temp_directory="/store/bphp/locale/$project/$locale"
		if [ ! -d $temp_directory ]; then
			mkdir -p $temp_directory
		fi
		directory="/store/Clouds/Mega/www/$project/locale/$locale/LC_MESSAGES"
		if [ -d "$directory" ]; then
			cd $directory
			php /store/Clouds/Mega/insp_storage/2023/Algoritmia/blackphp_updater/po_sort.php $project $locale
			rsync -c $temp_directory/messages.po $directory/messages.po
			if [ "messages.po" -nt "messages.mo" ]; then
				msgfmt messages.po
				echo "$locale Changed"
			fi
		fi
	done
done
