#!/bin/bash

TARGET_DIR="/store/bphp/releases"
cd "$TARGET_DIR" || exit 1

files_to_delete=$(find . -type f -name 'release_*.zip' | while read -r filepath; do
	subdir=$(echo "$filepath" | cut -d/ -f2)
	timestamp=$(echo "$filepath" | grep -oE '[0-9]{14}')
	datepart=${timestamp:0:8}
	echo "$subdir $datepart $timestamp $filepath"
done | sort | awk '
{
	key = $1 " " $2
	if (key in max_time) {
		if ($3 > max_time[key]) {
			max_time[key] = $3
			file[key] = $4
		}
	} else {
		max_time[key] = $3
		file[key] = $4
	}
	all_files[key, $4] = 1
}
END {
	for (idx in all_files) {
		split(idx, parts, SUBSEP)
		k = parts[1]
		f = parts[2]
		if (f != file[k]) {
			print f
		}
	}
}
' | sort)

if [ -n "$files_to_delete" ]; then
	echo "$files_to_delete" | xargs rm -v
else
	echo "No old files to delete."
fi
