<?php
/**
 * @category   Mad
 * @package    Mad_Controller
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * Dispatch a request to the appropriate controller and execute the response
 *
 * @category   Mad
 * @package    Mad_Controller
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Controller_Dispatcher
{
    /** @var Mad_Controller_Dispatcher */
    private static $_instance;

    /** @var Mad_Controller_Request_Http */
    private $_request;

    /** @var Horde_Routes_Mapper */
    private $_mapper;

    /**
     * Singleton instance
     */
    public static function getInstance()
    {
        if (self::$_instance === null) {
            self::$_instance = new self();
        }
        return self::$_instance;
    }

    /**
     * Class constructor.  Initialize the mapper and configure it with
     * our controller directory and scan callback.  Load the route
     * definitions into the mapper.
     */
    private function __construct()
    {
        $this->reload();
    }

    /** 
     * Reload the routes for dispatching
     */
    public function reload()
    {
        $options = array('directory' => MAD_ROOT . '/app/controllers',
                         'explicit'  => false
                        );

        $map = new Horde_Routes_Mapper($options);
        include MAD_ROOT . '/config/routes.php';

        $scanner = new Mad_Controller_Scanner($map);
        $map->controllerScan = $scanner->getCallback();

        $this->_mapper = $map;
    }

    /**
     * Get the route mapper for this dispatcher
     *
     * @return  Horde_Routes_Mapper
     */
    public function getRouteMapper()
    {
        return $this->_mapper;
    }

    /**
     * Get the route utilities for this dispatcher and its mapper
     *
     * @return  Horde_Routes_Utils
     */
    public function getRouteUtils()
    {
        return $this->_mapper->utils;
    }

    /**
     * Dispatch the request to the correct controller
     *
     * @param  null|Mad_Controller_Request_Http  $request
     * @param  null|Mad_Controller_Response_Http $response
     * @return void
     */
    public function dispatch($request=null, $response=null)
    {
        $t = new Mad_Support_Timer;
        $t->start();

        if ($response === null) {
            $response = new Mad_Controller_Response_Http();
        }

        if ($request === null) {
            $request = new Mad_Controller_Request_Http();
        }

        // request could not be parsed
        if ($request->isMalformed()) {
            $body = "Your request could not be understood by the server, "
                  . "probably due to malformed syntax.\n\n";

            $exc = $request->getException();
            if ($exc && MAD_ENV != 'production') {
                $body .= $exc->getMessage();
            }

            $response->setStatus(400);
            $response->setBody($body);

        // dispatch request to controller
        } else {
            $controller = $this->recognize($request);
            $response   = $controller->process($request, $response);
        }

        $time = $t->finish();
        $this->_logRequest($request, $time);

        $response->send();
    }

    /**
     * Check if request path matches any Routes to get the controller
     *
     * @return  Mad_Controller_Base
     * @throws  Mad_Controller_Exception
     */
    public function recognize($request)
    {
        // pass a subset of the request environment
        // horde_routes_mapper for route matching
        $environ = array('REQUEST_METHOD' => $request->getMethod());
        foreach (array('HTTP_HOST', 'SERVER_NAME', 'HTTPS') as $k) { 
            $environ[$k] = $request->getServer($k); 
        }
        $this->_mapper->environ = $environ;

        $path = $request->getPath();
        if (substr($path, 0, 1) != '/') { $path = "/$path"; }

        $matchdata = $this->_mapper->match($path);
        if ($matchdata) { $hash = $this->formatMatchdata($matchdata); }
        
        if (empty($hash) || !isset($hash[':controller'])) {
            $msg = 'No routes in config/routes.php match the path: "'.$request->getPath().'"';
            throw new Mad_Controller_Exception($msg);
            return false;
        }
        $request->setPathParams($hash);

        // try to load the class
        $controllerName = $hash[':controller'];
        if (!class_exists($controllerName, false)) {
            $path = MAD_ROOT.'/app/controllers/'.$controllerName.'.php';
            if (file_exists($path)) {
                require_once $path;
            } else {
                $msg = "The Controller \"$controllerName\" does not exist at ".$path;
                throw new Mad_Controller_Exception($msg);
            }
        }
        return new $controllerName();
    }

    /**
     * Take the $matchdata returned by a Horde_Routes_Mapper match and add
     * in :controller and :action that are used by the rest of the framework.
     * 
     * Format controller names: my_stuff => MyStuffController
     * Format action names:     action_name => actionName
     * 
     * @param   array   $matchdata
     * @return  mixed   false | array
     */
    public function formatMatchdata($matchdata)
    {
        $ret = array();
        foreach ($matchdata as $key=>$val) {
            if ($key == 'controller') {
                $ret['controller'] = $val;
                $ret[':controller'] = Mad_Support_Inflector::camelize($val).'Controller';
            } elseif ($key == 'action') {
                // Horde_Routes_Mapper->resource() and Python Routes are inconsistent
                // with Rails by using "delete" instead of "destroy".
                if ($val == 'delete') { $val = 'destroy'; }

                $ret['action']  = $val;
                $ret[':action'] = Mad_Support_Inflector::camelize($val, 'lower');
            } else {
                $ret[$key] = $val;
            }
        }
        return !empty($ret) && isset($ret['controller']) ? $ret : false;
    }

    /*##########################################################################
    # Logger
    ##########################################################################*/

    /**
     * Returns the logger object.
     *
     * @return  object
     */
    public static function logger()
    {
        return $GLOBALS['MAD_DEFAULT_LOGGER'];
    }

    /**
     * Log the http request
     *
     * @todo - get total query times
     *
     * @param   Mad_Controller_Request_Http $request
     * @param   int $totalTime
     */
    protected function _logRequest(Mad_Controller_Request_Http $request, $totalTime)
    {
        $queryTime  = 0; // total time to execute queries
        $queryCount = 0; // total queries performed
        $phpTime = $totalTime - $queryTime;

        // embed user info in log
        $uri    = $request->getUri();
        $method = $request->getMethod();

        $paramStr = 'PARAMS=' . $this->_formatLogParams($request->getParameters());

        $msg = "$method $uri $totalTime ms (DB=$queryTime [$queryCount] PHP=$phpTime) $paramStr";
        $msg = wordwrap($msg, 80, "\n\t  ", 1);

        Mad_Controller_Dispatcher::logger()->info($msg);
    }

    /**
     * Formats the request parameters as a "key => value, key => value, ..." string
     * for the log file.
     *
     * @param array $params
     * @return string
     */
    protected function _formatLogParams($params)
    {
        $paramStr = '{';
        $count = 0;
        foreach ($params as $key => $value) {
            if ($key != 'controller'  && $key != 'action' &&
                $key != ':controller' && $key != ':action') {
                if ($count++ > 0) { $paramStr .= ', '; }

                $paramStr .= $key.' => ';

                if (is_array($value)) {
                    $paramStr .= $this->_formatLogParams($value);
                } elseif (is_object($value)) {
                    $paramStr .= get_class($value);
                } else {
                    $paramStr .= $value;
                }
            }
        }
        return $paramStr . '}';
    }

}
