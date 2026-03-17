<?php

class DocumentFile extends Mad_Model_Base
{
    public function _initialize()
    {
        $this->belongsTo('DocumentFolder', ['foreignKey' => 'folder_id']);
    }

    public function downloadUrl()
    {
        if ($this->isReadable()) {
            return '/documents/' . $this->documentFolder->path . $this->filename;
        }
        return $this->mirror_url;
    }

    public function localPath()
    {
        return MAD_ROOT . '/public/documents/'
             . $this->documentFolder->path . $this->filename;
    }

    public function isReadable()
    {
        return is_readable($this->localPath());
    }
}
