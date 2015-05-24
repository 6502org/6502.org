<?php

class DocumentsController extends ApplicationController
{
    public function index() {
        $config = Horde_Yaml::loadFile(MAD_ROOT.'/config/database.yml');
        $spec = $config[MAD_ENV];
        $this->pdo = new PDO("mysql:host=${spec['host']};dbname=${spec['database']}",
                             $spec['username'],
                             $spec['password']);

	    $keyList = explode('/', trim($this->params['path'], '/'));
        foreach($keyList as $k => $v) {
            if (empty($v)) { unset($keyList[$k]); }
        }
        array_unshift($keyList, 'documents');

      /* Welcome message */
    	$welcome = "Documents Archive";
    	$title = "Documents Archive";
    	$description = "A collection of useful documents pertaining to the 6502 microprocessor.";

      /* Validate all keys by retrieving the section information for
         each key from the database.  If an invalid key is found, redirect the URL
         using the preceeding known-good keys.  */
        $this->sections = array();
    	$url = "/";
    	foreach($keyList as $key) {
            if (!empty($this->sections)) {
                $parent_folder_id = $this->sections[count($this->sections)-1]['id'];
            } else {
                $parent_folder_id = 0;
            }

            $sql = 'SELECT *
                    FROM docs_sections
                    WHERE (slug = :slug) AND (parent_folder_id = :parent_folder_id)
                    LIMIT 1';
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute(array('slug' => $key,
                                 'parent_folder_id' => $parent_folder_id));
            $section = $stmt->fetch();

    		if (!empty($section)) {
    			$url .= $section['slug'] . '/';
    			$section['url'] = $url;
    			array_push($this->sections, $section);
    		} else {
    			/* If the key does not exist, it might also be a filename.  If it is,
    			   update the download counter and redirect.  */
    			if (count($this->sections) > 0) {
                    $sql = 'SELECT *
                            FROM docs_items
                            WHERE (filename = :key) AND (section_id = :id)
                            LIMIT 1';
                    $stmt = $this->pdo->prepare($sql);
                    $stmt->execute(array('key' => $key,
                                         'id'  => $this->sections[count($this->sections)-1]['id']));
                    $item = $stmt->fetch();

    				if (empty($item)) {
    					// If the filename could not be found, redirect to last known-good keys.
    					header ("Location: $url");
    					exit();
    				} else {
    					// If the filename was found, update the download counter and redirect to download.
                        $sql = 'UPDATE docs_items
                                SET downloads = downloads + 1
                                WHERE id = :id';
                        $stmt = $this->pdo->prepare($sql);
                        $stmt->execute(array('id' => $item['id']));

    					header ("Location: http://archive.6502.org/" . $this->sections[count($this->sections)-1]['path'] . $item['filename']);
    					exit();
    				}
    			} else {
    				// Last key was not a valid key or filename.  Redirect to last known-good keys.
    				header ("Location: $url");
    				exit();
    			}
    		}
    	}

        /* Get subsections of the current section */
      	$this->mySection = $this->sections[count($this->sections)-1];

      	$myId = $this->sections[count($this->sections)-1]['id'];

        $sql="SELECT * FROM docs_sections
              WHERE parent_folder_id = :id
              ORDER BY title ASC";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array('id' => $myId));
        $this->mySections = $stmt->fetchAll();

    	for ($i=0; $i<count($this->mySections); $i++) {
    		$this->mySections[$i]['url'] = $url . $this->mySections[$i]['slug'] . '/';
    	}

        $sql="SELECT * FROM docs_items
              WHERE section_id = :id
              ORDER BY sort_title, title ASC";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array('id' => $myId));
		$this->mySection['items'] = $stmt->fetchAll();

        $this->_updateFileSizes();
        $this->_updatePageCounts();

        /* Create URL for each item */
        foreach ($this->mySection['items'] as &$item) {
            $item['url'] = $url . $item['filename'];
        }

    }

    // Update size of any file whose filesize is 0
    protected function _updateFileSizes()
    {
        foreach ($this->mySection['items'] as &$item) {
    		if ($item['filesize'] == 0) {
                $filespec = dirname(MAD_ROOT)
                          . '/archive.6502.org/public/'
                          . $this->mySection['path']
                          . $item['filename'];

    	  		if (file_exists($filespec)) {
    		  		$item['filesize'] = filesize($filespec);

                    $sql = 'UPDATE docs_items
                            SET filesize = :filesize
                            WHERE id = :id';
                    $stmt = $this->pdo->prepare($sql);
                    $stmt->execute(array('filesize' => $item['filesize'],
                                         'id'       => $item['id']));
    	  		}
    		}
    	}
    }

    // Update PDF page counts of any file whose count is 0
    protected function _updatePageCounts()
    {
        foreach ($this->mySection['items'] as &$item) {
            if ($item['pages'] != 0) { continue; }

            // get filename on disk, ensure it exists
            $filespec = dirname(MAD_ROOT)
                      . '/archive.6502.org/public/'
                      . $this->mySection['path']
                      . $item['filename'];

            $pages = $this->_getPdfPageCount($filespec);
            if ($pages == 0) { continue; }

            // update row with page count
            $item['pages'] = $pages;
            $sql = 'UPDATE docs_items
                    SET pages = :pages
                    WHERE id = :id';
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute(array('pages' => $item['pages'],
                                 'id'    => $item['id']));
        }
    }

    // Get page count of a PDF, or 0 if any error
    protected function _getPdfPageCount($filename)
    {
        if (! file_exists($filename)) { return 0; }

        // ensure file is pdf
        $ext = pathinfo($filename, PATHINFO_EXTENSION);
        if ($ext != "pdf") { return 0; }

        // run pdfinfo on file
        $escaped = escapeshellarg($filename);
        exec("pdfinfo $escaped", $lines, $retval);
        if ($retval != 0) { return 0; }

        // parse pdfinfo output into key/value pairs
        $properties = array();
        foreach ($lines as $line) {
            $exploded = explode(":", $line, 2);
            if (count($exploded) != 2) { return 0; }
            $key = trim($exploded[0]);
            $value = trim($exploded[1]);
            if (strlen($key) && strlen($value)) { $properties[$key] = $value; }
        }

        // get page count from pdf info
        if (! array_key_exists("Pages", $properties)) { return 0; }
        return (int)$properties["Pages"];
    }

}
