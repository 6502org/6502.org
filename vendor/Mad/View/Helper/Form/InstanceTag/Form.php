<?php
/**
 * @category   Mad
 * @package    Mad_View
 * @subpackage Helper
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * @category   Mad
 * @package    Mad_View
 * @subpackage Helper
 * @copyright  (c) 2007-2008 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_View_Helper_Form_InstanceTag_Form extends Mad_View_Helper_Form_InstanceTag_Base
{
    public function toInputFieldTag($fieldType, $options = array())
    {
        if (! isset($options['size'])) {
            $options['size'] = isset($options['maxlength']) ? $options['maxlength']
                                                            : $this->_defaultFieldOptions['size'];
        }
        $options = array_merge($this->_defaultFieldOptions, $options);

        if ($fieldType == 'hidden') {
            unset($options['size']);
        }
        $options['type'] = $fieldType;

        if ($fieldType != 'file') {
            if (! isset($options['value'])) {
                $options['value'] = $this->valueBeforeTypeCast($this->object());
            }
        }
        $options = $this->addDefaultNameAndId($options);
        return $this->tag('input', $options);
    }

    public function toRadioButtonTag($tagValue, $options = array())
    {
        $options = array_merge($this->_defaultRadioOptions, $options);
        $options['type']  = 'radio';
        $options['value'] = $tagValue;
        if (isset($options['checked'])) {
            $cv = $options['checked'];
            unset($options['checked']);
            $checked = ($cv == true || $cv == 'checked');
        } else {
            $checked = $this->isRadioButtonChecked($this->value($this->object()), $tagValue);
        }
        if ($checked) {
            $options['checked'] = 'checked';
        }

        $prettyTagValue = strval($tagValue);
        $prettyTagValue = preg_replace('/\s/', '_', $prettyTagValue);
        $prettyTagValue = preg_replace('/\W/', '', $prettyTagValue);
        $prettyTagValue = strtolower($prettyTagValue);

        if (! isset($options['id'])) {
            if (isset($this->autoIndex)) {
                $options['id'] = "{$this->objectName}_{$this->autoIndex}_{$this->objectProperty}_$prettyTagValue";
            } else {
                $options['id'] = "{$this->objectName}_{$this->objectProperty}_$prettyTagValue";
            }
        }
        
        $options = $this->addDefaultNameAndId($options);
        return $this->tag('input', $options);
    }

    public function toTextAreaTag($options = array())
    {
        $options = array_merge($this->_defaultTextAreaOptions, $options);
        $options = $this->addDefaultNameAndId($options);

        if (isset($options['size'])) {
            $size = $options['size'];
            unset($options['size']);
            
            list($options['cols'], $options['rows']) = explode('x', $size);
        }

        if (isset($options['value'])) {
            $value = $options['value'];
            unset($options['value']);
        } else {
            $value = $this->valueBeforeTypeCast($this->object(), $options);
        }
        
        return $this->contentTag('textarea', htmlentities($value, ENT_QUOTES, 'utf-8'), $options);
    }

    public function toCheckBoxTag($options = array(), $checkedValue = '1', $uncheckedValue = '0')
    {
        $options['type'] = 'checkbox';
        $options['value'] = $checkedValue;
        if (isset($options['checked'])) {
            $cv = $options['checked'];
            unset($options['checked']);
            $checked = ($cv == true || $cv == 'checked');
        } else {
            $checked = $this->isCheckBoxChecked($this->value($this->object()), $checkedValue);
        }
        if ($checked) {
            $options['checked'] = 'checked';
        }
        $options = $this->addDefaultNameAndId($options);
        
        // hidden must output first in PHP to not overwrite checkbox value
        $tags = $this->tag('input', array('name'  => $options['name'], 
                                          'type'  => 'hidden', 
                                          'value' => $uncheckedValue)). 
                $this->tag('input', $options);
        return $tags;
    }

    protected function isCheckBoxChecked($value, $checkedValue)
    {
        switch(gettype($value)) {
            case 'boolean':
                return $value;
            case 'NULL':
                return false;
            case 'integer':
                return $value != 0;
            case 'string':
                return $value == $checkedValue;
            default:
                return intval($value) != 0;
        }
    }

    protected function isRadioButtonChecked($value, $checkedValue)
    {
        return (strval($value) == strval($checkedValue));
    }

}
