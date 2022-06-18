#/bin/bash
# Actualizador de archivos de idioma

# En una lista definida $projects, se busca e cada proyecto, en la carpeta locale/, cada uno de los idiomas definidos en el arreglo $locales. Dentro de ella, se buscan los archivos messages.po, y se convierten a messages.mo, para luego poder ser accedidos por gettext

# REQUERIMIENTOS
# gettext

#Lista de proyectos
projects=(blackphp negkit sicoimWebApp acrossdesk mimakit velnet21WebApp)
#Lista de idiomas regionales
locales=(es_ES en_US)
for project in "${projects[@]}"; do
	echo "------------ Update language files in $project"
	for locale in "${locales[@]}"; do
		directory="/store/Clouds/Mega/www/$project/locale/$locale/LC_MESSAGES"
		if [ -d "$directory" ]; then
			cd $directory
			if [ "messages.po" -nt "messages.mo" ]; then
				msgfmt messages.po
				echo "    $locale Changed"
			else
				echo "    $locale Up to date"
			fi
		fi
	done
done
