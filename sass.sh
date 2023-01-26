#!/bin/bash

# Compilador de sass

# REQUERIMIENTOS
# sass (npm install -g sass)

# Navegar hacia el directorio de BlackPHP donde se encuentrasn las hojas de estilos
dir=/store/Clouds/Mega/www/blackphp/public
temp_folder=/store/bphp/css
if [ ! -d $temp_folder ]; then
	mkdir -p $temp_folder
fi

cd $dir/styles

echo "------------ Compile SASS"
declare -A themes
themes[blue]="styles"
themes[black]="themes/black/styles"
themes[green]="themes/green/styles"
themes[blue_top]="themes/blue_top/styles"
themes[white]="themes/white/styles"
for theme in "${!themes[@]}"; do
	theme_folder=$temp_folder/${themes[$theme]}
	if [ ! -d $theme_folder ]; then
		mkdir -p $theme_folder
	fi
	sass --no-source-map --style=compressed theme_$theme.scss $theme_folder/theme.min.css
done
rsync -rc --info=NAME1 $temp_folder/ $dir/
