<?php

class DocumentFile extends Mad_Model_Base
{
    public function _initialize()
    {
        $this->belongsTo('DocumentFolder', ['foreignKey' => 'folder_id']);

        $this->validatesPresenceOf('title');
        $this->validatesPresenceOf('filename');
        $this->validatesUniquenessOf('filename');
        $this->validatesPresenceOf('folder_id');
        $this->validatesFormatOf('sha1', ['with' => '/^[0-9a-f]{40}$/']);
        $this->validatesNumericalityOf('pages');
        $this->validatesNumericalityOf('filesize');
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

    public function isIntact()
    {
        return $this->isReadable() && sha1_file($this->localPath()) === $this->sha1;
    }

}
