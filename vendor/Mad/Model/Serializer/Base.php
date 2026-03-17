<?php
/**
 * @category   Mad
 * @package    Mad_Model
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * The base object from which all DataObjects are extended from
 *
 * @category   Mad
 * @package    Mad_Model
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Model_Serializer_Base
{
    protected $_record = null;

    protected $_options = [];

    protected $_serializableRecord = [];

    public function __construct($record, $options = []) 
    {
        $this->_record  = $record;
        $this->_options = $options;
    }


    public function __toString()
    {
        return $this->serialize();
    }
    
    /**
     * To replicate the behavior in ActiveRecord#attributes,
     * <tt>:except</tt> takes precedence over <tt>:only</tt>.  If <tt>:only</tt> is not set
     * for a N level model but is set for the N+1 level models,
     * then because <tt>:except</tt> is set to a default value, the second
     * level model can have both <tt>:except</tt> and <tt>:only</tt> set.  So if
     * <tt>:only</tt> is set, always delete <tt>:except</tt>.
    */
    public function getSerializableAttributeNames()
    {
        $attributeNames = $this->_record->attributeNames();

        // only
        if (!empty($this->_options['only'])) {
            $this->_options['except'] = null;
            $attributeNames = array_intersect($attributeNames, (array)$this->_options['only']);

        // except
        } else {
            $this->_options['only'] = null;
            $except = isset($this->_options['except']) ? (array)$this->_options['except'] : [];
            $except = array_merge($except, (array)$this->_record->inheritanceColumn());
            $this->_options['except'] = array_unique($except);
            $attributeNames = array_diff($attributeNames, $this->_options['except']);
        }
        sort($attributeNames);
        return $attributeNames;
    }

    public function getSerializableMethodNames()
    {
        $methodAttributes = [];

        $methods = isset($this->_options['methods']) ? (array)$this->_options['methods'] : [];
        foreach ($methods as $method) {
            if (method_exists($this->_record, $method)) {
                $methodAttributes[] = $method; 
            }
        }
        sort($methodAttributes);
        return $methodAttributes;
    }

    public function getSerializablePropertyNames()
    {
        $propertyAttributes = [];

        $properties = isset($this->_options['properties']) ? (array)$this->_options['properties'] : [];
        foreach ($properties as $property) {
            $propertyAttributes[] = $property; 
        }
        sort($propertyAttributes);
        return $propertyAttributes;
    }

    public function getSerializableNames()
    {
        $names = array_merge($this->getSerializableAttributeNames(), 
                             $this->getSerializablePropertyNames(),
                             $this->getSerializableMethodNames());
        sort($names);
        return $names;
    }

    /**
     * Add associations specified via the <tt>:includes</tt> option.
     * Expects a block that takes as arguments:
     *   +association+ - name of the association
     *   +records+     - the association record(s) to be serialized
     *   +opts+        - options for the association records
     */
    public function addIncludes()
    {
        if (isset($this->_options['include'])) {
            $includeAssociations = (array)$this->_options['include'];
            unset($this->_options['include']);
        }
        if (empty($includeAssociations)) { return; }

        $baseOnlyOrExcept = ['except' => $this->_options['except'], 
                                  'only'   => $this->_options['only']];

        // associative array includes have additional options
        $includeHasOptions = !is_int(key($includeAssociations));
        $associations = $includeHasOptions ? array_keys($includeAssociations) : $includeAssociations;

        // find records for each association
        foreach ($associations as $association) {
            $assoc = $this->_record->reflectOnAssociation($association);
            $type = $assoc->getMacro();

            $method = Mad_Support_Inflector::camelize($association, 'lower');

            if ($type == 'hasMany' || $type == 'hasAndBelongsToMany') {
                $records = $this->_record->{$method}()->getCollection();

            } elseif ($type == 'hasOne' || $type == 'belongsTo') {
                $records = $this->_record->{$method}();
            }            

            if ($records === null) { continue; }

            // options
            if ($includeHasOptions) {
                $associationOptions = $includeAssociations[$association];
            } else {
                $associationOptions = $baseOnlyOrExcept;
            }

            // sub-records
            $opts = array_merge($this->_options, $associationOptions);

            $this->yieldRecords($association, $records, $opts);
        }

        $this->_options['include'] = $includeAssociations;
    }
    
    /** 
     * Use the record to build associations
     */
    public function yieldRecords($association, $records, $opts)
    {
        // multiple record association
        if (is_array($records)) {
            $serialized = [];
            foreach ($records as $record) {
                $serializer = new self($record, $opts);
                $serialized[] = $serializer->getSerializableRecord();
            }
            $this->_serializableRecord[$association] = $serialized;
                
        // single record association
        } else {
            $serializer = new self($records, $opts);
            $this->_serializableRecord[$association] = $serializer->getSerializableRecord();
        }
    }

    public function getSerializableRecord()
    {
        $this->_serializableRecord = [];
        
        foreach ($this->getSerializableAttributeNames() as $name) {
            $this->_serializableRecord[$name] = $this->_record->$name;
        }
        foreach ($this->getSerializablePropertyNames() as $name) {
            $this->_serializableRecord[$name] = $this->_record->{$name};
        }
        foreach ($this->getSerializableMethodNames() as $name) {
            $this->_serializableRecord[$name] = $this->_record->{$name}();
        }
        $this->addIncludes();

        return $this->_serializableRecord;
    }

    // overwrite to implement
    public function serialize()
    {
        return '';
    }
}
