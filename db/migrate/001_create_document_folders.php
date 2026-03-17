<?php

class CreateDocumentFolders extends Mad_Model_Migration_Base
{
    public function up()
    {
        $t = $this->createTable('document_folders');
            $t->column('title',            'string',  array('limit' => 100));
            $t->column('sort_title',       'string',  array('limit' => 255));
            $t->column('description',      'text');
            $t->column('path',             'string',  array('limit' => 200));
            $t->column('parent_folder_id', 'integer', array('null' => false, 'default' => 0));
            $t->column('slug',             'string',  array('limit' => 100));
        $t->end();

        $this->addIndex('document_folders', 'title');
        $this->addIndex('document_folders', 'parent_folder_id');
        $this->addIndex('document_folders', 'slug');
        $this->addIndex('document_folders', 'sort_title');
    }

    public function down()
    {
        $this->dropTable('document_folders');
    }
}
