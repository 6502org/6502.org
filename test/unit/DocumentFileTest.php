<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('unit')]
class DocumentFileTest extends Mad_Test_Unit
{
    public function setUp(): void
    {
        $this->fixtures('document_folders', 'document_files');
    }

    // Validations

    public function testRequiresTitle(): void
    {
        $file = $this->_validFile();
        $file->title = null;
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('title'));
    }

    public function testRequiresFilename(): void
    {
        $file = $this->_validFile();
        $file->filename = null;
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('filename'));
    }

    public function testRequiresUniqueFilename(): void
    {
        $file = $this->_validFile();
        $file->filename = 'mos_6500_mpu_nov_1985.pdf';
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('filename'));
    }

    public function testRequiresFolderId(): void
    {
        $file = $this->_validFile();
        $file->folder_id = null;
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('folder_id'));
    }

    public function testRequiresValidSha1(): void
    {
        $file = $this->_validFile();
        $file->sha1 = 'not-a-hash';
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('sha1'));
    }

    public function testRequiresSha1ToBeHex(): void
    {
        $file = $this->_validFile();
        $file->sha1 = 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz';
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('sha1'));
    }

    public function testAcceptsValidSha1(): void
    {
        $file = $this->_validFile();
        $this->assertTrue($file->isValid());
    }

    public function testPagesIsNumeric(): void
    {
        $file = $this->_validFile();
        $file->pages = 'abc';
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('pages'));
    }

    public function testFilesizeIsNumeric(): void
    {
        $file = $this->_validFile();
        $file->filesize = 'abc';
        $this->assertFalse($file->isValid());
        $this->assertTrue($file->errors->isInvalid('filesize'));
    }

    // Associations

    public function testBelongsToDocumentFolder(): void
    {
        $file = DocumentFile::find($this->document_files('mos_6502_current')->id);
        $this->assertEquals('mos', $file->documentFolder->slug);
    }

    // Integrity

    public function testIsIntactWhenReadableAndSha1Matches(): void
    {
        $file = DocumentFile::find($this->document_files('mos_6502_current')->id);
        $path = $file->localPath();
        @mkdir(dirname($path), 0755, true);
        file_put_contents($path, 'test content');
        try {
            $file->sha1 = sha1_file($path);
            $this->assertTrue($file->isIntact());
        } finally {
            unlink($path);
        }
    }

    public function testIsNotIntactWhenSha1Mismatches(): void
    {
        $file = DocumentFile::find($this->document_files('mos_6502_current')->id);
        $path = $file->localPath();
        @mkdir(dirname($path), 0755, true);
        file_put_contents($path, 'test content');
        try {
            $this->assertFalse($file->isIntact());
        } finally {
            unlink($path);
        }
    }

    public function testIsNotIntactWhenNotReadable(): void
    {
        $file = DocumentFile::find($this->document_files('mos_6502_current')->id);
        $this->assertFalse($file->isIntact());
    }

    public function testIsNotReadableWhenFileDoesNotExist(): void
    {
        $file = DocumentFile::find($this->document_files('mos_6502_current')->id);
        $this->assertFalse($file->isReadable());
    }

    // findByPath

    public function testFindByPath(): void
    {
        $file = DocumentFile::findByPath('datasheets/mos/mos_6500_mpu_nov_1985.pdf');
        $this->assertNotNull($file);
        $this->assertEquals('mos_6500_mpu_nov_1985.pdf', $file->filename);
    }

    public function testFindByPathIsCaseInsensitive(): void
    {
        $file = DocumentFile::findByPath('datasheets/mos/MOS_6500_MPU_NOV_1985.PDF');
        $this->assertNotNull($file);
        $this->assertEquals('mos_6500_mpu_nov_1985.pdf', $file->filename);
    }

    public function testFindByPathReturnsNullForBadFilename(): void
    {
        $this->assertNull(DocumentFile::findByPath('datasheets/mos/nonexistent.pdf'));
    }

    public function testFindByPathReturnsNullForBadFolder(): void
    {
        $this->assertNull(DocumentFile::findByPath('datasheets/nonexistent/mos_6500_mpu_nov_1985.pdf'));
    }

    // Helper

    private function _validFile()
    {
        return new DocumentFile([
            'title'     => 'Test Document',
            'filename'  => 'unique_test_file.pdf',
            'folder_id' => 3,
            'sha1'      => 'dddddddddddddddddddddddddddddddddddddddd',
            'pages'     => 10,
            'filesize'  => 5000
        ]);
    }
}
