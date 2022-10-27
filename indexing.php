<?php
	if(empty($argv[1]))
	{
		die("No files found!\n");
	}
	if(!file_exists($argv[1]))
	{
		die($argv[1] . " not exists!\n");
	}
	$content = file_get_contents($argv[1]);
	$lines = explode("\n", $content);
	$commented = false;
	$i = 0;
	$index = Array();
	$methods = 0;
	$documented = 0;
	foreach($lines as $line)
	{
		$i++;
		$line = trim($line);
		if($line == "/**")
		{
			$commented = true;
		}
		if(strpos($line, "class") === 0)
		{
			$commented = false;
		}
		if(strpos($line, "################################") === 0)
		{
			$commented = false;
			$line = str_replace("################################", "", $line);
			$index[] = Array(0, $line);
		}
		if(strpos($line, "public function") === 0)
		{
			$line = str_replace("public function ", "", $line);
			$index[] = Array($i, $line, $commented);
			$commented = false;
		}
	}
	foreach($index as $item)
	{
		if($item[0] == 0)
		{
			echo "$item[1]\n";
		}
		else
		{
			$num = str_pad($item[0], 4, " ", STR_PAD_LEFT);
			$status = $item[2] ? " " : "*";
			echo "\t$num {$status}$item[1]\n";
			if($item[2])
			{
				$documented++;
			}
			$methods++;
		}
	}
	echo "-------------------------------------\n";
	echo "Methods:    $methods\n";
	echo "Documented: $documented\n";
?>
