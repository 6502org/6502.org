<?php
/**
 * Copyright 2007 Maintainable Software, LLC
 * Copyright 2008 The Horde Project (http://www.horde.org/)
 *
 * @author     Mike Naberezny <mike@maintainable.com>
 * @author     Derek DeVries <derek@maintainable.com>
 * @author     Chuck Hagenbuch <chuck@horde.org>
 * @license    http://opensource.org/licenses/bsd-license.php
 * @category   Horde
 * @package    Horde_Db
 * @subpackage Adapter
 */

/**
 * @author     Mike Naberezny <mike@maintainable.com>
 * @author     Derek DeVries <derek@maintainable.com>
 * @author     Chuck Hagenbuch <chuck@horde.org>
 * @license    http://opensource.org/licenses/bsd-license.php
 * @category   Horde
 * @package    Horde_Db
 * @subpackage Adapter
 */
class Horde_Db_Adapter_Abstract_ColumnDefinition
{
    protected $_base      = null;
    protected $_name      = null;
    protected $_type      = null;
    protected $_limit     = null;
    protected $_precision = null;
    protected $_scale     = null;
    protected $_default   = null;
    protected $_null      = null;

    /**
     * Construct
     */
    public function __construct($base, $name, $type, $limit=null,
         $precision=null, $scale=null, $default=null, $null=null)
    {
        // protected
        $this->_base      = $base;

        // public
        $this->_name      = $name;
        $this->_type      = $type;
        $this->_limit     = $limit;
        $this->_precision = $precision;
        $this->_scale     = $scale;
        $this->_default   = $default;
        $this->_null      = $null;
    }

    /*##########################################################################
    # Public
    ##########################################################################*/

    /**
     * @return  string
     */
    public function toSql()
    {
        $sql = $this->_base->quoteColumnName($this->_name).' ';
        try {
            $sql .= $this->_base->typeToSql($this->_type,      $this->_limit,
                                            $this->_precision, $this->_scale);
        } catch (Exception $e) {
            $sql .= $this->_type;
        }
        return $this->_addColumnOptions($sql, array('null'    => $this->_null,
                                                    'default' => $this->_default));
    }

    /**
     * @return  string
     */
    public function __toString()
    {
        return $this->toSql();
    }


    /*##########################################################################
    # Accessor
    ##########################################################################*/

    /**
     * @return  string
     */
    public function getName()
    {
        return $this->_name;
    }

    /**
     * @return  string
     */
    public function getDefault()
    {
        return $this->_default;
    }

    /**
     * @return  string
     */
    public function getType()
    {
        return $this->_type;
    }

    /**
     * @return  string
     */
    public function getSqlType()
    {
        try {
            return $this->_base->typeToSql($this->_type, $this->_limit, $this->_precision, $this->_scale);
        } catch (Exception $e) {
            return $this->_type;
        }
    }

    /**
     * @return  int
     */
    public function getLimit()
    {
        return $this->_limit;
    }

    /**
     * @return  int
     */
    public function precision()
    {
        return $this->_precision;
    }

    /**
     * @return  int
     */
    public function scale()
    {
        return $this->_scale;
    }

    /**
     * @return  boolean
     */
    public function isNull()
    {
        return $this->_null;
    }

    /**
     * @param   string
     */
    public function setName($name)
    {
        $this->_name = $name;
    }

    /**
     * @param  string
     */
    public function setDefault($default)
    {
        $this->_default = $default;
    }

    /**
     * @param  string
     */
    public function setType($type)
    {
        $this->_type = $type;
    }

    /**
     * @param  int
     */
    public function setLimit($limit)
    {
        $this->_limit = $limit;
    }

    /**
     * @param  int
     */
    public function setPrecision($precision)
    {
        $this->_precision = $precision;
    }

    /**
     * @param  int
     */
    public function setScale($scale)
    {
        $this->_scale = $scale;
    }

    /**
     * @param  boolean
     */
    public function setNull($null)
    {
        $this->_null = $null;
    }


    /*##########################################################################
    # Schema Statements
    ##########################################################################*/

    /**
     * @param   string  $sql
     * @param   array   $options
     */
    protected function _addColumnOptions($sql, $options)
    {
        return $this->_base->addColumnOptions($sql,
            array_merge($options, array('column' => $this))
        );
    }

}
