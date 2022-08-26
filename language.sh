#/bin/bash
# Actualizador de archivos de idioma

# En una lista definida $projects, se busca e cada proyecto, en la carpeta locale/, cada uno de los idiomas definidos en el arreglo $locales. Dentro de ella, se buscan los archivos messages.po, y se convierten a messages.mo, para luego poder ser accedidos por gettext

# REQUERIMIENTOS
# gettext

#Lista de proyectos
projects=(blackphp negkit sicoimWebApp acrossdesk mimakit)
declare -A databases
databases[blackphp]=blackphp
databases[negkit]=negkit
databases[sicoimWebApp]=sicoim
databases[acrossdesk]=acrossdesk
databases[mimakit]=mimakit
#Lista de idiomas regionales
locales=(es_ES en_US)
for project in "${projects[@]}"; do
	echo "------------ Update language files in $project"
	temp_directory="/store/bphp/locale/$project"
	cd $temp_directory
	grep -nrw "/store/Clouds/Mega/www/$project/views/" -Ee '_\([^\)]+\)' | sed -E 's/\)/\)\n/g' | grep -Ee '_\([^\)]+\)' | sed -E 's/(.*_\()([^\)]*)(\).*)/\2/' | grep -v '{{' > required.txt
	grep -nrw "/store/Clouds/Mega/www/$project/controllers/" -Ee '_\([^\)]+\)'  | sed -E 's/\)/\)\n/g' | grep -Ee '_\([^\)]+\)' | sed -E 's/(.*_\(\")([^\)]*)(\"\).*)/\2/' | grep -v '/store/Clouds/' >> required.txt
	mysql --skip-column-names -u root -pldi14517 ${databases[$project]} -e "SELECT module_name FROM app_modules WHERE status = 1 UNION SELECT method_name FROM app_methods WHERE status = 1 UNION SELECT theme_name FROM app_themes UNION SELECT method_description FROM app_methods WHERE status = 1" >> required.txt
	app_payments=`mysql --skip-column-names -u root -pldi14517 information_schema -e "SELECT 1 FROM TABLES WHERE TABLE_SCHEMA = '${databases[$project]}' AND TABLE_NAME = 'app_payments'"`
	if [ "$app_payments" = "1" ]; then
		mysql --skip-column-names -u root -pldi14517 ${databases[$project]} -e "SELECT CONCAT('payments', ptype_name) FROM app_payments" >> required.txt
	fi
	sort -u -o required.txt required.txt
	for locale in "${locales[@]}"; do
		temp_directory="/store/bphp/locale/$project/$locale"
		directory="/store/Clouds/Mega/www/$project/locale/$locale/LC_MESSAGES"
		if [ -d "$directory" ]; then
			cd $directory
			php /store/Clouds/Mega/insp_storage/2022/Algoritmia/blackphp_updater/po_sort.php $project $locale
			rsync -c $temp_directory/messages.po $directory/messages.po
			if [ "messages.po" -nt "messages.mo" ]; then
				msgfmt messages.po
				echo "$locale Changed"
			#else
			#	echo "$locale Up to date"
			fi
		fi
	done
done
