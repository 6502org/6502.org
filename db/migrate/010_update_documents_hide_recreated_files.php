<?php

class UpdateDocumentsHideRecreatedFiles extends Mad_Model_Migration_Base
{
    public function up()
    {
        /*
         * These two "recreated" datasheets are redrawn versions of
         * originals.  Although someone worked hard on them and they
         * are pretty, they aren't real datasheets and thus shouldn't
         * be in the archive.  So that existing links still work, we
         * keep them, but as hidden.  Retouched datasheets are fine
         * but self-drawn ones are out of scope for the archive.
         */
        $this->update(
            "UPDATE document_files SET visible = 0
             WHERE id IN (184, 185)"
        );
    }

    public function down()
    {
        $this->update(
            "UPDATE document_files SET visible = 1
             WHERE id IN (184, 185)"
        );
    }
}
