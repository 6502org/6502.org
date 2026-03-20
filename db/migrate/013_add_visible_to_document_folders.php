<?php

class AddVisibleToDocumentFolders extends Mad_Model_Migration_Base
{
    public function up()
    {
        $this->addColumn('document_folders', 'visible', 'integer', [
            'null' => false, 'default' => 1
        ]);
    }

    public function down()
    {
        $this->removeColumn('document_folders', 'visible');
    }
}
