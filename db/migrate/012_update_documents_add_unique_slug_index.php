<?php

class UpdateDocumentsAddUniqueSlugIndex extends Mad_Model_Migration_Base
{
    public function up()
    {
        $this->removeIndex('document_folders', ['column' => 'slug']);
        $this->addIndex('document_folders', ['slug', 'parent_folder_id'],
                        ['unique' => true, 'name' => 'index_document_folders_on_slug_and_parent']);
    }

    public function down()
    {
        $this->removeIndex('document_folders', ['name' => 'index_document_folders_on_slug_and_parent']);
        $this->addIndex('document_folders', 'slug');
    }
}
