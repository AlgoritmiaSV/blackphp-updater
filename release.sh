#!/bin/bash

# Creación de una versión de lanzamiento de proyectos derivados de BlackPHP

# El objetivo de este script es generar una versión de lanzamiento de los proyectos, sin comentarios, sin archivos propios de las entidades, y con todos los archivos minificados (PHP, CSS, HTML y JavaScripts), listo para subir a la web, actualizarlo en otro servidor, o llevarlo en formato zip.
# Los Javascript no se minifican aquí, porque antes de esto debió realizarse el poceso de minificación de archivos JS que está en otro de los scripts

# Para esta operación, se necesitan permisos de root (Sólo en Linux)
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	command="${0} ${@}"
	su -c "$command"
	exit 1
fi

# Si no se especifica un parámetro, se realiza una versión de lanzamiento de cada proyecto
if [ "$#" = "0" ]; then
	for folder in blackphp mimakit negkit negkitContracts negkitProjects negkitServices sicoimWebApp fileManager inabve
	do
		$0 $folder
	done
	exit 1
fi
echo "------------ Releasing $1"

# Carpeta origen del proyecto
source=/store/Clouds/Mega/www/$1

# Comprobar si existe la carpeta origen
if [ ! -d $source ]; then
	echo "Project $1 not exists!"
	exit 1
fi

# Carpeta de producción, donde se encontrarán los archivos resultantes
production=/store/bphp/production/$1
if [ ! -d $production ]; then
	mkdir -p $production
fi

# Todos los lanzamientos. En esta carpeta estarán los archivos zip de cada vez que se ejecute el script
releases=/store/bphp/releases/$1
if [ ! -d $releases ]; then
	mkdir -p $releases
fi

# Creación de un archivo JSON con la fecha de lanzamiento
cd $source
echo "    Setting date..."
last_update=`date +"%Y-%m-%d %H:%M:%S"`
version=`jq -r ".version" app_info.json`
number=`jq -r ".number" app_info.json`
number=$((number+1))
system_name=`jq -r ".system_name" app_info.json`
copyright=`jq -r ".copyright" app_info.json`
website=`jq -r ".website" app_info.json`
jq -n --arg last_update "$last_update" \
		--arg version "$version" \
		--arg number "$number" \
		--arg system_name "$system_name" \
		--arg copyright "$copyright" \
		--arg website "$website" \
'{"system_name": "\($system_name)", "version": "\($version)", "number": "\($number)", "last_update": "\($last_update)", "copyright": "\($copyright)", "website": "\($website)"}' > app_info.json

# Sincronización de archivos no sujetos a minificación, como las imágenes, fuentes, y archivos que previamente hayan sido minificados
echo "    Syncing..."
rsync -cr --delete --chown=fajardo:fajardo --chmod=D755,F644 --exclude ".git" --exclude ".gitignore" --exclude "companies/" --exclude "entities/" --exclude "db/historical/" --exclude "/docs/" --exclude "node_modules/" --include "default_config.php" --exclude "*.php" --include "public/scripts/*.min.js" --include "public/scripts/serviceWorker.js" --exclude "public/scripts/*" --exclude "*.html" --include "*.min.css" --exclude "*.css" --exclude "CHANGELOG.*" --exclude "changelog.*" --exclude "*.scss" --exclude "bower.json" --exclude "composer.json" --exclude "composer.lock" --exclude "package.json" --exclude "package-lock.json" --exclude "messages.po" --info=NAME1 $source/ $production/

# Minificación y copia de archivos PHP
echo "    Minifying PHP..."
while read -r php_file; do
	if [ ! -f "$production/$php_file" -o "$source/$php_file" -nt "$production/$php_file" ]; then
		/usr/bin/php -w $source/$php_file > $production/$php_file
		echo "    $php_file"
	fi
done < <(find . -type f -name "*.php" ! -name "default_config.php" ! -path "./entities/*")

# Minificación y copia de archivos CSS
echo "    Minifying CSS..."
while read -r css_file; do
	if [ ! -f "$production/$css_file" -o "$source/$css_file" -nt "$production/$css_file" ]; then
		echo "    $css_file"
		cat $css_file | sed -e "s|/\*\(\\\\\)\?\*/|/~\1~/|g" -e "s|/\*[^*]*\*\+\([^/][^*]*\*\+\)*/||g" -e "s|\([^:/]\)//.*$|\1|" -e "s|^//.*$||" | tr '\n' ' ' | sed -e "s|/\*[^*]*\*\+\([^/][^*]*\*\+\)*/||g" -e "s|/\~\(\\\\\)\?\~/|/*\1*/|g" -e "s|\s\+| |g" -e "s| \([{;:,]\)|\1|g" -e "s|\([{;:,]\) |\1|g" > $production/$css_file
	fi
done < <(find . -type f -name "*.css" ! -name "*.min.css" ! -path "./node_modules/*")

# Minificación y copia de archivos HTML
echo "    Minifying HTML..."
while read -r html_file; do
	if [ ! -f "$production/$html_file" -o "$source/$html_file" -nt "$production/$html_file" ]; then
		cat $html_file | sed ':a;N;$!ba;s/>\s*</></g' > $production/$html_file
		echo "    $html_file"
	fi
done < <(find . -type f -name "*.html" ! -path "./node_modules/*")

# Exportando node_modules; sólo las carpetas de distribución.
node_dir=/store/bphp/node_modules
if [ ! -d $node_dir ]; then
	mkdir -p $node_dir
fi
node_folders=$node_dir/$1.txt
for i in `cat $source/libs/View.php | grep "node_modules" | tr -d "'" | tr -d ","`; do
	dirname $i >> $node_folders
done
sort -u -o $node_folders $node_folders
for i in `cat $node_folders`; do
	if [ ! -d $production/$i/ ]; then
		mkdir -p $production/$i/
	fi
	rsync -cr --delete --exclude "docs" --chown=fajardo:fajardo --chmod=D755,F644 --info=NAME1 $source/$i/ $production/$i/
done

# Navegando hacia la carppeta de producción
cd $production

# Eliminando archivos innecesarios
# La comprobación de pwd y $production se hace para evitar eliminar algun archivo por error
# en caso de que cd $production haya fallado
if [ "`pwd`" = "$production" ]; then
	while read -r file_name; do
		if [ ! -f "$source/$file_name" ] && [ ! -d "$source/$file_name" ]; then
			rm -rv $file_name
		fi
	done < <(find .)
fi

# Compresión en un archivo zip que irá a la carpeta releases
zip_file=$releases/release_`/bin/date +\%Y\%m\%d\%H\%M\%S`.zip
zip -rqdg $zip_file ./
chown -R fajardo:fajardo $production/
chown -R fajardo:fajardo $releases/
