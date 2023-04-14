<?php
	date_default_timezone_set('America/El_Salvador');
	$headers = Array();
	$messages = Array("0" => Array());
	$project_config = $argv[1] == null ? "projects/blackphp.json" : $argv[1];
	$locale = $argv[2] == null ? "en_US" : $argv[2];
	$blackphp = json_decode(file_get_contents(dirname(__FILE__) . "/config.json"), true);
	$project = json_decode(file_get_contents($project_config), true);
	$project_folder = basename($project["project_path"]);

	$temp_po = $blackphp["temp_path"] . "/locale/$project_folder/$locale/messages.po";
	$source_po = $project["project_path"] . "/locale/$locale/LC_MESSAGES/messages.po";
	$required = $blackphp["temp_path"] . "/locale/$project_folder/required.txt";

	if(!file_exists($source_po))
	{
		die("File $source_po not found!\n\n");
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
		echo "$locale: $not_required translations not required\n";
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
		echo "$locale: $not_translated untranslated messages\n";
	}
	$lang_name = Array(
		"en_US" => "ENGLISH",
		"es_ES" => "SPANISH",
		"it_IT" => "ITALIAN"
	);
	$file_content = '';
	if($not_required > 0 || $not_translated > 0)
	{
		$headers = Array(
			'# PACK OF ' . $lang_name[$locale] . ' LANGUAGE FOR ' . strtoupper($project["project_name"]),
			'# Copyright (C)2022-' . Date("Y") . ' Red Teleinformática',
			'# This file is distributed under the same license as the PACKAGE ' . $project["project_name"] . '.',
			'# Edwin Fajardo <contacto@edwinfajardo.com>, 2022.',
			'#',
			'#, fuzzy',
			'msgid ""',
			'msgstr ""',
			'"Project-Id-Version: ' . $project["project_name"] . ' 1.0\n"',
			'"Report-Msgid-Bugs-To: \n"',
			$headers[10],
			'"PO-Revision-Date: ' . Date("Y-m-d H:i") .  '+UTC-6\n"',
			'"Last-Translator: ' . $project["lang_translator"] . '\n"',
			'"Language-Team: ' . $project["lang_team"] . '\n"',
			'"Language: ' . $locale . '\n"',
			'"MIME-Version: 1.0\n"',
			'"Content-Type: text/plain; charset=UTF-8\n"',
			'"Content-Transfer-Encoding: 8bit\n"'
		);
	}
	foreach($headers as $line)
	{
		$file_content .= ($line . "\n");
	}
	$file_content .= $txt;
	$fd = fopen($temp_po, "w+");
	fwrite($fd, $file_content);
	fclose($fd);
?>
