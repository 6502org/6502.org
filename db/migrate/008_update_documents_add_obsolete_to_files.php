<?php

class UpdateDocumentsAddObsoleteToFiles extends Mad_Model_Migration_Base
{
    public function up()
    {
        $this->addColumn('document_files', 'obsolete', 'boolean', [
            'null' => false, 'default' => false
        ]);

        // Mark all files in the "older" folders as obsolete.
        $this->update(
            "UPDATE document_files SET obsolete = 1
             WHERE folder_id IN (SELECT id FROM document_folders WHERE slug = 'older')"
        );

        // Move files from "older" subfolders into their parent folders.
        // cmd/older (id=21) -> cmd (id=3)
        $this->update(
            "UPDATE document_files SET folder_id = 3 WHERE folder_id = 21"
        );
        // wdc/older (id=13) -> wdc (id=7)
        $this->update(
            "UPDATE document_files SET folder_id = 7 WHERE folder_id = 13"
        );

        // Remove the now-empty "older" folders.
        $this->execute("DELETE FROM document_folders WHERE id IN (13, 21)");
    }

    public function down()
    {
        // Recreate the "older" folders.
        $this->execute(
            "INSERT INTO document_folders (id, title, sort_title, description, path, parent_folder_id, slug)
             VALUES (21, 'Older Versions', NULL, NULL, 'datasheets/cmd/older/', 3, 'older')"
        );
        $this->execute(
            "INSERT INTO document_folders (id, title, sort_title, description, path, parent_folder_id, slug)
             VALUES (13, 'Older Versions', NULL, NULL, 'datasheets/wdc/older/', 7, 'older')"
        );

        // Move obsolete files back to their "older" folders.
        $this->update(
            "UPDATE document_files SET folder_id = 21
             WHERE folder_id = 3 AND obsolete = 1"
        );
        $this->update(
            "UPDATE document_files SET folder_id = 13
             WHERE folder_id = 7 AND obsolete = 1"
        );

        // Drop the column by recreating the table. SQLite's ALTER TABLE
        // DROP COLUMN can't handle the UNIQUE index on this table.
        $this->execute("
            CREATE TABLE document_files_backup AS
            SELECT id, title, filename, pages, sort_title, filesize,
                   folder_id, created_at, visible, sha1, mirror_url
            FROM document_files
        ");
        $this->execute("DROP TABLE document_files");
        $this->execute("
            CREATE TABLE document_files (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                title varchar(100) NOT NULL,
                filename varchar(100) NOT NULL,
                pages int NOT NULL DEFAULT 0,
                sort_title varchar(100),
                filesize int NOT NULL DEFAULT 0,
                folder_id int NOT NULL DEFAULT 0,
                created_at datetime NOT NULL,
                visible int DEFAULT 1,
                sha1 varchar(40) NOT NULL,
                mirror_url text
            )
        ");
        $this->execute("
            INSERT INTO document_files
            SELECT * FROM document_files_backup
        ");
        $this->execute("DROP TABLE document_files_backup");
        $this->execute("
            CREATE UNIQUE INDEX idx_document_files_filename
            ON document_files (filename COLLATE NOCASE)
        ");
    }
}
