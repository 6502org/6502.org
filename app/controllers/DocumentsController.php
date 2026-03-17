<?php

class DocumentsController extends ApplicationController
{
    public function index() {
        $this->db = Mad_Model_Base::connection();

        $keyList = explode('/', trim($this->params['path'], '/'));
        foreach($keyList as $k => $v) {
            if (empty($v)) { unset($keyList[$k]); }
        }
        array_unshift($keyList, 'documents');

        /* Welcome message */
        $welcome = "Documents Archive";
        $title = "Documents Archive";
        $description = "A collection of useful documents pertaining to the 6502 microprocessor.";

        /* Validate all keys by retrieving the folder information for
           each key from the database.  If an invalid key is found, redirect the URL
           using the preceeding known-good keys.  */
        $this->folders = array();
        $url = "/";
        foreach($keyList as $key) {
            if (!empty($this->folders)) {
                $parent_folder_id = $this->folders[count($this->folders)-1]['id'];
            } else {
                $parent_folder_id = 0;
            }

            $sql = 'SELECT *
                    FROM document_folders
                    WHERE (slug = ?) AND (parent_folder_id = ?)
                    LIMIT 1';
            $folder = $this->db->selectOne($sql, array($key, $parent_folder_id));

            if (!empty($folder)) {
                $url .= $folder['slug'] . '/';
                $folder['url'] = $url;
                array_push($this->folders, $folder);
            } else {
                /* If the key does not exist, it might also be a filename.
                   If it is, redirect.  */
                if (count($this->folders) > 0) {
                    $sql = 'SELECT *
                            FROM document_files
                            WHERE (filename = ?) AND (folder_id = ?)
                            LIMIT 1';
                    $doc = $this->db->selectOne($sql,
                        array($key, $this->folders[count($this->folders)-1]['id']));

                    if (empty($doc)) {
                        // If the filename could not be found, redirect to last known-good keys.
                        $this->redirectTo($url);
                        return;
                    } else {
                        // If the filename was found, redirect to download.

                        // TODO: send the document file
                        /*
                        $folder = $this->folders[count($this->folders)-1];
                        $filename = $this->_getLocalFilename($doc, $folder);
                        $options = array('type' => 'application/octet-stream');
                        $ext = pathinfo($filename, PATHINFO_EXTENSION);
                        if ($ext == 'pdf') {
                            $options['type'] = 'application/pdf';
                            $options['disposition'] = 'inline';
                        }
                        $this->sendFile($filename, $options);
                        return;
                        */

                        if (DOCUMENTS_USE_MIRROR_URL && !empty($doc['mirror_url'])) {
                            $url = $doc['mirror_url'];
                        } else {
                            $url = "http://archive.6502.org/" .
                                   $this->folders[count($this->folders)-1]['path'] .
                                   $doc['filename'];
                        }
                        $this->redirectTo($url);
                        return;
                    }
                } else {
                    // Last key was not a valid key or filename.  Redirect to last known-good keys.
                    $this->redirectTo($url);
                    return;
                }
            }
        }

        // Get subfolders of the current folder
        $this->myFolder = $this->folders[count($this->folders)-1];
        $sql="SELECT * FROM document_folders
              WHERE parent_folder_id = ?
              ORDER BY LOWER(COALESCE(sort_title, title)) ASC";
        $this->myFolders = $this->db->selectAll($sql, array($this->myFolder['id']));

        for ($i=0; $i<count($this->myFolders); $i++) {
            $this->myFolders[$i]['url'] = $url . $this->myFolders[$i]['slug'] . '/';
        }

        $sql="SELECT * FROM document_files
              WHERE folder_id = ?
              ORDER BY LOWER(COALESCE(sort_title, title)) ASC";
        $this->myFolder['docs'] = $this->db->selectAll($sql, array($this->myFolder['id']));

        // Create URL for each doc
        foreach ($this->myFolder['docs'] as &$doc) {
            $doc['url'] = $url . $doc['filename'];
        }

    }

    // Get the full path to the document on disk
    protected function _getLocalFilename($doc, $folder)
    {
        return dirname(MAD_ROOT) . '/archive.6502.org/public/'
                                 . $folder['path']
                                 . $doc['filename'];
    }

}
