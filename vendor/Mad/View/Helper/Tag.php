<?php
/**
 * Use these methods to generate HTML tags programmatically.
 * By default, they output XHTML compliant tags.
 *
 * @category   Mad
 * @package    Mad_View
 * @subpackage Helper
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * Use these methods to generate HTML tags programmatically.
 * By default, they output XHTML compliant tags.
 *
 * @category   Mad
 * @package    Mad_View
 * @subpackage Helper
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_View_Helper_Tag extends Mad_View_Helper_Base
{
    /**
     * HTML attributes that get converted from boolean to the attribute name: 
     * array('disabled' => true) becomes array('disabled' => 'disabled')
     *
     * @var array
     */
    private $_booleanAttributes = array('disabled', 'readonly', 'multiple');
    
    /**
     * Returns an empty HTML tag of type $name which by default is XHTML
     * compliant. Setting $open to true will create an open tag compatible
     * with HTML 4.0 and below. Add HTML attributes by passing an attributes
     * hash to $options. For attributes with no value (like disabled and
     * readonly), give it a value of TRUE in the $options array.
     * 
     *   $this->tag("br")
     *      # => <br />
     *   $this->tag("br", null, true)
     *     # => <br>
     *   $this->tag("input", array('type' => 'text', 'disabled' => true))
     *      # => <input type="text" disabled="disabled" />
     * 
     * @param string   $name     Tag name
     * @param string   $options  Tag attributes
     * @param boolean  $open     Leave tag open for HTML 4.0 and below?
     * @param string             Generated HTML tag
     */
    public function tag($name, $options = null, $open = false) 
    {
        return "<$name"
             . ($options ? $this->tagOptions($options) : '')
             . ($open ? '>' : ' />');
    }

    /**
     * Returns an HTML block tag of type $name surrounding the $content. Add
     * HTML attributes by passing an attributes hash to $options. For attributes
     * with no value (like disabled and readonly), give it a value of TRUE in
     * the $options array.
     *
     *   $this->contentTag("p", "Hello world!")
     *     # => <p>Hello world!</p>
     *   $this->contentTag("div", $this->contentTag("p", "Hello world!"), array("class" => "strong"))
     *     # => <div class="strong"><p>Hello world!</p></div>
     *   $this->contentTag("select", $options, array("multiple" => true))
     *     # => <select multiple="multiple">...options...</select>
     *
     * @param  string  $name      Tag name
     * @param  string  $content   Content to place between the tags
     * @param  array   $options   Tag attributes
     * @return string             Genereated HTML tags with content between  
     */
    public function contentTag($name, $content, $options = null)
    {
        $tagOptions = ($options ? $this->tagOptions($options) : '');
        return "<$name$tagOptions>$content</$name>";
    }
    
    /**
     * Returns a CDATA section with the given $content.  CDATA sections
     * are used to escape blocks of text containing characters which would
     * otherwise be recognized as markup. CDATA sections begin with the string
     * <tt><![CDATA[</tt> and end with (and may not contain) the string <tt>]]></tt>.
     *
     *   $this->cdataSection("<hello world>")
     *     # => <![CDATA[<hello world>]]>    
     *
     * @param   string $content  Content for inside CDATA section
     * @return  string           CDATA section with content
     */
    public function cdataSection($content)
    {
        return "<![CDATA[$content]]>";
    }

    /**
     * Returns the escaped $html without affecting existing escaped entities.
     *
     *   $this->escapeOnce("1 > 2 &amp; 3")
     *     # => "1 &lt; 2 &amp; 3"
     *
     * @param  string  $html    HTML to be escaped
     * @return string           Escaped HTML without affecting existing escaped entities
     */
    public function escapeOnce($html)
    {
        return $this->fixDoubleEscape(htmlspecialchars($html));
    }

    /**
     * Converts an associative array of $options into
     * a string of HTML attributes
     *
     * @param  array  $options  key/value pairs
     * @param  string           key1="value1" key2="value2" 
     */
    public function tagOptions($options)
    {
        foreach ($options as $k => &$v) {
            if ($v === null || $v === false) {
                unset($options[$k]);
            } else {
                if (in_array($k, $this->_booleanAttributes)) {
                    $v = $k;
                }
            }
        }

        if (! empty($options)) {
            foreach ($options as $k => &$v) {
                $v = $k . '="' . $this->escapeOnce($v) . '"';
            }
            sort($options);
            return ' ' . implode(' ', $options);
        } else {
            return '';
        }
    }

    /**
     * Fix double-escaped entities, such as &amp;amp;, &amp;#123;, etc.
     *
     * @param  string  $escaped  Double-escaped entities
     * @return string            Entities fixed
     */
    private function fixDoubleEscape($escaped)
    {
        return preg_replace('/&amp;([a-z]+|(#\d+));/i', '&\\1;', $escaped);
    }
}
