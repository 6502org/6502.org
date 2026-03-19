<?php

class CreateDocumentFiles extends Mad_Model_Migration_Base
{
    public function up()
    {
        $this->createTable('document_files', function($t) {
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
        });

        $this->addIndex('document_files', 'filename', ['name' => 'idx_document_files_filename']);
    }

    public function down()
    {
        $this->dropTable('document_files');
    }
}
