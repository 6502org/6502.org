<?php
/**
 * CSS selector assertions for HTML/XML documents.
 *
 * Ported from PHPUnit 4.8 (PHPUnit_Util_XML and PHPUnit_Framework_Assert)
 * which removed these in PHPUnit 5.0. The original code was written by
 * Sebastian Bergmann and contributors under the BSD license.
 *
 * @category   Mad
 * @package    Mad_Test
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * Provides CSS selector based assertions against HTML/XML documents.
 *
 * @category   Mad
 * @package    Mad_Test
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Test_DomAssertion
{
    /**
     * Parse a CSS selector and find matching nodes in a document.
     *
     * @param  string              $selector  CSS selector
     * @param  string              $content   Content to match (true for any)
     * @param  string|DOMDocument  $actual    HTML/XML string or DOMDocument
     * @param  bool                $isHtml    Whether to parse as HTML
     * @return array|false         Matched DOMNodes, or false if none
     */
    public static function cssSelect($selector, $content, $actual, $isHtml = true)
    {
        $matcher = self::convertSelectToTag($selector, $content);
        $dom     = self::load($actual, $isHtml);
        $tags    = self::findNodes($dom, $matcher, $isHtml);

        return $tags;
    }

    /**
     * Parse a CSS selector into an associative array suitable for
     * use with findNodes().
     *
     * @param  string  $selector
     * @param  mixed   $content
     * @return array
     */
    public static function convertSelectToTag($selector, $content = true)
    {
        $selector = trim(preg_replace("/\s+/", " ", $selector));

        // substitute spaces within attribute value
        while (preg_match('/\[[^\]]+"[^"]+\s[^"]+"\]/', $selector)) {
            $selector = preg_replace(
                '/(\[[^\]]+"[^"]+)\s([^"]+"\])/',
                '$1__SPACE__$2',
                $selector
            );
        }

        if (strstr($selector, ' ')) {
            $elements = explode(' ', $selector);
        } else {
            $elements = array($selector);
        }

        $previousTag = array();

        foreach (array_reverse($elements) as $element) {
            $element = str_replace('__SPACE__', ' ', $element);

            // child selector
            if ($element == '>') {
                $previousTag = array('child' => $previousTag['descendant']);
                continue;
            }

            // adjacent-sibling selector
            if ($element == '+') {
                $previousTag = array('adjacent-sibling' => $previousTag['descendant']);
                continue;
            }

            $tag = array();

            // match element tag
            preg_match("/^([^\.#\[]*)/", $element, $eltMatches);

            if (!empty($eltMatches[1])) {
                $tag['tag'] = $eltMatches[1];
            }

            // match attributes, ids, and classes
            preg_match_all(
                "/(\[[^\]]*\]*|#[^\.#\[]*|\.[^\.#\[]*)/",
                $element,
                $matches
            );

            if (!empty($matches[1])) {
                $classes = array();
                $attrs   = array();

                foreach ($matches[1] as $match) {
                    // id matched
                    if (substr($match, 0, 1) == '#') {
                        $tag['id'] = substr($match, 1);

                    // class matched
                    } elseif (substr($match, 0, 1) == '.') {
                        $classes[] = substr($match, 1);

                    // attribute matched
                    } elseif (substr($match, 0, 1) == '[' &&
                              substr($match, -1, 1) == ']') {
                        $attribute = substr($match, 1, strlen($match) - 2);
                        $attribute = str_replace('"', '', $attribute);

                        // match single word
                        if (strstr($attribute, '~=')) {
                            list($key, $value) = explode('~=', $attribute);
                            $value             = "regexp:/.*\b$value\b.*/";

                        // match substring
                        } elseif (strstr($attribute, '*=')) {
                            list($key, $value) = explode('*=', $attribute);
                            $value             = "regexp:/.*$value.*/";

                        // exact match
                        } else {
                            list($key, $value) = explode('=', $attribute);
                        }

                        $attrs[$key] = $value;
                    }
                }

                if (!empty($classes)) {
                    $tag['class'] = implode(' ', $classes);
                }

                if (!empty($attrs)) {
                    $tag['attributes'] = $attrs;
                }
            }

            // tag content
            if (is_string($content)) {
                $tag['content'] = $content;
            }

            // determine previous child/descendants
            if (!empty($previousTag['descendant'])) {
                $tag['descendant'] = $previousTag['descendant'];
            } elseif (!empty($previousTag['child'])) {
                $tag['child'] = $previousTag['child'];
            } elseif (!empty($previousTag['adjacent-sibling'])) {
                $tag['adjacent-sibling'] = $previousTag['adjacent-sibling'];
                unset($tag['content']);
            }

            $previousTag = array('descendant' => $tag);
        }

        return $tag;
    }

    /**
     * Load a document into a DOMDocument.
     *
     * @param  string|DOMDocument  $actual
     * @param  bool                $isHtml
     * @return DOMDocument
     */
    public static function load($actual, $isHtml = false)
    {
        if ($actual instanceof DOMDocument) {
            return $actual;
        }

        if (!is_string($actual)) {
            throw new Mad_Test_Exception(
                'Could not load XML from ' . gettype($actual)
            );
        }

        if ($actual === '') {
            throw new Mad_Test_Exception(
                'Could not load XML from empty string'
            );
        }

        $document = new DOMDocument;
        $document->preserveWhiteSpace = false;

        $internal  = libxml_use_internal_errors(true);
        $reporting = error_reporting(0);

        if ($isHtml) {
            $loaded = $document->loadHTML($actual);
        } else {
            $loaded = $document->loadXML($actual);
        }

        libxml_clear_errors();
        libxml_use_internal_errors($internal);
        error_reporting($reporting);

        if ($loaded === false) {
            throw new Mad_Test_Exception(
                'Could not load XML/HTML document'
            );
        }

        return $document;
    }

    /**
     * Find DOMNodes matching the given options in a DOMDocument.
     *
     * @param  DOMDocument  $dom
     * @param  array        $options
     * @param  bool         $isHtml
     * @return array|false
     */
    public static function findNodes(DOMDocument $dom, array $options, $isHtml = true)
    {
        $valid = array(
            'id', 'class', 'tag', 'content', 'attributes', 'parent',
            'child', 'ancestor', 'descendant', 'children', 'adjacent-sibling'
        );

        $filtered = array();
        $options  = self::_assertValidKeys($options, $valid);

        // find the element by id
        if ($options['id']) {
            $options['attributes']['id'] = $options['id'];
        }

        if ($options['class']) {
            $options['attributes']['class'] = $options['class'];
        }

        $nodes = array();

        // find the element by a tag type
        if ($options['tag']) {
            if ($isHtml) {
                $elements = self::_getElementsByCaseInsensitiveTagName(
                    $dom, $options['tag']
                );
            } else {
                $elements = $dom->getElementsByTagName($options['tag']);
            }

            foreach ($elements as $element) {
                $nodes[] = $element;
            }

            if (empty($nodes)) {
                return false;
            }

        // no tag selected, get them all
        } else {
            $tags = array(
                'a', 'abbr', 'acronym', 'address', 'area', 'b', 'base', 'bdo',
                'big', 'blockquote', 'body', 'br', 'button', 'caption', 'cite',
                'code', 'col', 'colgroup', 'dd', 'del', 'div', 'dfn', 'dl',
                'dt', 'em', 'fieldset', 'form', 'frame', 'frameset', 'h1', 'h2',
                'h3', 'h4', 'h5', 'h6', 'head', 'hr', 'html', 'i', 'iframe',
                'img', 'input', 'ins', 'kbd', 'label', 'legend', 'li', 'link',
                'map', 'meta', 'noframes', 'noscript', 'object', 'ol', 'optgroup',
                'option', 'p', 'param', 'pre', 'q', 'samp', 'script', 'select',
                'small', 'span', 'strong', 'style', 'sub', 'sup', 'table',
                'tbody', 'td', 'textarea', 'tfoot', 'th', 'thead', 'title',
                'tr', 'tt', 'ul', 'var',
                // HTML5
                'article', 'aside', 'audio', 'bdi', 'canvas', 'command',
                'datalist', 'details', 'dialog', 'embed', 'figure', 'figcaption',
                'footer', 'header', 'hgroup', 'keygen', 'mark', 'meter', 'nav',
                'output', 'progress', 'ruby', 'rt', 'rp', 'track', 'section',
                'source', 'summary', 'time', 'video', 'wbr'
            );

            foreach ($tags as $tag) {
                if ($isHtml) {
                    $elements = self::_getElementsByCaseInsensitiveTagName(
                        $dom, $tag
                    );
                } else {
                    $elements = $dom->getElementsByTagName($tag);
                }

                foreach ($elements as $element) {
                    $nodes[] = $element;
                }
            }

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by attributes
        if ($options['attributes']) {
            foreach ($nodes as $node) {
                $invalid = false;

                foreach ($options['attributes'] as $name => $value) {
                    // match by regexp if like "regexp:/foo/i"
                    if (preg_match('/^regexp\s*:\s*(.*)/i', $value, $matches)) {
                        if (!preg_match($matches[1], $node->getAttribute($name))) {
                            $invalid = true;
                        }

                    // class can match only a part
                    } elseif ($name == 'class') {
                        $findClasses = explode(
                            ' ', preg_replace("/\s+/", ' ', $value)
                        );
                        $allClasses = explode(
                            ' ', preg_replace("/\s+/", ' ', $node->getAttribute($name))
                        );

                        foreach ($findClasses as $findClass) {
                            if (!in_array($findClass, $allClasses)) {
                                $invalid = true;
                            }
                        }

                    // match by exact string
                    } else {
                        if ($node->getAttribute($name) != $value) {
                            $invalid = true;
                        }
                    }
                }

                if (!$invalid) {
                    $filtered[] = $node;
                }
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by content
        if ($options['content'] !== null) {
            foreach ($nodes as $node) {
                $invalid = false;

                // match by regexp if like "regexp:/foo/i"
                if (preg_match('/^regexp\s*:\s*(.*)/i', $options['content'], $matches)) {
                    if (!preg_match($matches[1], self::_getNodeText($node))) {
                        $invalid = true;
                    }

                // match empty string
                } elseif ($options['content'] === '') {
                    if (self::_getNodeText($node) !== '') {
                        $invalid = true;
                    }

                // match by exact string
                } elseif (strstr(self::_getNodeText($node), $options['content']) === false) {
                    $invalid = true;
                }

                if (!$invalid) {
                    $filtered[] = $node;
                }
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by parent node
        if ($options['parent']) {
            $parentNodes = self::findNodes($dom, $options['parent'], $isHtml);
            $parentNode  = isset($parentNodes[0]) ? $parentNodes[0] : null;

            foreach ($nodes as $node) {
                if ($parentNode !== $node->parentNode) {
                    continue;
                }
                $filtered[] = $node;
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by child node
        if ($options['child']) {
            $childNodes = self::findNodes($dom, $options['child'], $isHtml);
            $childNodes = !empty($childNodes) ? $childNodes : array();

            foreach ($nodes as $node) {
                foreach ($node->childNodes as $child) {
                    foreach ($childNodes as $childNode) {
                        if ($childNode === $child) {
                            $filtered[] = $node;
                        }
                    }
                }
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by adjacent-sibling
        if ($options['adjacent-sibling']) {
            $adjacentSiblingNodes = self::findNodes(
                $dom, $options['adjacent-sibling'], $isHtml
            );
            $adjacentSiblingNodes = !empty($adjacentSiblingNodes)
                ? $adjacentSiblingNodes : array();

            foreach ($nodes as $node) {
                $sibling = $node;

                while ($sibling = $sibling->nextSibling) {
                    if ($sibling->nodeType !== XML_ELEMENT_NODE) {
                        continue;
                    }

                    foreach ($adjacentSiblingNodes as $adjacentSiblingNode) {
                        if ($sibling === $adjacentSiblingNode) {
                            $filtered[] = $node;
                            break;
                        }
                    }

                    break;
                }
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by ancestor
        if ($options['ancestor']) {
            $ancestorNodes = self::findNodes($dom, $options['ancestor'], $isHtml);
            $ancestorNode  = isset($ancestorNodes[0]) ? $ancestorNodes[0] : null;

            foreach ($nodes as $node) {
                $parent = $node->parentNode;

                while ($parent && $parent->nodeType != XML_HTML_DOCUMENT_NODE) {
                    if ($parent === $ancestorNode) {
                        $filtered[] = $node;
                    }
                    $parent = $parent->parentNode;
                }
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by descendant
        if ($options['descendant']) {
            $descendantNodes = self::findNodes(
                $dom, $options['descendant'], $isHtml
            );
            $descendantNodes = !empty($descendantNodes)
                ? $descendantNodes : array();

            foreach ($nodes as $node) {
                foreach (self::_getDescendants($node) as $descendant) {
                    foreach ($descendantNodes as $descendantNode) {
                        if ($descendantNode === $descendant) {
                            $filtered[] = $node;
                        }
                    }
                }
            }

            $nodes    = $filtered;
            $filtered = array();

            if (empty($nodes)) {
                return false;
            }
        }

        // filter by children
        if ($options['children']) {
            $validChild   = array('count', 'greater_than', 'less_than', 'only');
            $childOptions = self::_assertValidKeys(
                $options['children'], $validChild
            );

            foreach ($nodes as $node) {
                $children  = array();
                $childNodes = $node->childNodes;

                foreach ($childNodes as $childNode) {
                    if ($childNode->nodeType !== XML_CDATA_SECTION_NODE &&
                        $childNode->nodeType !== XML_TEXT_NODE) {
                        $children[] = $childNode;
                    }
                }

                // we must have children to pass this filter
                if (!empty($children)) {
                    // exact count of children
                    if ($childOptions['count'] !== null) {
                        if (count($children) !== $childOptions['count']) {
                            break;
                        }

                    // range count of children
                    } elseif ($childOptions['less_than']    !== null &&
                              $childOptions['greater_than'] !== null) {
                        if (count($children) >= $childOptions['less_than'] ||
                            count($children) <= $childOptions['greater_than']) {
                            break;
                        }

                    // less than a given count
                    } elseif ($childOptions['less_than'] !== null) {
                        if (count($children) >= $childOptions['less_than']) {
                            break;
                        }

                    // more than a given count
                    } elseif ($childOptions['greater_than'] !== null) {
                        if (count($children) <= $childOptions['greater_than']) {
                            break;
                        }
                    }

                    // match each child against a specific tag
                    if ($childOptions['only']) {
                        $onlyNodes = self::findNodes(
                            $dom, $childOptions['only'], $isHtml
                        );

                        foreach ($children as $child) {
                            $matched = false;
                            foreach ($onlyNodes as $onlyNode) {
                                if ($onlyNode === $child) {
                                    $matched = true;
                                }
                            }
                            if (!$matched) {
                                break 2;
                            }
                        }
                    }

                    $filtered[] = $node;
                }
            }

            $nodes = $filtered;

            if (empty($nodes)) {
                return false;
            }
        }

        return !empty($nodes) ? $nodes : array();
    }


    /*##########################################################################
    # Private
    ##########################################################################*/

    /**
     * Validate and set defaults for associative array keys.
     *
     * @param  array  $hash
     * @param  array  $validKeys
     * @return array
     */
    private static function _assertValidKeys(array $hash, array $validKeys)
    {
        $valids = array();

        foreach ($validKeys as $key => $val) {
            is_int($key) ? $valids[$val] = null : $valids[$key] = $val;
        }

        $validKeys = array_keys($valids);

        foreach ($hash as $key => $value) {
            if (!in_array($key, $validKeys)) {
                $unknown[] = $key;
            }
        }

        if (!empty($unknown)) {
            throw new Mad_Test_Exception(
                'Unknown key(s): ' . implode(', ', $unknown)
            );
        }

        foreach ($valids as $key => $value) {
            if (!isset($hash[$key])) {
                $hash[$key] = $value;
            }
        }

        return $hash;
    }

    /**
     * Get elements by case-insensitive tag name.
     *
     * @param  DOMDocument  $dom
     * @param  string       $tag
     * @return DOMNodeList
     */
    private static function _getElementsByCaseInsensitiveTagName(DOMDocument $dom, $tag)
    {
        $elements = $dom->getElementsByTagName(strtolower($tag));

        if ($elements->length == 0) {
            $elements = $dom->getElementsByTagName(strtoupper($tag));
        }

        return $elements;
    }

    /**
     * Recursively get the text content of a node.
     *
     * @param  DOMNode  $node
     * @return string
     */
    private static function _getNodeText(DOMNode $node)
    {
        if (!$node->childNodes instanceof DOMNodeList) {
            return '';
        }

        $result = '';

        foreach ($node->childNodes as $childNode) {
            if ($childNode->nodeType === XML_TEXT_NODE ||
                $childNode->nodeType === XML_CDATA_SECTION_NODE) {
                $result .= trim($childNode->data) . ' ';
            } else {
                $result .= self::_getNodeText($childNode);
            }
        }

        return str_replace('  ', ' ', $result);
    }

    /**
     * Recursively get all descendant elements of a node.
     *
     * @param  DOMNode  $node
     * @return array
     */
    private static function _getDescendants(DOMNode $node)
    {
        $allChildren = array();
        $childNodes  = $node->childNodes ? $node->childNodes : array();

        foreach ($childNodes as $child) {
            if ($child->nodeType === XML_CDATA_SECTION_NODE ||
                $child->nodeType === XML_TEXT_NODE) {
                continue;
            }

            $children    = self::_getDescendants($child);
            $allChildren = array_merge($allChildren, $children, array($child));
        }

        return $allChildren;
    }
}
