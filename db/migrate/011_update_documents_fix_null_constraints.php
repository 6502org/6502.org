<?php

class UpdateDocumentsFixNullConstraints extends Mad_Model_Migration_Base
{
    public function up()
    {
        // SQLite can't ALTER COLUMN, so we recreate the tables.

        // DocumentFolder: title, slug, path should be NOT NULL
        $this->createTable('document_folders_new', function($t) {
            $t->column('title',            'string',  ['limit' => 100, 'null' => false]);
            $t->column('sort_title',       'string',  ['limit' => 255]);
            $t->column('description',      'text');
            $t->column('path',             'string',  ['limit' => 200, 'null' => false, 'default' => '']);
            $t->column('parent_folder_id', 'integer', ['null' => false, 'default' => 0]);
            $t->column('slug',             'string',  ['limit' => 100, 'null' => false]);
        });
        $this->execute("INSERT INTO document_folders_new SELECT * FROM document_folders");
        $this->dropTable('document_folders');
        $this->renameTable('document_folders_new', 'document_folders');
        $this->addIndex('document_folders', 'title');
        $this->addIndex('document_folders', 'parent_folder_id');
        $this->addIndex('document_folders', 'slug');
        $this->addIndex('document_folders', 'sort_title');

        // DocumentFile: visible should be NOT NULL, folder_id should have no default
        $this->createTable('document_files_new', function($t) {
            $t->column('title',      'string',  ['limit' => 100, 'null' => false]);
            $t->column('filename',   'string',  ['limit' => 100, 'null' => false]);
            $t->column('pages',      'integer', ['null' => false, 'default' => 0]);
            $t->column('sort_title', 'string',  ['limit' => 100]);
            $t->column('filesize',   'integer', ['null' => false, 'default' => 0]);
            $t->column('folder_id',  'integer', ['null' => false]);
            $t->column('created_at', 'datetime', ['null' => false]);
            $t->column('visible',    'integer', ['null' => false, 'default' => 1]);
            $t->column('sha1',       'string',  ['limit' => 40, 'null' => false]);
            $t->column('mirror_url', 'text');
            $t->column('obsolete',   'boolean', ['null' => false, 'default' => false]);
        });
        $this->execute("INSERT INTO document_files_new SELECT * FROM document_files");
        $this->dropTable('document_files');
        $this->renameTable('document_files_new', 'document_files');
        $this->addIndex('document_files', 'filename', ['name' => 'idx_document_files_filename']);
    }

    public function down()
    {
        // DocumentFolder: revert to nullable title, slug, path
        $this->createTable('document_folders_new', function($t) {
            $t->column('title',            'string',  ['limit' => 100]);
            $t->column('sort_title',       'string',  ['limit' => 255]);
            $t->column('description',      'text');
            $t->column('path',             'string',  ['limit' => 200]);
            $t->column('parent_folder_id', 'integer', ['null' => false, 'default' => 0]);
            $t->column('slug',             'string',  ['limit' => 100]);
        });
        $this->execute("INSERT INTO document_folders_new SELECT * FROM document_folders");
        $this->dropTable('document_folders');
        $this->renameTable('document_folders_new', 'document_folders');
        $this->addIndex('document_folders', 'title');
        $this->addIndex('document_folders', 'parent_folder_id');
        $this->addIndex('document_folders', 'slug');
        $this->addIndex('document_folders', 'sort_title');

        // DocumentFile: revert visible to nullable, folder_id default to 0
        $this->createTable('document_files_new', function($t) {
            $t->column('title',      'string',  ['limit' => 100, 'null' => false]);
            $t->column('filename',   'string',  ['limit' => 100, 'null' => false]);
            $t->column('pages',      'integer', ['null' => false, 'default' => 0]);
            $t->column('sort_title', 'string',  ['limit' => 100]);
            $t->column('filesize',   'integer', ['null' => false, 'default' => 0]);
            $t->column('folder_id',  'integer', ['null' => false, 'default' => 0]);
            $t->column('created_at', 'datetime', ['null' => false]);
            $t->column('visible',    'integer', ['default' => 1]);
            $t->column('sha1',       'string',  ['limit' => 40, 'null' => false]);
            $t->column('mirror_url', 'text');
            $t->column('obsolete',   'boolean', ['null' => false, 'default' => false]);
        });
        $this->execute("INSERT INTO document_files_new SELECT * FROM document_files");
        $this->dropTable('document_files');
        $this->renameTable('document_files_new', 'document_files');
        $this->addIndex('document_files', 'filename', ['name' => 'idx_document_files_filename']);
    }
}
