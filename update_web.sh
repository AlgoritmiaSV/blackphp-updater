#!/bin/bash

# Ejecución de scripts de BlackPHP Updater

# Se requieren permisos de root (Sólo en Linux)
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	command="${0} ${@}"
	su -c "$command"
	exit 1
fi

# Ruta de los scripts
echo "Update web"
path=/store/Clouds/Mega/insp_storage/2022/Algoritmia/blackphp_updater

# Ejecución
$path/minify_js.sh
$path/blackphp.sh
$path/mysqldump.sh
$path/language.sh
$path/orm_generator.sh
#cd /home/fajardo
./init.sh -p
