<?php

class DocumentsController extends ApplicationController
{
    public function index() {
    	$docrootPath   = dirname(dirname(__FILE__)) . '/public_html';

        $config = Horde_Yaml::loadFile(MAD_ROOT.'/config/database.yml');
        $spec = $config[MAD_ENV];
        $pdo = new PDO("mysql:host=${spec['host']};dbname=${spec['database']}", $spec['username'], $spec['password']);

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
    			$sql = "AND parent_id='".$this->sections[count($this->sections)-1]['id']."'";
    		} else {
    			$sql = "AND parent_id='0'"; 
    		}

    		$sql="SELECT * FROM docs_sections WHERE section_key='$key' $sql LIMIT 1";
    		$rows = iterator_to_array($pdo->query($sql));
    		$section = $rows[0];

    		if (!empty($section)) {
    			$url .= $section['section_key'] . '/';
    			$section['url'] = $url;
    			array_push($this->sections, $section); 
    		} else {
    			/* If the key does not exist, it might also be a filename.  If it is,
    			   update the download counter and redirect.  */
    			if (count($this->sections) > 0) {
    				$sql  = "SELECT * FROM docs_items WHERE filename='$key' AND ";
    				$sql .= "FIND_IN_SET('".$this->sections[count($this->sections)-1]['id']."',section_ids) LIMIT 1";

                    $rows = iterator_to_array($pdo->query($sql));
                    $item = $rows[0];

    				if (empty($item)) {
    					// If the filename could not be found, redirect to last known-good keys.
    					header ("Location: $url");
    					exit(); 
    				} else {
    					// If the filename was found, update the download counter and redirect to download.
    					$sql = "UPDATE docs_items SET downloads=downloads+1 WHERE id='".$item['id']."'";
    					$pdo->query($sql);
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
  
    	$sql="SELECT * FROM docs_sections WHERE FIND_IN_SET('$myId', parent_id) ORDER BY title ASC";
        $this->mySections = iterator_to_array($pdo->query($sql));

    	for ($i=0; $i<count($this->mySections); $i++) {
    		$this->mySections[$i]['url'] = $url . $this->mySections[$i]['section_key'] . '/';
    	}
	
    	$this->mySection['items'] = array();

		$sql="SELECT * FROM docs_items WHERE FIND_IN_SET($myId,section_ids) ORDER BY sort_title, title ASC";
		$this->mySection['items'] = iterator_to_array($pdo->query($sql));

        $this->_updateFileSizes();

        /* Create URL for each item */	
        foreach ($this->mySection['items'] as &$item) {
            $item['url'] = $url . $item['filename'];
        }

    }

    // Update size of any file whose size_kb entry is 0
    protected function _updateFileSizes()
    {
    	for ($i=0; $i<count($this->mySection['items']); $i++) {
    		$fileSize = $this->mySection['items'][$i]['size_kb'];

    		if ($fileSize==0) {
    			$filename = $this->mySection['items'][$i]['filename'];
                $filespec = dirname(dirname($docrootPath)) . '/archive.6502.org/' . $this->mySection['path'] . $filename;
	  		
    	  		if (file_exists($filespec)) {
    				$fileSize = intval(@filesize($filespec) / 1024);
    		  		$this->mySection['items'][$i]['size_kb'] = $fileSize;
		  		
    		  		$sql = "UPDATE docs_items SET size_kb=$fileSize WHERE filename='$filename' AND find_in_set($myId,section_ids)";
    				$result = $pdo->query($sql);
    	  		}
    		}
    	}        
    }
}
