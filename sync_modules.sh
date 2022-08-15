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

usage()
{
	echo Available options:
	declare -F | awk {'print "\t" $3'}
}

#	Main
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
