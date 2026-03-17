<?php

class UpdateDocumentsRemoveEmptyFolder extends Mad_Model_Migration_Base
{
    public function up()
    {
        // Remove junk row with no slug, title, or parent.
        $this->execute("DELETE FROM document_folders WHERE id = 56");
    }

    public function down()
    {
        $this->execute(
            "INSERT INTO document_folders (id, title, sort_title, description, path, parent_folder_id, slug)
             VALUES (56, NULL, NULL, NULL, NULL, 0, NULL)"
        );
    }
}
