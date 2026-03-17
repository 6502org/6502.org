<?php

class CreateDocumentFiles extends Mad_Model_Migration_Base
{
    public function up()
    {
        $t = $this->createTable('document_files');
            $t->column('title',      'string',  array('limit' => 100, 'null' => false));
            $t->column('filename',   'string',  array('limit' => 100, 'null' => false));
            $t->column('pages',      'integer', array('null' => false, 'default' => 0));
            $t->column('sort_title', 'string',  array('limit' => 100));
            $t->column('filesize',   'integer', array('null' => false, 'default' => 0));
            $t->column('folder_id',  'integer', array('null' => false, 'default' => 0));
            $t->column('created_at', 'datetime', array('null' => false));
            $t->column('visible',    'integer', array('default' => 1));
            $t->column('sha1',       'string',  array('limit' => 40, 'null' => false));
            $t->column('mirror_url', 'text');
        $t->end();

        $this->execute("CREATE UNIQUE INDEX idx_document_files_filename
                        ON document_files (filename COLLATE NOCASE)");
    }

    public function down()
    {
        $this->dropTable('document_files');
    }
}
