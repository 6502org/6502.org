<?php
require_once dirname(dirname(__FILE__)).'/config/environment.php';

$request = new Mad_Controller_Request_Http();
$dispatcher = Mad_Controller_Dispatcher::getInstance();

try {
    $dispatcher->dispatch($request);
} catch (Mad_Controller_Exception $e) {
    if (!headers_sent()) {
        header('HTTP/1.0 404 Not Found');
        header('Content-Type: text/html');
    }
    readfile(__DIR__ . '/404.html');
} catch (Exception $e) {
    if (!headers_sent()) {
        header('HTTP/1.1 500 Internal Server Error');
        header('Content-Type: text/html');
    }
    if (MAD_ENV == 'production') {
        readfile(__DIR__ . '/500.html');
    } else {
        echo '<pre>' . htmlspecialchars($e->getMessage() . "\n\n" . $e->getTraceAsString()) . '</pre>';
    }
}
