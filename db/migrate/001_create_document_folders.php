<?php

class CreateDocumentFolders extends Mad_Model_Migration_Base
{
    public function up()
    {
        $this->createTable('document_folders', function($t) {
            $t->column('title',            'string',  ['limit' => 100]);
            $t->column('sort_title',       'string',  ['limit' => 255]);
            $t->column('description',      'text');
            $t->column('path',             'string',  ['limit' => 200]);
            $t->column('parent_folder_id', 'integer', ['null' => false, 'default' => 0]);
            $t->column('slug',             'string',  ['limit' => 100]);
        });

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
