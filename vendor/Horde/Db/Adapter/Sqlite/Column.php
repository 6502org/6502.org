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
class Horde_Db_Adapter_Sqlite_Column extends Horde_Db_Adapter_Abstract_Column
{
    /**
     * @var array
     */
    protected static $_hasEmptyStringDefault = ['binary', 'string', 'text'];


    /*##########################################################################
    # Default Value Handling
    ##########################################################################*/

    /**
     * SQLite PRAGMA table_info returns default values in SQL-quoted form
     * (e.g., '' for empty string, 'hello' for the string hello, NULL for null).
     * Strip the surrounding quotes before type-casting.
     */
    public function extractDefault($default)
    {
        if ($default === null || $default === 'NULL') {
            return null;
        }

        // Strip surrounding single quotes (SQL literal format)
        if (strlen($default) >= 2 && $default[0] === "'" && $default[strlen($default) - 1] === "'") {
            $default = substr($default, 1, -1);
            // Unescape doubled single quotes
            $default = str_replace("''", "'", $default);
        }

        return parent::extractDefault($default);
    }


    /*##########################################################################
    # Type Juggling
    ##########################################################################*/

    public function stringToBinary($value)
    {
        return str_replace(["\0", '%'], ['%00', '%25'], $value);
    }

    public function binaryToString($value)
    {
        return str_replace(['%00', '%25'], ["\0", '%'], $value);
    }

}
