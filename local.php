<?php

/* php -d short_open_tag=on -S localhost:8000 -t public local.php 
 *
 * https://www.php.net/manual/en/features.commandline.webserver.php
 *
 * this code is not suitable for production (directory traversal
 * possible).  the cli-server itself is described on that page 
 * as not suitable for production either.
 */

if (php_sapi_name() != 'cli-server') {
	die("This script runs under the built-in PHP webserver.\n");
}

$request_path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);

$here = dirname(realpath(__FILE__));
$filename = $here . "/public/" . $request_path;

if ((!file_exists($filename)) || (!is_file($filename))) {
    require_once $here . '/public/index.php';
} else {
    return false; // served by built-in webserver
}
