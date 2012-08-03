<?php

class ErrorsController extends ApplicationController
{
    public function error404() {
       $this->render(array('status' => 404));
    }
}
