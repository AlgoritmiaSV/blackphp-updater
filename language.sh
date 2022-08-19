#/bin/bash
# Actualizador de archivos de idioma

# En una lista definida $projects, se busca e cada proyecto, en la carpeta locale/, cada uno de los idiomas definidos en el arreglo $locales. Dentro de ella, se buscan los archivos messages.po, y se convierten a messages.mo, para luego poder ser accedidos por gettext

# REQUERIMIENTOS
# gettext

#Lista de proyectos
projects=(blackphp negkit sicoimWebApp acrossdesk mimakit)
#Lista de idiomas regionales
locales=(es_ES en_US)
for project in "${projects[@]}"; do
	echo "------------ Update language files in $project"
	for locale in "${locales[@]}"; do
		temp_directory="/store/blackphp/locale/$project/$locale"
		directory="/store/Clouds/Mega/www/$project/locale/$locale/LC_MESSAGES"
		if [ -d "$directory" ]; then
			cd $directory
			php /store/Clouds/Mega/insp_storage/2022/Algoritmia/blackphp_updater/po_sort.php $directory/messages.po $temp_directory/messages.po
			rsync -c --info=NAME1 $temp_directory/messages.po $directory/messages.po
			if [ "messages.po" -nt "messages.mo" ]; then
				msgfmt messages.po
				echo "    $locale Changed"
			else
				echo "    $locale Up to date"
			fi
		fi
	done
done
