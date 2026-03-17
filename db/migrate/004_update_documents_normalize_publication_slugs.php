<?php

class UpdateDocumentsNormalizePublicationSlugs extends Mad_Model_Migration_Base
{
    public function up()
    {
        // Rename slug "publications" to "periodicals" to match
        // the folder's title "Periodicals".
        $this->update(
            "UPDATE document_folders SET slug = 'periodicals' WHERE id = 14"
        );

        // Rename slug "interactive" to "aiminteractive" to match the
        // publication name "AIM Interactive".
        $this->update(
            "UPDATE document_folders SET slug = 'aiminteractive' WHERE id = 16"
        );

        // Update all publication paths from "publications/" to "periodicals/"
        // to match the parent folder's slug rename.
        $this->update(
            "UPDATE document_folders SET path = REPLACE(path, 'publications/', 'periodicals/')
             WHERE path LIKE 'publications/%'"
        );

        // Fix "commodore_computing_intl" abbreviation in path to match the
        // full slug "commodore_computing_international".
        $this->update(
            "UPDATE document_folders
             SET path = 'periodicals/commodore_computing_international/'
             WHERE id = 37"
        );
    }

    public function down()
    {
        $this->update(
            "UPDATE document_folders SET slug = 'interactive' WHERE id = 16"
        );

        $this->update(
            "UPDATE document_folders SET slug = 'publications' WHERE id = 14"
        );

        $this->update(
            "UPDATE document_folders
             SET path = 'publications/commodore_computing_intl/'
             WHERE id = 37"
        );

        $this->update(
            "UPDATE document_folders SET path = REPLACE(path, 'periodicals/', 'publications/')
             WHERE path LIKE 'periodicals/%'"
        );
    }
}
