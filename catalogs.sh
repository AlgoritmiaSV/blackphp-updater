#/bin/bash
#Cargando configuración inicial
script_path=`realpath $0`
script_dir=`dirname $script_path`
temp_path=`jq -r ".temp_path" $script_dir/config.json`
config_files=$script_dir/projects
cd $config_files

if [ "$#" = "0" ]; then
	for config_file in `ls -I "_*"`
	do
		$0 "$config_files/$config_file"
	done
	exit 1
fi

if [ ! -f "$1" ]; then
	echo "File $1 not exists!"
	exit 1
fi
project_name=`jq -r ".project_name" $1`
project_path=`jq -r ".project_path" $1`
db_host=`jq -r ".db_host" $1`
db_user=`jq -r ".db_user" $1`
db_password=`jq -r ".db_password" $1`
database=`jq -r ".database" $1`
db_prefix=`jq -r ".db_prefix" $1`
project_folder=`basename $project_path`
temp_dir=$temp_path/locale/$project_folder

echo "------------ Checking the existence of tables and columns in $project_folder"
mysql --skip-column-names \
	-h "$db_host" \
	-u "$db_user" \
	-p"$db_password" \
	"$database" \
	-e "
		SELECT DISTINCT
			c.table_name,
			c.column_name,
			CASE 
				WHEN t.table_name IS NULL THEN 'Missing table'
				WHEN col.column_name IS NULL THEN 'Missing column'
				ELSE 'OK'
			END AS consistency_status
		FROM $database.app_catalogs c
		LEFT JOIN information_schema.tables t 
			ON t.table_schema = '$database' 
			AND t.table_name = c.table_name
		LEFT JOIN information_schema.columns col 
			ON col.table_schema = '$database' 
			AND col.table_name = c.table_name 
			AND col.column_name = c.column_name
		WHERE t.table_name IS NULL
			OR col.column_name IS NULL
		ORDER BY c.table_name, c.column_name;
	"

echo "------------ Checking descriptions in catalogs $project_folder"
mysql --skip-column-names \
	-h "$db_host" \
	-u "$db_user" \
	-p"$db_password" \
	"$database" \
	-e "
		SELECT 
			col.table_name,
			col.column_name,
			CASE 
				WHEN cat.table_name IS NULL THEN 'Missing definition in app_catalogs'
				ELSE 'OK'
			END AS consistency_status
		FROM information_schema.columns col
		JOIN information_schema.tables t
			ON t.table_schema = col.table_schema
			AND t.table_name = col.table_name
			AND t.table_type = 'BASE TABLE'
		LEFT JOIN (
			SELECT DISTINCT table_name, column_name
			FROM $database.app_catalogs
		) cat
			ON cat.table_name = col.table_name
			AND cat.column_name = col.column_name
		WHERE col.table_schema = '$database'
		AND col.column_comment LIKE '%app_catalogs%'
		AND cat.table_name IS NULL
		ORDER BY col.table_name, col.column_name;
	"
