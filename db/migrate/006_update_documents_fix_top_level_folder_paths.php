<?php

class UpdateDocumentsFixTopLevelFolderPaths extends Mad_Model_Migration_Base
{
    public function up()
    {
        // Top-level folders under the "documents" root had empty paths.
        // Set them to match their slugs for consistency.
        $rows = $this->selectAll(
            "SELECT id, slug FROM document_folders
             WHERE parent_folder_id = 1 AND path = ''"
        );
        foreach ($rows as $row) {
            $this->update(
                "UPDATE document_folders SET path = ? WHERE id = ?",
                [$row['slug'] . '/', $row['id']]
            );
        }
    }

    public function down()
    {
        $this->update(
            "UPDATE document_folders SET path = ''
             WHERE parent_folder_id = 1"
        );
    }
}
