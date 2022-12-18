#!/bin/bash
cash()
{
	rsync -ac --info=NAME1 $1/controllers/Cash.php $2/controllers/Cash.php
	rsync -acr --delete --info=NAME1 $1/views/cash/ $2/views/cash/
}

catalog()
{
	rsync -ac --info=NAME1 $1/controllers/Catalog.php $2/controllers/Catalog.php
	rsync -acr --delete --info=NAME1 $1/views/catalog/ $2/views/catalog/
}

sales()
{
	rsync -ac --info=NAME1 $1/controllers/Sales.php $2/controllers/Sales.php
	rsync -acr --delete --info=NAME1 $1/views/sales/ $2/views/sales/
}

purchases()
{
	rsync -ac --info=NAME1 $1/controllers/Purchases.php $2/controllers/Purchases.php
	rsync -acr --delete --info=NAME1 $1/views/purchases/ $2/views/purchases/
}

user()
{
	rsync -ac --info=NAME1 $1/controllers/User.php $2/controllers/User.php
	rsync -acr --delete --info=NAME1 $1/views/user/ $2/views/user/
}

index()
{
	rsync -ac --info=NAME1 $1/controllers/index.php $2/controllers/index.php
}

reports()
{
	rsync -ac --info=NAME1 $1/controllers/Reports.php $2/controllers/Reports.php
	rsync -acr --delete --info=NAME1 $1/views/reports/ $2/views/reports/
}

settings()
{
	rsync -ac --info=NAME1 $1/controllers/Settings.php $2/controllers/Settings.php
	rsync -acr --delete --info=NAME1 --exclude "info_details.html" $1/views/settings/ $2/views/settings/
}

usage()
{
	echo Available options:
	declare -F | awk {'print "\t" $3'}
}

all()
{
	options=`declare -F | awk {'print $3'}`
	for option in $options; do
		if [ "$option" == "all" -o "$option" == "usage" ]; then
			continue
		fi
		$option $1 $2
	done
}

#	Main
# Se requieren permisos de root (Sólo en Linux)
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	command="${0} ${@}"
	su -c "$command"
	exit 1
fi
source=/store/Clouds/Mega/www/negkit
destiny=/store/Clouds/Mega/www/mimakit
if [ "$#" = "0" ]; then
	usage
else
	while [ "$#" -gt "0" ]; do
		if [ `type -t $1`"" == 'function' ]; then
			$1 $source $destiny
		else
			echo "Unrecognized parametter $1"
			usage
		fi
		shift
	done
fi
