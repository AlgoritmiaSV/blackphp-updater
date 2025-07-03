#!/bin/bash
# upload $1 $source $destiny $host $port $user $read_logs
upload()
{
	if [ "$7" = "true" ]; then
		echo Reading error_log
		ssh -p $5 $6@$4 "cat $3/error_log"
	fi
	if [ "$1" = "true" ]; then
		rsync -crv -e "ssh -p $5" --delete \
			--exclude 'config.php' \
			--exclude 'entities/' \
			--exclude 'db/' \
			$2 $6@$4:$3
	else
		rsync -crv -e "ssh -p $5" --delete \
			--exclude 'config.php' \
			--exclude 'entities/' \
			--exclude 'db/' \
			--exclude 'node_modules/' \
			--exclude 'vendor/' \
			$2 $6@$4:$3
	fi
	echo Completed Succefully!
	echo -n Synced at:
	date +"%Y-%m-%d %H:%M:%S"
}

usage()
{
	echo Available options:
	script_path=`realpath $0`
	script_dir=`dirname $script_path`
	cat $script_dir/rsync.json | jq -c '.[]' |
	while IFS=$"\n" read -r c; do
		sync_name=$(echo "$c" | jq -r '.sync_name')
		description=$(echo "$c" | jq -r '.description')
		printf "%14s: %s\n" "$sync_name" "$description"
	done
	echo "            -n: Ommit vendor and node_modules"
}

searchProject()
{
	script_path=`realpath $0`
	script_dir=`dirname $script_path`
	cat $script_dir/rsync.json | jq -c '.[]' |
	while IFS=$"\n" read -r c; do
		sync_name=$(echo "$c" | jq -r '.sync_name')
		if [ "$2" = "$sync_name" ]; then
			description=$(echo "$c" | jq -r '.description')
			source=$(echo "$c" | jq -r '.source')
			destiny=$(echo "$c" | jq -r '.destiny')
			host=$(echo "$c" | jq -r '.host')
			port=$(echo "$c" | jq -r '.port')
			user=$(echo "$c" | jq -r '.user')
			read_logs=$(echo "$c" | jq -r '.read_logs')
			echo "---------------- $description"
			upload $1 $source $destiny $host $port $user $read_logs
		fi
	done
}

# **************** MAIN ****************
if [ "$#" = "0" ]; then
	usage
elif [ "$1" = "-l" ]; then
	usage
else
	packages=true
	while [ "$#" -gt "0" ]; do
		if [ "$1" = "-n" ]; then
			packages=false
		else
			searchProject $packages $1
		fi
		shift
	done
fi
