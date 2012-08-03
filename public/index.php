<?php
require_once dirname(dirname(__FILE__)).'/config/environment.php';

$request = new Mad_Controller_Request_Http();
$dispatcher = Mad_Controller_Dispatcher::getInstance();

try {
    $dispatcher->dispatch($request);
} catch (Exception $e) {
    header('Location: /404');
}
