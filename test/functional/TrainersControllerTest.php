<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('functional')]
class TrainersControllerTest extends Mad_Test_Functional
{
    public function setUp(): void
    {
        $this->fixtures('document_folders', 'document_files');
        parent::setUp();
    }

    public function testIndexPage(): void
    {
        $this->get('/trainers');
        $this->assertResponse('success');
        $this->assertResponseContains('Microcomputers and Trainers');
    }

    public function testSynertekPage(): void
    {
        $this->get('/trainers/synertek');
        $this->assertResponse('success');
        $this->assertResponseContains('Synertek SYM-1');
    }
}

