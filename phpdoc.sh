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
titles[negkitContracts]="NegKit Contracts"
titles[negkitProjects]="NegKit Projects"
titles[negkitServices]="NegKit Services"
titles[sicoimWebApp]=SICOIM
titles[mimakit]=MimaKit
titles[fileManager]="File Manager"
titles[inabve]="INABVE"

# Si no se le ha pasado ningún parámetro, entonces se ejecuta con todos los proyectos definidos en los arreglos.
if [ "$#" = "0" ]; then
	for folder in ${!titles[@]}
	do
		$0 $folder
	done
	exit 1
fi

# Compueba que el nombre de la carpeta pasada por parámetro exista en el arrego $titles, y si es así, se genera la documentación, de lo contrario devuelve un error.
echo "------------ Generating documentation for $1"
if [ -v titles[$1] ]; then
	if [ ! -d /store/bphp/documentation/$1/ ]; then
		mkdir -p /store/bphp/documentation/$1/
	fi
	phpdoc -d /store/Clouds/Mega/www/$1/ -t /store/bphp/documentation/$1/ -i vendor/ -i plugins/ --title "${titles[$1]}" --setting="guides.enabled=true"
else
	echo "Error: $1 NOT EXISTS"
fi

# (Sólo en Linux) Deben actualizarse los permisos de la documentación generada para que sea accesible por el usuario que inicia sesión en la interfaz gráfica.
cd /store/bphp/documentation/
chown -R fajardo:fajardo *
