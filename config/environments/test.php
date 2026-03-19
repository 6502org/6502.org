<?php

$config->model->cacheTables     = false;  // don't cache tables
$config->mailer->deliveryMethod = 'test'; // don't actually send mail

define('DOCUMENTS_ROOT', MAD_ROOT . '/tmp/documents/');
