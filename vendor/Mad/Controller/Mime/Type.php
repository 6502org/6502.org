<?php
/**
 * @category   Mad
 * @package    Mad_Controller
 * @subpackage Response
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * Represents an HTTP response to the user.
 *
 * @category   Mad
 * @package    Mad_Controller
 * @subpackage Response
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Controller_Mime_Type
{   
    public $symbol;
    public $synonyms;
    public $string;
    
    public static $set             = [];
    public static $lookup          = [];
    public static $extensionLookup = [];
    public static $registered      = false;
    
    public function __construct($string, $symbol = null, $synonyms = [])
    {
        $this->string   = $string;
        $this->symbol   = $symbol;
        $this->synonyms = $synonyms;
    }
    
    public function __toString()
    {
        return $this->symbol;
    }
    
    public static function lookup($string)
    {
        if (!empty(self::$lookup[$string])) {
            return self::$lookup[$string];
        } else {
            return null;
        }
    }
    
    public static function lookupByExtension($ext)
    {
        if (!empty(self::$extensionLookup[$ext])) {
            return self::$extensionLookup[$ext];
        } else {
            return null;
        }
    }

    public static function register($string, $symbol, $synonyms = [], $extSynonyms = [])
    {
        $type = new Mad_Controller_Mime_Type($string, $symbol, $synonyms);
        self::$set[] = $type;

        // add lookup strings
        foreach (array_merge((array)$string, $synonyms) as $string) {
            self::$lookup[$string] = $type;
        }

        // add extesnsion lookups
        foreach (array_merge((array)$symbol, $extSynonyms) as $ext) {
            self::$extensionLookup[$ext] = $type;
        }
    }
    
    /**
     * @todo - actually parse the header. This is simply mocked out
     * with common types for now
     */
    public static function parse($acceptHeader)
    {
        $types = [];

        if (strstr($acceptHeader, 'text/javascript')) {
            if (isset(self::$extensionLookup['js'])) {
                $types[] = self::$extensionLookup['js'];
            }
        
        } elseif (strstr($acceptHeader, 'text/html')) {
            if (isset(self::$extensionLookup['html'])) {
                $types[] = self::$extensionLookup['html'];
            }

        } elseif (strstr($acceptHeader, 'text/xml')) {
            if (isset(self::$extensionLookup['xml'])) {
                $types[] = self::$extensionLookup['xml'];
            }

        // default to html
        } else {
            if (isset(self::$extensionLookup['html'])) {
                $types[] = self::$extensionLookup['html'];
            }
        }
        return $types;
    }

    // Register mime types
    // @todo - move this elsewhere?    
    public static function registerTypes()
    {
        if (!self::$registered) {
            Mad_Controller_Mime_Type::register("*/*",             'all');
            Mad_Controller_Mime_Type::register("text/plain",      'text', [], ['txt']);
            Mad_Controller_Mime_Type::register("text/html",       'html', ['application/xhtml+xml'], ['xhtml']);
            Mad_Controller_Mime_Type::register("text/javascript", 'js',   ['application/javascript', 'application/x-javascript'], ['xhtml']);
            Mad_Controller_Mime_Type::register("text/csv",        'csv');
            Mad_Controller_Mime_Type::register("application/xml", 'xml',  ['text/xml', 'application/x-xml']);        
            self::$registered = true;
        }
    }
}
