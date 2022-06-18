#!/bin/bash

# Monificador de javascript y jQuery con la API toptal.com

# REQUERIMIENTOS
# wget

# Navegar hacia el directorio de BlackPHP donde se encuentrasn los scripts
dir=/store/Clouds/Mega/www/blackphp/public/scripts
cd $dir

# Verificar cuáles de los scipt son más nuevos que el último bpscript.min.js generado.
scripts=(main lists forms dialogs order tree charts)
modified=false
echo "------------ Minify JS"
# Imprime la fecha y hora de última generación de bpscript.min.js
echo "    bpscript.min.js last update: `stat -c %y bpscript.min.js`"
for i in "${scripts[@]}"; do
	if [ "$i.js" -nt bpscript.min.js ]; then
		echo "    $i.js Modified"
		modified=true
	fi
done
# Si hay al menos un archivo nuevo, entonces se hace de nuevo el proceso de minificación; de lo contrario, imprime "All up to date"
if $modified; then
	echo "/*BlackPHP (c)2022 Edwin Fajardo.*/" > $dir/bpscript.min.js
	for i in ${scripts[@]}; do
		echo "    Minify $i"
		wget -q --post-data="input=`php -r \"echo urlencode(file_get_contents(\\\"$i.js\\\"));\"`" -O - https://www.toptal.com/developers/javascript-minifier/api/raw >> $dir/bpscript.min.js
		echo ";" >> $dir/bpscript.min.js
	done
else
	echo "    All up to date"
fi
