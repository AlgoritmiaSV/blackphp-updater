<?php
$file = "/store/Clouds/Mega/development/mvc/blackphp/public/styles/main.css";
$content = file_get_contents($file);
$data = array();
$content = explode("\n", $content);
$is_property = false;
$is_media = false;
$rule = array("name" => "", "properties" => array());
foreach ($content as $line) {
    $line = trim($line);
    if ($line == "") {
        continue;
    }
    if ($line == "{") {
        $is_property = true;
    } elseif ($line == "}") {
        $is_property = false;
        $data[] = $rule;
        $rule = array("name" => "", "properties" => array());
    } else {
        if ($is_property) {
            $line = trim($line, ";");
            $parts = explode(":", $line);
            $rule["properties"][] = array(
                "name" => $parts[0],
                "value" => $parts[1]
            );
        } else {
            $rule["name"] = $line;
        }
    }
}
print_r($data);
