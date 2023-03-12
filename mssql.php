<?php
	if(empty($argv[1]))
	{
		echo("Database name is not defined\n");
		exit(0);
	}
	$database = $argv[1];
	$data_types = Array(
		"int" => "int",
		"tinyint" => "smallint",
		"char" => "nchar",
		"varchar" => "nvarchar",
		"datetime" => "datetime2"
	);
	$connection = mysqli_connect("localhost", "root", "ldi14517", "information_schema");
	$tables_query = mysqli_query($connection, "SELECT * FROM TABLES WHERE TABLE_SCHEMA = '$database'");
	while($table = mysqli_fetch_assoc($tables_query))
	{
		if($table['TABLE_TYPE'] != 'BASE TABLE')
		{
			continue;
		}
		echo("\nCREATE TABLE " . $table['TABLE_NAME'] . " (\n");
		$columns_query = mysqli_query($connection, "SELECT * FROM COLUMNS WHERE TABLE_SCHEMA = '$database' AND TABLE_NAME = '" . $table['TABLE_NAME'] . "'");
		while($column = mysqli_fetch_assoc($columns_query))
		{
			# Nombre de la columna
			echo("  " . $column['COLUMN_NAME']);

			# Tipo de la columna
			if(isset($data_types[$column['DATA_TYPE']]))
			{
				echo(" " . $data_types[$column['DATA_TYPE']]);
			}
			else
			{
				echo(" (" . $column['DATA_TYPE'] . ")");
			}

			# Longitud
			if(in_array($column['DATA_TYPE'], Array("char", "varchar")))
			{
				echo("(" . $column['CHARACTER_MAXIMUM_LENGTH'] . ")");
			}
			if($column['DATA_TYPE'] == 'datetime')
			{
				echo("(0)");
			}

			# Null
			if($column['IS_NULLABLE'] == 'NO')
			{
				echo(" NOT");
			}
			echo(" NULL");
			echo ",\n";
		}
		echo(")\n");
	}
?>
