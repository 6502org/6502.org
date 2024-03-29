<?php

class DocumentsController extends ApplicationController
{
    public function index() {
        $config = Horde_Yaml::loadFile(MAD_ROOT.'/config/database.yml');
        $spec = $config[MAD_ENV];
        if ($spec['adapter'] == 'sqlite') {
            $dbfile = $spec['database'];
            if ($dbfile[0] != '/') { $dbfile = MAD_ROOT . '/' . $dbfile; }
            $this->pdo = new PDO("sqlite:$dbfile", null, null);
        } else { // mysql
            $this->pdo = new PDO("mysql:host=${spec['host']};dbname=${spec['database']}",
                                 $spec['username'], $spec['password']);
        }

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
                    WHERE (slug = :slug) AND (parent_folder_id = :parent_folder_id)
                    LIMIT 1';
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute(array('slug' => $key,
                                 'parent_folder_id' => $parent_folder_id));
            $folder = $stmt->fetch();

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
                            WHERE (filename = :key) AND (folder_id = :id)
                            LIMIT 1';
                    $stmt = $this->pdo->prepare($sql);
                    $stmt->execute(array('key' => $key,
                                         'id'  => $this->folders[count($this->folders)-1]['id']));
                    $doc = $stmt->fetch();

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
              WHERE parent_folder_id = :id
              ORDER BY LOWER(COALESCE(sort_title, title)) ASC";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array('id' => $this->myFolder['id']));
        $this->myFolders = $stmt->fetchAll();

        for ($i=0; $i<count($this->myFolders); $i++) {
            $this->myFolders[$i]['url'] = $url . $this->myFolders[$i]['slug'] . '/';
        }

        $sql="SELECT * FROM document_files
              WHERE folder_id = :id
              ORDER BY LOWER(COALESCE(sort_title, title)) ASC";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array('id' => $this->myFolder['id']));
        $this->myFolder['docs'] = $stmt->fetchAll();

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
