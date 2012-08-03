<?php
/**
 * @category   Mad
 * @package    Mad_Controller
 * @copyright  (c) 2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
 
/**
 * Horde_Routes_Mapper requires a list of all possible controller names
 * in order to build the regular expressions it uses for matching routes.
 * It uses a callback, controllerScan, to get this list.
 *
 * Depending on the routes connected to the mapper, it may be possible to
 * determine all of the controller names from the routes themselves.  If
 * not, the filesystem must be scanned to determine the controller names.
 *
 * This class contains two controllerScan strategies, one that scans the
 * filesystem and one that doesn't, and can determine the most efficient
 * strategy to use for a given mapper.
 *
 * @category   Mad
 * @package    Mad_Controller
 * @copyright  (c) 2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Controller_Scanner
{
    /**
     * @var Horde_Routes_Mapper
     */
    protected $_mapper;
    
    /**
     * controllerScan strategy selected for this mapper.
     * @var callback
     */
    protected $_callback;
    
    /**
     * Array of controller names collected from route hardcodes
     * @var array
     */
    protected $_controllers;


    /**
     * Constructor.  Analyze the routes connected to this mapper to
     * select a controllerScan strategy.
     *
     * @param  Horde_Routes_Mapper
     */
    public function __construct($mapper)
    {
        $this->_mapper = $mapper;
        $this->analyze();
    }

    /**
     * Analyze the routes connected to the mapper.  If all of the possible
     * controller names can be determined from the routes themselves, select
     * the scanHardcodes() strategy that returns them collected from the
     * routes.  If the possible controller names cannot be determined this
     * way, select the scanFilesystem() strategy.
     */
    public function analyze()
    {
        $needScan = false;
        $controllers = array();
        foreach ($this->_mapper->matchList as $route) {
            if (in_array('controller', $route->hardCoded)) {
                $controllers[ $route->defaults['controller'] ] = true;
            } else {
                $needScan = true;
                break;
            }
        }
        $this->_controllers = array_keys($controllers);

        if ($needScan || empty($this->_controllers)) {
            $this->_callback = array($this, 'scanFilesystem');
        } else {
            $this->_callback = array($this, 'scanHardcodes');
        }
    }

    /**
     * Get the controllerScan callback stategy selected for this mapper.
     *
     * @return callback
     */
    public function getCallback()
    {
        return $this->_callback;
    }
    
    /**
     * Scan a directory and return an array of the controllers it contains.
     * The array is used by Horde_Routes to build its matching regexps.
     *
     * @param  string  $dirname  Controller directory
     * @param  string  $prefix   Prefix controllers found with string
     * @return array             Controller names
     */ 
    public function scanFilesystem($dirname = null, $prefix = '')
    {
        if ($dirname === null) { 
            return array(); 
        }

        $controllers = array();
        foreach (new DirectoryIterator($dirname) as $entry) {
            if ($entry->isFile()) {
                if (preg_match('/^[^_]{1,1}.*\.php$/', $entry) !== false) {
                    $c = $prefix . substr($entry->getFilename(), 0, -4);
                    $c = strtolower(preg_replace('/([a-z])([A-Z])/', "\${1}_\${2}", $c));
                    $c = substr($c, 0, -(strlen('_controller')));
                    $controllers[] = $c;
                }
            }
        }

        usort($controllers, 'Horde_Routes_Utils::longestFirst');
        return $controllers;
    }

    /**
     * Return an array of controller names that were collected from the
     * hardcodes of the routes connected to this mapper.
     *
     * @param  string  $dirname  For method signature compatibility only
     * @param  string  $prefix   Prefix controllers found with string
     * @return array             Controller names
     */
    public function scanHardcodes($dirname = null, $prefix = null)
    {
        if ($prefix === null) {
            $controllers = $this->_controllers;
        } else {
            $controllers = array();
            foreach ($this->_controllers as $controller) {
                $controllers[] = $prefix . $controller;
            }
        }

        usort($controllers, 'Horde_Routes_Utils::longestFirst');
        return $controllers;        
    }
    
}