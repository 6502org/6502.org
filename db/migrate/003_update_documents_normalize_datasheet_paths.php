<?php

class UpdateDocumentsNormalizeDatasheetPaths extends Mad_Model_Migration_Base
{
    public function up()
    {
        // Manufacturer folders directly under datasheets (parent_folder_id = 2).
        // Change path from "datasheets/" to "datasheets/{slug}/".
        $rows = $this->selectAll(
            "SELECT id, slug FROM document_folders
             WHERE parent_folder_id = 2 AND path = 'datasheets/'"
        );
        foreach ($rows as $row) {
            $this->update(
                "UPDATE document_folders SET path = ? WHERE id = ?",
                ['datasheets/' . $row['slug'] . '/', $row['id']]
            );
        }

        // Sub-sub-folders under manufacturer folders (e.g. cmd/older, mos/app_briefs, wdc/older).
        // Change path from "datasheets/" to "datasheets/{parent_slug}/{slug}/".
        $rows = $this->selectAll(
            "SELECT child.id, child.slug, parent.slug AS parent_slug
             FROM document_folders child
             JOIN document_folders parent ON child.parent_folder_id = parent.id
             WHERE parent.parent_folder_id = 2 AND child.path = 'datasheets/'"
        );
        foreach ($rows as $row) {
            $this->update(
                "UPDATE document_folders SET path = ? WHERE id = ?",
                ['datasheets/' . $row['parent_slug'] . '/' . $row['slug'] . '/', $row['id']]
            );
        }

        // Rename "Older" to "Older Versions" for consistency (CMD folder).
        $this->update(
            "UPDATE document_folders SET title = 'Older Versions' WHERE id = 21"
        );
    }

    public function down()
    {
        // Revert all datasheet subfolder paths back to flat "datasheets/".
        $this->update(
            "UPDATE document_folders SET path = 'datasheets/'
             WHERE path LIKE 'datasheets/%/%'"
        );

        // Revert title.
        $this->update(
            "UPDATE document_folders SET title = 'Older' WHERE id = 21"
        );
    }
}
