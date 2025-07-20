#!/bin/bash

# Must be run as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	command="$0 $@"
	su -c "$command"
	exit 1
fi

script_path=`realpath "$0"`
base_path=`dirname "$script_path"`

# Task map
declare -A scripts=(
	[js]="minify_js.sh"
	[sass]="sass.sh"
	[blackphp]="blackphp_sync.sh"
	[mysqldump]="mysqldump.sh"
	[language]="language.sh"
	[images]="images.sh"
)

# If no arguments, run all
if [ $# -eq 0 ]; then
	echo "No arguments provided. Running all tasks..."
	for key in "${!scripts[@]}"; do
		echo "Running: ${scripts[$key]}"
		"$base_path/${scripts[$key]}"
	done
else
	for task in "$@"; do
		if [[ ${scripts[$task]+_} ]]; then
			echo "Running: ${scripts[$task]}"
			"$base_path/${scripts[$task]}"
		else
			echo "Invalid task: $task"
			echo "Available tasks: ${!scripts[@]}"
		fi
	done
fi
