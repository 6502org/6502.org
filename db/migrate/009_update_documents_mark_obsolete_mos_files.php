<?php

class UpdateDocumentsMarkObsoleteMosFiles extends Mad_Model_Migration_Base
{
    public function up()
    {
        // Preliminary datasheets where a newer version exists,
        // and older dated versions where a newer version exists.
        // "Recreated" datasheets do not supersede originals.
        // The undated 6510 and 65245 datasheets are CSG era (newer)
        // while the dated ones are MOS Technology era (older).
        $this->update(
            "UPDATE document_files SET obsolete = 1
             WHERE id IN (649, 651, 277, 645, 18, 647, 633, 388, 648, 640, 12, 644)"
        );
    }

    public function down()
    {
        $this->update(
            "UPDATE document_files SET obsolete = 0
             WHERE id IN (649, 651, 277, 645, 18, 647, 633, 388, 648, 640, 12, 644)"
        );
    }
}
