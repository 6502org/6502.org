<?php
/**
 * @category   Mad
 * @package    Mad_Controller
 * @subpackage Response
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * Represents an HTTP response to the user.
 *
 * @category   Mad
 * @package    Mad_Controller
 * @subpackage Response
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Controller_Response_Http
{
    /**
     * Cookies sent with response
     * @var array
     */
    protected $_cookie = array();
     
    /**
     * Stored session data
     * @var array
     */
    protected $_session = array();

    /**
     * Session data saved for a single request
     * @var array
     */
    protected $_flash = array();


    /**
     * The url to redirect the request to
     * @var string
     */
    protected $_redirectUrl = null;

    /**
     * The http status code. Default to OK
     * @var string
     */
    protected $_status = '200 OK';

    /**
     * HTTP headers to send
     * @var array
     */
    protected $_headers = array();

    /**
     * prevent cached content (ie)
     * @var array
     */
    protected $_preventCache = true;

    /**
     * Body of the rendered page
     * @var string
     */
    protected $_body = null;


    /*##########################################################################
    # Construct
    ##########################################################################*/

    /**
     * Construct response
     */
    public function __construct(){}


    /*##########################################################################
    # Instance methods
    ##########################################################################*/

    /**
     * Set the url for redirection
     * 
     * @param   string  $toUrl
     */
    public function redirect($toUrl)
    {
        $this->_status = '302 Found';
        $this->_redirectUrl = $toUrl;
        $this->_headers["Location: $toUrl"] = true;
    }

    /**
     * Page was not found
     */
    public function pageNotFound()
    {
        $this->_status = '404 Page Not Found';
    }

    /**
     * Send content to the browser.
     *
     * After the body content has been sent, terminates the execution of the
     * PHP script.
     */
    public function send()
    {
        // send all headers
        foreach ($this->getHeaders() as $header => $replace) {
            header($header, $replace);
        }

        // set cookies
        foreach ($this->_cookie as $name => $options) {
            // simulate cookie set on test
            if (MAD_ENV == 'test') {
                $_COOKIE[$name] = $options['value'];
            } else {
                setcookie($name, $options['value'], $options['expiration'], 
                                 $options['path']);
            }
        }

        // set flash/session data
        $this->_session['_flash'] = $this->_flash;
        foreach ($this->_session as $name => $value) {
            $_SESSION[$name] = $value;
        }

        // send body
        print $this->getBody();
    }


    /*##########################################################################
    # Accessors
    ##########################################################################*/
    
    /**
     * Set a cookie
     * 
     * @param   string  $name
     * @param   string  $value
     * @param   int     $expiration
     * @param   string  $path
     */
    public function setCookie($name, $value, $expiration=0, $path=null)
    {
        // only set cookies for this matter by default
        $this->_cookie[$name] = array('value'      => $value,
                                      'expiration' => $expiration,
                                      'path' => isset($path) ? $path : '/');
    }

    /**
     * Set a session variable OR all session variables (by array).
     *
     * <code>
     *  // set single session var
     *  $this->setSession('NAME', 'my session');
     *
     *  // set all session vars (overwrites previous single sessions set)
     *  $this->setSession(array('NAME 1' => 'my session 1',
     *                          'NAME 2' => 'my session 2'));
     * </code>
     * 
     * @param   mixed   $name
     * @param   mixed   $value
     */
    public function setSession($name, $value=null)
    {
        // Set by name or all at once
        if (is_string($name)) {
            $this->_session[$name] = $value;
        } elseif (is_array($name)) {
            $this->_session = $name;
        }
    }

    /**
     * Set a flash variable OR all flash variables (by array).
     *
     * <code>
     *  // set single flash var
     *  $this->setFlash('NAME', 'my flash');
     *
     *  // set all flash vars (overwrites previous single flash set)
     *  $this->setFlash(array('NAME 1' => 'my flash 1',
     *                        'NAME 2' => 'my flash 2'));
     * </code>
     * 
     * @param   mixed   $name
     * @param   mixed   $value
     */
    public function setFlash($name, $value=null)
    {
        // Set by name or all at once
        if (is_string($name)) {
            if ($value === null) {
                unset($this->_flash[$name]);
            } else {
                $this->_flash[$name] = $value;
            }
        } elseif (is_array($name)) {
            $this->_flash = $name;
        }
    }

    /**
     * Add header information
     * 
     * @param   string  $header
     * @param   boolean $replace
     */
    public function setHeader($header, $replace=true)
    {
        $this->_headers[$header] = $replace;
    }

    /**
     * Set the body of the response
     * 
     * @param   string  $body
     */
    public function setBody($body)
    {
        $this->_body = $body;
    }
    
    /**
     * Set the HTTP status code
     * 
     * @param   string  $status
     */
    public function setStatus($status)
    {
        $this->_status = $status;
    }

    /**
     * Get the headers of the response
     * 
     * @return  array
     */
    public function getHeaders()
    {
        $headers["HTTP/1.1 $this->_status"] = true;

        if ($this->_status == '200 OK') {
            $headers["Connection: close"] = true;
            $headers["Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT"] = true;

            // Try to keep browser from caching any screen to ensure current data.
            if ($this->_preventCache && !isset($this->_headers["Expires: 0"])) {
                $headers["Expires: Mon, 26 Jul 1997 05:00:00 GMT"]             = true;
                $headers["Cache-Control: no-store, no-cache, must-revalidate"] = true;
                $headers["Pragma: no-cache"]                                   = true;
            }
        }
        return array_merge($this->_headers, $headers);
    }

    /**
     * Get the body of the response
     * 
     * @return  string
     */
    public function getBody()
    {
        return $this->_body;
    }

    /**
     * Get the HTTP status of the response
     * 
     * @return  string
     */
    public function getStatus()
    {
        return $this->_status;
    }

    /**
     * Get  3 digit http code from the status
     * 
     * @return  int
     */
    public function getStatusCode()
    {
        preg_match("/(\d\d\d)/", $this->_status, $matches);
        return isset($matches[1]) ? (int) $matches[1] : 0;
    }

    /**
     * @todo charset
     */
    public function setContentType($mimeType)
    {
        $this->setHeader("Content-Type: $mimeType", $replace=true);
    }

    /**
     * Get if the response is a 200 OK
     * 
     * @return  boolean
     */
    public function getIsOk()
    {
        return substr($this->_status, 0, 1) == '2';
    }

    /**
     * Get if the response is a redirection
     * 
     * @return  boolean
     */
    public function getIsRedirect()
    {
        return substr($this->_status, 0, 1) == '3';
    }

    /**
     * Get where the page is redirecting to
     * 
     * @return  string
     */
    public function getRedirectUrl()
    {
        return $this->_redirectUrl;
    }
}
