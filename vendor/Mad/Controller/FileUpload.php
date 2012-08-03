<?php
/**
 * @category   Mad
 * @package    Mad_Controller
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * A file upload from multipart form
 *
 * @category   Mad
 * @package    Mad_Controller
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Controller_FileUpload
{
    public $originalFilename = null;
    public $length           = null;
    public $contentType      = null;
    public $path             = null;

    public function __construct($options)
    {
        $this->originalFilename = isset($options['name'])     ? $options['name']     : null;
        $this->length           = isset($options['size'])     ? $options['size']     : null;
        $this->contentType      = isset($options['type'])     ? $options['type']     : null;
        $this->path             = isset($options['tmp_name']) ? $options['tmp_name'] : null;
    }
}