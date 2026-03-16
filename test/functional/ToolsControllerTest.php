<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('functional')]
class ToolsControllerTest extends Mad_Test_Functional
{
    public function setUp(): void
    {
        parent::setUp();
    }

    public function testIndexPage(): void
    {
        $this->get('/tools');
        $this->assertResponse('success');
        $this->assertResponseContains('Development Tools');
    }

    public function testAsmPage(): void
    {
        $this->get('/tools/asm');
        $this->assertResponse('success');
        $this->assertResponseContains('Assemblers');
    }

    public function testEmuPage(): void
    {
        $this->get('/tools/emu');
        $this->assertResponse('success');
        $this->assertResponseContains('Emulat');
    }

    public function testLangPage(): void
    {
        $this->get('/tools/lang');
        $this->assertResponse('success');
        $this->assertResponseContains('Compilers');
    }
}

