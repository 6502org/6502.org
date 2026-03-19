<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(dirname(__FILE__))).'/config/environment.php';
}

#[\PHPUnit\Framework\Attributes\Group('unit')]
class DocumentFolderTest extends Mad_Test_Unit
{
    public function setUp(): void
    {
        $this->fixtures('document_folders', 'document_files');
    }

    // Validations

    public function testRequiresTitle(): void
    {
        $folder = new DocumentFolder(['slug' => 'test', 'parent_folder_id' => 1]);
        $this->assertFalse($folder->isValid());
        $this->assertTrue($folder->errors->isInvalid('title'));
    }

    public function testRequiresSlug(): void
    {
        $folder = new DocumentFolder(['title' => 'Test', 'parent_folder_id' => 1]);
        $this->assertFalse($folder->isValid());
        $this->assertTrue($folder->errors->isInvalid('slug'));
    }

    public function testSlugUniqueWithinParent(): void
    {
        $folder = new DocumentFolder([
            'title' => 'Duplicate',
            'slug' => 'mos',
            'path' => 'datasheets/mos2/',
            'parent_folder_id' => 2
        ]);
        $this->assertFalse($folder->isValid());
        $this->assertTrue($folder->errors->isInvalid('slug'));
    }

    public function testSlugAllowedInDifferentParent(): void
    {
        $folder = new DocumentFolder([
            'title' => 'MOS in another parent',
            'slug' => 'mos',
            'path' => 'somewhere/mos/',
            'parent_folder_id' => 1
        ]);
        $this->assertTrue($folder->isValid());
    }

    // Associations

    public function testSubfolders(): void
    {
        $root = DocumentFolder::find($this->document_folders('root')->id);
        $subfolders = $root->subfolders;
        $this->assertEquals(1, count($subfolders));
        $this->assertEquals('Datasheets', $subfolders[0]->title);
    }

    public function testDocumentFiles(): void
    {
        $mos = DocumentFolder::find($this->document_folders('mos')->id);
        $files = $mos->documentFiles;
        $this->assertEquals(3, count($files));
    }

    public function testParentFolder(): void
    {
        $mos = DocumentFolder::find($this->document_folders('mos')->id);
        $this->assertEquals('Datasheets', $mos->parentFolder->title);
    }

    // Finders

    public function testResolvePath(): void
    {
        $folders = DocumentFolder::resolvePath('datasheets/mos');
        $this->assertEquals(3, count($folders));
        $this->assertEquals('documents', $folders[0]->slug);
        $this->assertEquals('datasheets', $folders[1]->slug);
        $this->assertEquals('mos', $folders[2]->slug);
    }

    public function testResolvePathStopsAtInvalidSlug(): void
    {
        $folders = DocumentFolder::resolvePath('datasheets/nonexistent');
        $this->assertEquals(2, count($folders));
        $this->assertEquals('datasheets', $folders[1]->slug);
    }

    public function testResolvePathCaseInsensitive(): void
    {
        $folders = DocumentFolder::resolvePath('Datasheets/MOS');
        $this->assertEquals(3, count($folders));
    }

    public function testFindBySlugAndParent(): void
    {
        $folder = DocumentFolder::findBySlugAndParent('mos', 2);
        $this->assertNotNull($folder);
        $this->assertEquals('mos', $folder->slug);
    }

    public function testFindBySlugAndParentReturnsNullWhenNotFound(): void
    {
        $folder = DocumentFolder::findBySlugAndParent('nonexistent', 2);
        $this->assertNull($folder);
    }

    public function testFindFile(): void
    {
        $mos = DocumentFolder::find($this->document_folders('mos')->id);
        $file = $mos->findFile('mos_6500_mpu_nov_1985.pdf');
        $this->assertNotNull($file);
        $this->assertEquals('mos_6500_mpu_nov_1985.pdf', $file->filename);
    }

    public function testFindFileCaseInsensitive(): void
    {
        $mos = DocumentFolder::find($this->document_folders('mos')->id);
        $file = $mos->findFile('MOS_6500_MPU_NOV_1985.PDF');
        $this->assertNotNull($file);
    }

    public function testFindFileReturnsNullWhenNotFound(): void
    {
        $mos = DocumentFolder::find($this->document_folders('mos')->id);
        $file = $mos->findFile('nonexistent.pdf');
        $this->assertNull($file);
    }

    // Path

    public function testPathForRoot(): void
    {
        $root = DocumentFolder::find($this->document_folders('root')->id);
        $this->assertEquals('/documents/', $root->path());
    }

    public function testPathForSubfolder(): void
    {
        $mos = DocumentFolder::find($this->document_folders('mos')->id);
        $this->assertEquals('/documents/datasheets/mos/', $mos->path());
    }
}
