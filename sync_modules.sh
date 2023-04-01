#!/bin/bash
#	Main
# Se requieren permisos de root (Sólo en Linux)
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	command="${0} ${@}"
	su -c "$command"
	exit 1
fi
script_path=`realpath $0`
script_dir=`dirname $script_path`
config_files=$script_dir/projects

index=0
item=`jq ".[0]" $script_dir/sync_modules.json`
while [ "$item" != "null" ]; do
	module=`echo "$item" | jq -r ".module"`
	from=`echo "$item" | jq -r ".from"`
	to=`echo "$item" | jq -r ".to"`
	elements=`echo "$item" | jq -r ".sync"`
	d_index=0
	d_item=`echo "$to" | jq -r ".[0]"`
	while [ "$d_item" != "null" ]; do
		echo "----Syncing $module from $from to $d_item"

		source_path=`jq -r ".project_path" $config_files/$from.json`
		destiny_path=`jq -r ".project_path" $config_files/$d_item.json`

		e_index=0
		element=`echo "$elements" | jq -r ".[0]"`
		while [ "$element" != "null" ]; do
			if [ -f "$source_path/$element" ]; then
				rsync -ac --info=NAME1 "$source_path/$element" "$destiny_path/$element"
			fi
			if [ -d "$source_path/$element" ]; then
				rsync -acr --delete --info=NAME1 --exclude "info_details.html" "$source_path/$element/" "$destiny_path/$element/"
			fi
			((e_index=e_index+1))
			element=`echo "$elements" | jq -r ".[$e_index]"`
		done

		((d_index=d_index+1))
		d_item=`echo "$to" | jq -r ".[$d_index]"`
	done
	((index=index+1))
	item=`jq ".[$index]" $script_dir/sync_modules.json`
done
