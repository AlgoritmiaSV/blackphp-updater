<?php
	$headers = Array();
	$messages = Array("0" => Array());
	$project = $argv[1] == null ? "blackphp" : $argv[1];
	$locale = $argv[2] == null ? "en_US" : $argv[2];
	$temp_po = "/store/bphp/locale/$project/$locale/messages.po";
	$source_po = "/store/Clouds/Mega/www/$project/locale/$locale/LC_MESSAGES/messages.po";
	$required = "/store/bphp/locale/$project/required.txt";

	if(!file_exists($source_po))
	{
		die("File not found!\n\n");
	}
	$content = file_get_contents($source_po);
	$content = explode("\n", $content);
	$context = "0";
	$id = "";
	$i = 0;
	foreach($content as $line)
	{
		$i++;
		if($i <= 18)
		{
			$headers[] = $line;
			continue;
		}
		if(strpos($line, "msgctxt") !== false && strpos($line, "msgctxt") == 0)
		{
			$context = preg_replace('/msgctxt\s+\"(.*)\"/i','$1', $line);
		}
		if(strpos($line, "msgid") !== false && strpos($line, "msgid") == 0)
		{
			$id = preg_replace('/msgid\s+\"(.*)\"/i','$1', $line);
		}
		if(strpos($line, "msgstr") !== false && strpos($line, "msgstr") == 0)
		{
			if(!array_key_exists($context, $messages))
			{
				$messages[$context] = Array();
			}
			$messages[$context][] = Array(
				"id" => $id,
				"str" => preg_replace('/msgstr\s+\"(.*)\"/i','$1', $line)
			);
			$id = "";
			$context = "0";
		}
	}
	foreach($messages as $key => $value)
	{
		usort($messages[$key], function ($a,$b) {
			return strtolower($a["id"]) > strtolower($b["id"]);
		});
	}
	ksort($messages);

	$lines = Array();
	if(file_exists($required))
	{
		$lines = file_get_contents($required);
		$lines = explode("\n", $lines);
	}

	$txt = "";
	foreach($headers as $header)
	{
		$txt .= "$header\n";
	}
	$total = 0;
	$not_required = 0;
	foreach($messages as $context => $list)
	{
		$total += count($list);
		foreach($list as $message)
		{
			$txt .= "\n";
			if($context == "0")
			{
				$index = array_search($message["id"], $lines);
				if($index !== false)
				{
					unset($lines[$index]);
				}
				else
				{
					$txt .= "# Not required\n";
					$not_required++;
				}
			}
			else
			{
				$index = array_search($context . "\04" . $message["id"], $lines);
				if($index !== false)
				{
					unset($lines[$index]);
				}
				else
				{
					$txt .= "# Not required\n";
					$not_required++;
				}
				$txt .= "msgctxt \"" . $context . "\"\n";
			}
			$txt .= "msgid \"" . $message["id"] . "\"\n";
			$txt .= "msgstr \"" . $message["str"] . "\"\n";
		}
	}
	if($not_required > 0)
	{
		echo "$not_required translations not required\n";
	}
	$txt .= "\n# " . $total . " messages translated.\n";
	$not_translated = 0;
	foreach($lines as $line)
	{
		if(strpos($line, "\04") !== false)
		{
			$parts = explode("\04", $line);
			$txt .= "\n#msgctxt \"$parts[0]\"\n#msgid \"$parts[1]\"\n#msgstr \"\"\n";
			$not_translated++;
		}
		elseif(!empty($line) && $locale != "en_US")
		{
			$txt .= "\n#msgid \"$line\"\n#msgstr \"\"\n";
			$not_translated++;
		}
	}
	if($not_translated > 0)
	{
		echo "$not_translated not translated expressions\n";
	}
	$fd = fopen($temp_po, "w+");
	fwrite($fd, $txt);
	fclose($fd);
?>
