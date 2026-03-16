<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('functional')]
class ContentsControllerTest extends Mad_Test_Functional
{
    public function setUp(): void
    {
        parent::setUp();
    }

    public function testHomePage(): void
    {
        $this->get('/');
        $this->assertResponse('success');
        $this->assertResponseContains('6502.org');
        $this->assertResponseContains('Welcome');
    }

    public function testNewsPage(): void
    {
        $this->get('/news');
        $this->assertResponse('success');
        $this->assertResponseContains('News and Site Updates');
    }

    public function testHomebuiltPage(): void
    {
        $this->get('/homebuilt');
        $this->assertResponse('success');
        $this->assertResponseContains('Homebuilt Projects');
    }

    public function testRepositoryPage(): void
    {
        $this->get('/source');
        $this->assertResponse('success');
        $this->assertResponseContains('Source Code Library');
    }

    public function testMiniProjectsPage(): void
    {
        $this->get('/mini-projects');
        $this->assertResponse('success');
        $this->assertResponseContains('Mini-Projects');
    }

    public function testTutorialsPage(): void
    {
        $this->get('/tutorials');
        $this->assertResponse('success');
        $this->assertResponseContains('Tutorials and Primers');
    }

    public function testBooksPage(): void
    {
        $this->get('/books');
        $this->assertResponse('success');
        $this->assertResponseContains('Books');
    }

    public function testCommercialPage(): void
    {
        $this->get('/commercial');
        $this->assertResponse('success');
        $this->assertResponseContains('Commercial Support');
    }

    public function testGroupsPage(): void
    {
        $this->get('/groups');
        $this->assertResponse('success');
        $this->assertResponseContains('Discussion Groups');
    }
}

