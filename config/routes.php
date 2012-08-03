<?php

$map->connect('', array('controller' => 'contents', 'action' => 'home'));

$map->connect('news',          array('controller' => 'contents', 'action' => 'news'));
$map->connect('ads',           array('controller' => 'contents', 'action' => 'ads'));
$map->connect('books',         array('controller' => 'contents', 'action' => 'books'));
$map->connect('homebuilt',     array('controller' => 'contents', 'action' => 'homebuilt'));
$map->connect('commercial',    array('controller' => 'contents', 'action' => 'commercial'));
$map->connect('groups',        array('controller' => 'contents', 'action' => 'groups'));
$map->connect('mini-projects', array('controller' => 'contents', 'action' => 'mini_projects'));
$map->connect('tutorials',     array('controller' => 'contents', 'action' => 'tutorials'));
$map->connect('source',        array('controller' => 'contents', 'action' => 'repository'));

$map->connect('documents*path',        array('controller' => 'documents', 'action' => 'index'));

$map->connect('404',        array('controller' => 'errors', 'action' => 'error404'));

$map->connect(':controller/:action/:id', array('id' => null));
