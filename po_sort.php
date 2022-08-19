<?php
	$headers = Array();
	$messages = Array("0" => Array());
	if(!isset($argv[1]) || !file_exists($argv[1]))
	{
		die("File not found!\n\n");
	}
	$content = file_get_contents($argv[1]);
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
	$txt = "";
	foreach($headers as $header)
	{
		$txt .= "$header\n";
	}
	foreach($messages as $context => $list)
	{
		foreach($list as $message)
		{
			$txt .= "\n";
			if($context != "0")
			{
				$txt .= "msgctxt \"" . $context . "\"\n";
			}
			$txt .= "msgid \"" . $message["id"] . "\"\n";
			$txt .= "msgstr \"" . $message["str"] . "\"\n";
		}
	}
	$fd = fopen($argv[2], "w+");
	fwrite($fd, $txt);
	fclose($fd);
?>
