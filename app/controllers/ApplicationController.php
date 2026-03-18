<?php

class ApplicationController extends Mad_Controller_Base
{
    protected function _isProduction()
    {
        return MAD_ENV == 'production';
    }
}
