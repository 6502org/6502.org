<?php

// check compatibility
if (version_compare(PHP_VERSION, "5.4.0", "<")) {
    die("PHP 5.4 or higher is required.  Your version: " . PHP_VERSION);
}
if (version_compare(PHP_VERSION, "8.0.0", ">")) {
    die("PHP 7.4 or lower is required.  Your version: " . PHP_VERSION);
}
if (! ini_get("short_open_tag")) {
    die("short_open_tag = on must be set in php.ini");
}
if (! extension_loaded("pdo_sqlite")) {
    die("pdo_sqlite must be installed");
}


// env
define('MAD_ROOT', dirname(dirname(__FILE__)));
if (! defined('MAD_ENV')) {
    define('MAD_ENV', isset($_SERVER['MAD_ENV']) ? $_SERVER['MAD_ENV'] : 'development');
}
ini_set('date.timezone', 'US/Pacific');

// include paths
set_include_path(implode(PATH_SEPARATOR, array(
    MAD_ROOT . '/app',
    MAD_ROOT . '/app/controllers',
    MAD_ROOT . '/app/helpers',
    MAD_ROOT . '/app/models',
    MAD_ROOT . '/config',
    MAD_ROOT . '/lib',
    MAD_ROOT . '/test',
    MAD_ROOT . '/vendor',
    get_include_path()
)));

// initialization required by framework
require_once 'Mad/Support/Base.php';
Mad_Support_Base::initialize();

// error reporting
if (MAD_ENV == 'production') {
    error_reporting(0);
} else {
    ini_set('display_errors', 1);
    error_reporting(E_ALL | E_STRICT);
}

// initialize the default loger. writers and filters are specified in the environment files.
$GLOBALS['MAD_DEFAULT_LOGGER'] = new Horde_Log_Logger();
$writer = new Horde_Log_Handler_Stream(MAD_ROOT.'/log/'.MAD_ENV.'.log', 'a+');
$GLOBALS['MAD_DEFAULT_LOGGER']->addHandler($writer);

// priority filters
if (MAD_ENV == 'development') {
    $filter = new Horde_Log_Filter_Level(Horde_Log::INFO);
    $GLOBALS['MAD_DEFAULT_LOGGER']->addFilter($filter);
} elseif (MAD_ENV == 'production') {
    $filter = new Horde_Log_Filter_Level(Horde_Log::NOTICE);
    $GLOBALS['MAD_DEFAULT_LOGGER']->addFilter($filter);
}

