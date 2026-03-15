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
class Horde_Db_Adapter_Sqlite_Schema extends Horde_Db_Adapter_Abstract_Schema
{
    /*##########################################################################
    # Quoting
    ##########################################################################*/

    public function quoteTrue()
    {
        return '1';
    }

    public function quoteFalse()
    {
        return '0';
    }

    /**
     * @return  string
     */
    public function quoteColumnName($name)
    {
        return '"' . str_replace('"', '""', $name) . '"';
    }


    /*##########################################################################
    # Schema Statements
    ##########################################################################*/

    /**
     * The db column types for this adapter
     *
     * @return  array
     */
    public function nativeDatabaseTypes()
    {
        return array(
            'primaryKey' => $this->_defaultPrimaryKeyType(),
            'string'     => array('name' => 'varchar',  'limit' => 255),
            'text'       => array('name' => 'text',     'limit' => null),
            'integer'    => array('name' => 'int',      'limit' => null),
            'float'      => array('name' => 'float',    'limit' => null),
            'decimal'    => array('name' => 'decimal',  'limit' => null),
            'datetime'   => array('name' => 'datetime', 'limit' => null),
            'timestamp'  => array('name' => 'datetime', 'limit' => null),
            'time'       => array('name' => 'time',     'limit' => null),
            'date'       => array('name' => 'date',     'limit' => null),
            'binary'     => array('name' => 'blob',     'limit' => null),
            'boolean'    => array('name' => 'boolean',  'limit' => null),
        );
    }

    /**
     * Dump entire schema structure or specific table
     *
     * @param   string  $table
     * @return  string
     */
    public function structureDump($table=null)
    {
        if ($table) {
            return $this->selectValue('SELECT sql FROM (
                SELECT * FROM sqlite_master UNION ALL
                SELECT * FROM sqlite_temp_master) WHERE type != \'meta\' AND name = ' . $this->quote($table));
        } else {
            $dump = $this->selectValues('SELECT sql FROM (
                SELECT * FROM sqlite_master UNION ALL
                SELECT * FROM sqlite_temp_master) WHERE type != \'meta\' AND name != \'sqlite_sequence\'');
            return implode("\n\n", $dump);
        }
    }

    /**
     * Create the given db
     *
     * @param   string  $name
     */
    public function createDatabase($name)
    {
        return new PDO('sqlite:' . $name);
    }

    /**
     * Drop the given db
     *
     * @param   string  $name
     */
    public function dropDatabase($name)
    {
        if (! @file_exists($name)) {
            throw new Horde_Db_Exception('database does not exist');
        }

        if (! @unlink($name)) {
            throw new Horde_Db_Exception('could not remove the database file');
        }
    }

    /**
     * Get the name of the current db
     *
     * @return  string
     */
    public function currentDatabase()
    {
        return $this->_config['dbname'];
    }

    /**
     * List of tables for the db
     *
     * @param   string  $name
     */
    public function tables($name=null)
    {
        return $this->selectValues("SELECT name FROM sqlite_master WHERE type = 'table' UNION ALL SELECT name FROM sqlite_temp_master WHERE type = 'table' AND name != 'sqlite_sequence' ORDER BY name");
    }

    /**
     * List of indexes for the given table
     *
     * @param   string  $tableName
     * @param   string  $name
     */
    public function indexes($tableName, $name=null)
    {
        $indexes = array();
        foreach ($this->select('PRAGMA index_list(' . $this->quoteTableName($tableName) . ')') as $row) {
            $index = (object)array('table'   => $tableName,
                                   'name'    => $row[1],
                                   'unique'  => (bool)$row[2],
                                   'columns' => array());
            foreach ($this->select('PRAGMA index_info(' . $this->quoteColumnName($index->name) . ')') as $field) {
                $index->columns[] = $field[2];
            }

            $indexes[] = $index;
        }
        return $indexes;
    }

    /**
     * @param   string  $tableName
     * @param   string  $name
     */
    public function columns($tableName, $name=null)
    {
        // check cache
        $cached = $this->_cache->get("tables/$tableName");
        $rows = ($cached !== null) ? @unserialize($cached) : false;

        // query to build rows
        if (!$rows) {
            $rows = $this->selectAll('PRAGMA table_info(' . $this->quoteTableName($tableName) . ')', $name);

            // write cache
            $this->_cache->set("tables/$tableName", serialize($rows));
        }

        // create columns from rows
        $columns = array();
        foreach ($rows as $row) {
            $columns[] = new Horde_Db_Adapter_Sqlite_Column(
                $row[1], $row[4], $row[2], !(bool)$row[3]);
        }
        return $columns;
    }

    /**
     * Override createTable to return a Sqlite Table Definition
     * param    string  $name
     * param    array   $options
     */
    public function createTable($name, $options=array())
    {
        $pk = isset($options['primaryKey']) && $options['primaryKey'] === false ? false : 'id';
        $tableDefinition =
            new Horde_Db_Adapter_Abstract_TableDefinition($name, $this, $options);
        if ($pk != false) {
            $tableDefinition->primaryKey($pk);
        }
        return $tableDefinition;
    }

    /**
     * @param   string  $name
     * @param   string  $newName
     */
    public function renameTable($name, $newName)
    {
        $this->_clearTableCache($name);

        return $this->execute('ALTER TABLE ' . $this->quoteTableName($name) . ' RENAME TO ' . $this->quoteTableName($newName));
    }

    /**
     * Adds a new column to the named table.
     * See TableDefinition#column for details of the options you can use.
     *
     * @param   string  $tableName
     * @param   string  $columnName
     * @param   string  $type
     * @param   array   $options
     */
    public function addColumn($tableName, $columnName, $type, $options=array())
    {
        if ($this->transactionStarted()) {
            throw new Horde_Db_Exception('Cannot add columns to a SQLite database while inside a transaction');
        }

        parent::addColumn($tableName, $columnName, $type, $options);

        // See last paragraph on http://www.sqlite.org/lang_altertable.html
        $this->execute('VACUUM');
    }

    /**
     * Removes the column from the table definition.
     * ===== Examples
     *  remove_column(:suppliers, :qualification)
     *
     * @param   string  $tableName
     * @param   string  $columnName
     */
    public function removeColumn($tableName, $columnName)
    {
        // Check if column exists before doing expensive copy-table cycle
        $exists = false;
        foreach ($this->columns($tableName) as $col) {
            if ($col->getName() == $columnName) { $exists = true; break; }
        }
        if (!$exists) { return; }

        $this->_clearTableCache($tableName);
        $this->_alterTable($tableName, array(), function($definition) use ($columnName) {
            unset($definition[$columnName]);
        });
    }

    /**
     * @param   string  $tableName
     * @param   string  $columnName
     * @param   string  $type
     * @param   array   $options
     */
    public function changeColumn($tableName, $columnName, $type, $options=array())
    {
        $this->_clearTableCache($tableName);
        $this->_alterTable($tableName, array(), function($definition) use ($columnName, $type, $options) {
            $col = $definition[$columnName];
            $col->setType($type);
            if (isset($options['limit']))              { $col->setLimit($options['limit']); }
            if (array_key_exists('default', $options)) { $col->setDefault($options['default']); }
            if (isset($options['null']))               { $col->setNull($options['null']); }
        });
    }

    /**
     * @param   string  $tableName
     * @param   string  $columnName
     * @param   string  $default
     */
    public function changeColumnDefault($tableName, $columnName, $default)
    {
        $this->_clearTableCache($tableName);
        $this->_alterTable($tableName, array(), function($definition) use ($columnName, $default) {
            $definition[$columnName]->setDefault($default);
        });
    }

    /**
     * @param   string  $tableName
     * @param   string  $columnName
     * @param   string  $newColumnName
     */
    public function renameColumn($tableName, $columnName, $newColumnName)
    {
        $this->_clearTableCache($tableName);
        $this->_alterTable($tableName, array('rename' => array($columnName => $newColumnName)));
    }

    /**
     * Remove the given index from the table.
     *
     * Remove the suppliers_name_index in the suppliers table (legacy support, use the second or third forms).
     *   remove_index :suppliers, :name
     * Remove the index named accounts_branch_id in the accounts table.
     *   remove_index :accounts, :column => :branch_id
     * Remove the index named by_branch_party in the accounts table.
     *   remove_index :accounts, :name => :by_branch_party
     *
     * You can remove an index on multiple columns by specifying the first column.
     *   add_index :accounts, [:username, :password]
     *   remove_index :accounts, :username
     *
     * @param   string  $tableName
     * @param   array   $options
     */
    public function removeIndex($tableName, $options=array())
    {
        $this->_clearTableCache($tableName);

        $index = $this->indexName($tableName, $options);
        $sql = 'DROP INDEX '.$this->quoteColumnName($index);
        return $this->execute($sql);
    }


    /*##########################################################################
    # Protected
    ##########################################################################*/

    protected function _defaultPrimaryKeyType()
    {
        if ($this->supportsAutoIncrement())
            return 'INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL';
        else
            return 'INTEGER PRIMARY KEY NOT NULL';
    }

    /**
     * Alter a table by copying it to a temporary table, modifying the
     * definition, then copying it back. This is the only way to perform
     * most ALTER TABLE operations on SQLite.
     *
     * @param string   $tableName
     * @param array    $options    Options: 'rename' => array(old => new)
     * @param callable $callback   Receives the table definition for modification
     */
    protected function _alterTable($tableName, $options = array(), $callback = null)
    {
        $alteredTableName = "altered_{$tableName}";

        // First copy applies the rename (if any) and creates a temp table
        $this->_moveTable($tableName, $alteredTableName,
            array_merge($options, array('temporary' => true)));

        // Second copy moves back from the temp table. Don't pass rename
        // options since the columns were already renamed in the first copy.
        $optionsWithoutRename = $options;
        unset($optionsWithoutRename['rename']);
        $this->_moveTable($alteredTableName, $tableName, $optionsWithoutRename, $callback);
    }

    protected function _moveTable($from, $to, $options = array(), $callback = null)
    {
        $this->_copyTable($from, $to, $options, $callback);
        $this->dropTable($from);
    }

    protected function _copyTable($from, $to, $options = array(), $callback = null)
    {
        $fromColumns = $this->columns($from);
        $hasId = false;
        foreach ($fromColumns as $col) {
            if ($col->getName() == 'id') { $hasId = true; break; }
        }

        $createOptions = array_merge($options, array('id' => $hasId));
        if ($hasId) {
            $createOptions['primaryKey'] = 'id';
        } else {
            $createOptions['primaryKey'] = false;
        }

        $definition = $this->createTable($to, $createOptions);

        $rename = isset($options['rename']) ? $options['rename'] : array();

        foreach ($fromColumns as $column) {
            $columnName = $column->getName();
            if ($columnName == 'id') { continue; }

            $newName = isset($rename[$columnName]) ? $rename[$columnName] : $columnName;

            $colOptions = array();
            if ($column->getLimit())   { $colOptions['limit'] = $column->getLimit(); }
            if ($column->getDefault() !== null) { $colOptions['default'] = $column->getDefault(); }
            if (!$column->isNull())    { $colOptions['null'] = false; }

            $definition->column($newName, $column->getType(), $colOptions);
        }

        if ($callback) {
            $callback($definition);
        }

        $definition->end();

        $this->_copyTableIndexes($from, $to, $rename);
        $this->_copyTableContents($from, $to, $definition, $rename);
    }

    protected function _copyTableIndexes($from, $to, $rename = array())
    {
        $toColumnNames = array();
        foreach ($this->columns($to) as $col) {
            $toColumnNames[] = $col->getName();
        }

        foreach ($this->indexes($from) as $index) {
            $name = $index->name;
            if ($to == "altered_{$from}") {
                $name = "temp_{$name}";
            } elseif ($from == "altered_{$to}") {
                $name = substr($name, 5);
            }

            $columns = array();
            foreach ($index->columns as $col) {
                $newCol = isset($rename[$col]) ? $rename[$col] : $col;
                if (in_array($newCol, $toColumnNames)) {
                    $columns[] = $newCol;
                }
            }

            if (!empty($columns)) {
                $opts = array('name' => str_replace("_{$from}_", "_{$to}_", $name));
                if ($index->unique) { $opts['unique'] = true; }
                $this->addIndex($to, $columns, $opts);
            }
        }
    }

    protected function _copyTableContents($from, $to, $definition, $rename = array())
    {
        $columnNames = array();
        foreach ($definition->getColumns() as $col) {
            $columnNames[] = $col->getName();
        }

        // Build column mapping (new name => old name)
        $columnMappings = array();
        foreach ($columnNames as $name) {
            $columnMappings[$name] = $name;
        }
        foreach ($rename as $oldName => $newName) {
            $columnMappings[$newName] = $oldName;
        }

        // Filter to columns that exist in the source table
        $fromColumnNames = array();
        foreach ($this->columns($from) as $col) {
            $fromColumnNames[] = $col->getName();
        }

        $validColumns = array();
        foreach ($columnNames as $name) {
            if (in_array($columnMappings[$name], $fromColumnNames)) {
                $validColumns[] = $name;
            }
        }

        $fromCols = array();
        $toCols = array();
        foreach ($validColumns as $name) {
            $toCols[] = $this->quoteColumnName($name);
            $fromCols[] = $this->quoteColumnName($columnMappings[$name]);
        }

        $sql = sprintf('INSERT INTO %s (%s) SELECT %s FROM %s',
            $this->quoteTableName($to),
            implode(', ', $toCols),
            implode(', ', $fromCols),
            $this->quoteTableName($from)
        );

        $this->execute($sql);
    }

}
