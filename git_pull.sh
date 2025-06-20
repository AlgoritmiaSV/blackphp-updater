#!/bin/bash
#Cargando configuración inicial
script_path=`realpath $0`
script_dir=`dirname $script_path`
blackphp_path=`jq -r ".blackphp_path" $script_dir/config.json`
config_files=$script_dir/projects
cd $config_files

# List of your projects
projects=(`ls -1 | grep -v '^_' | sed 's/\.json$//'`)

# Base directory where your projects are located
git_dir="/store/Gits/mvc"

for project in "${projects[@]}"; do
	echo "🔄 Updating $project..."
	cd "$git_dir/$project" || { echo "❌ Cannot enter $project"; continue; }

	# Get local branches (excluding symbolic refs like HEAD)
	branches=($(git for-each-ref --format='%(refname:short)' refs/heads/))

	for branch in "${branches[@]}"; do
		echo "  ➤ Checking out $branch"
		git checkout "$branch"
		echo "  ⬇ Pulling latest changes"
		git pull
	done

	# Return to main if it exists
	if git show-ref --verify --quiet refs/heads/main; then
		echo "  🔁 Switching back to main"
		git checkout main
	fi

	# Sync .git folder
	project_path=`jq -r ".project_path" $config_files/$project.json`
	rsync -rc --delete --info=NAME1 $git_dir/$project/.git/ $project_path/.git/

	echo "✅ Done with $project"
	echo
done

echo "🏁 All projects updated and set to 'main' if available."
