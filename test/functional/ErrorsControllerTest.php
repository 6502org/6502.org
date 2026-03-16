<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('functional')]
class ErrorsControllerTest extends Mad_Test_Functional
{
    public function setUp(): void
    {
        parent::setUp();
    }

    public function test404Page(): void
    {
        $this->get('/404');
        $this->assertResponse('missing');
        $this->assertResponseContains('404');
        $this->assertResponseContains('could not be found');
    }
}

