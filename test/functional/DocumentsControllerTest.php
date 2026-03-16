<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('functional')]
class DocumentsControllerTest extends Mad_Test_Functional
{
    public function setUp(): void
    {
        parent::setUp();
    }

    public function testIndexPage(): void
    {
        $this->get('/documents');
        $this->assertResponse('success');
        $this->assertResponseContains('Documents Archive');
    }
}

