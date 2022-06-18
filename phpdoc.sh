#!/bin/bash
#
# Generación de documentación con PHP Documentor
#
# Genera la documentación de cada proyecto en formato HTML. Lea las instrucciones de PHP Documentor para informarse de la forma en que deben redactarse los comentarios dentro de los archivos PHP

# REQUERIMIENTOS
# PHP Documentor

# Títulos (nombres) de los sistemas en los que se generará la documentación
declare -A titles
titles[blackphp]="Black PHP"
titles[negkit]=NegKit
titles[sicoim]=SICOIM
titles[acrossdesk]="Across Desk"
titles[mimakit]=MimaKit
titles[velnet21]="VELNET 21 Web App"

# Carpeta en donde se guardará la información de cada proyecto
declare -A folders
folders[blackphp]=blackphp
folders[negkit]=negkit
folders[sicoim]=sicoimWebApp
folders[acrossdesk]=acrossdesk
folders[mimakit]=mimakit
folders[velnet21]=velnet21WebApp

# Si no se le ha pasado ningún parámetro, entonces se ejecuta con todos los proyectos definidos en los arreglos.
if [ "$#" = "0" ]; then
	for folder in ${!folders[@]}
	do
		$0 $folder
	done
	exit 1
fi

# Compueba que el nombre de la carpeta pasada por parámetro exista en el arrego $titles, y si es así, se genera la documentación, de lo contrario devuelve un error.
if [ -v titles[$1] ]; then
	echo "------------ Generating documentation for ${titles[$1]}"
	phpdoc -d /store/Clouds/Mega/www/${folders[$1]}/ -t /store/blackphp/documentation/${folders[$1]}/ -i vendor/ -i plugins/ --title "${titles[$1]}" --setting="guides.enabled=true"
else
	echo "    Error: $1 NOT EXISTS"
fi

# (Sólo en Linux) Deben actualizarse los permisos de la documentación generada para que sea accesible por el usuario que inicia sesión en la interfaz gráfica.
cd /store/blackphp/documentation/
chown -R fajardo:fajardo *
