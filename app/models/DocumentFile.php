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

    /**
     * Find a file by its full folder path and filename,
     * e.g. "downloads/mini-projects/datapod/datapod_source_code.zip"
     */
    public static function findByPath($path)
    {
        $parts = explode('/', trim($path, '/'));
        $filename = array_pop($parts);
        $folderPath = implode('/', $parts) . '/';

        return self::find('first', [
            'conditions' => 'LOWER(filename) = :filename AND folder_id IN '
                          . '(SELECT id FROM document_folders WHERE path = :folder_path)'
        ], [
            ':filename' => strtolower($filename),
            ':folder_path' => $folderPath
        ]);
    }

    public function localPath()
    {
        return DOCUMENTS_ROOT
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
