<?php

class UpdateDocumentsFixSelectedArticlesPath extends Mad_Model_Migration_Base
{
    public function up()
    {
        // "Selected Articles" is a subfolder of "Dr. Dobb's Journal".
        // Path should reflect the hierarchy, not a flat compound name.
        $this->update(
            "UPDATE document_folders
             SET path = 'periodicals/dr_dobbs_journal/selected_articles/'
             WHERE id = 42"
        );
    }

    public function down()
    {
        $this->update(
            "UPDATE document_folders
             SET path = 'periodicals/dr_dobbs_journal_selected_articles/'
             WHERE id = 42"
        );
    }
}
