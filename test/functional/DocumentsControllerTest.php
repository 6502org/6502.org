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
        $this->fixtures('document_folders', 'document_files');
        parent::setUp();
    }

    public function testIndexPage(): void
    {
        $this->get('/documents');
        $this->assertResponse('success');
        $this->assertResponseContains('Documents Archive');
    }

    public function testSubfolderPage(): void
    {
        $this->get('/documents/datasheets');
        $this->assertResponse('success');
    }

    public function testDeepFolderPage(): void
    {
        $this->get('/documents/datasheets/mos');
        $this->assertResponse('success');
        $this->assertResponseContains('6500 Microprocessors');
    }

    // The webserver should serve files directly. If a readable file
    // reaches the controller, the server is misconfigured.
    public function testReadableFileReturns500(): void
    {
        $path = DOCUMENTS_ROOT . 'datasheets/mos/mos_6500_mpu_nov_1985.pdf';
        if (!is_dir(dirname($path))) {
            mkdir(dirname($path), 0755, true);
        }
        file_put_contents($path, 'fake pdf');

        try {
            $this->get('/documents/datasheets/mos/mos_6500_mpu_nov_1985.pdf');
            $this->assertResponse(500);
            $this->assertSelect('p.message', '/mod_rewrite/');
        } finally {
            unlink($path);
        }
    }

    public function testUnavailableFileRedirectsWithFlash(): void
    {
        $this->get('/documents/datasheets/wdc/does_not_exist.pdf');
        $this->assertResponse('redirect');
        $this->assertRedirectedTo('/documents/datasheets/wdc/');
        $this->assertAssignsFlash('alert', '"Unavailable Document" is not currently available.');
    }

    public function testAvailableFileRedirectsToMirror(): void
    {
        $this->get('/documents/datasheets/mos/mos_6500_mpu_nov_1985.pdf');
        $this->assertResponse('redirect');
        $this->assertRedirectedTo('https://example.com/mos_6500_mpu_nov_1985.pdf');
    }

    public function testBadSlugRedirectsToLastGoodFolder(): void
    {
        $this->get('/documents/datasheets/nonexistent');
        $this->assertResponse('redirect');
        $this->assertRedirectedTo('/documents/datasheets/');
    }

    public function testCaseInsensitiveSlugs(): void
    {
        $this->get('/documents/Datasheets/MOS');
        $this->assertResponse('success');
    }
}
