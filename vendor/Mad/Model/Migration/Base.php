<?php
/**
 * @category   Mad
 * @package    Mad_Model
 * @subpackage Migration
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * @category   Mad
 * @package    Mad_Model
 * @subpackage Migration
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Model_Migration_Base
{
    /**
     * Print messages as migrations happen
     * @var boolean
     */
    public static $verbose = true;

    /**
     * The migration version
     * @var integer
     */
    public $version = null;

    
    public function __contruct() {}

    /**
     * Create a table. Accepts an optional closure to define columns,
     * which automatically calls end() when done.
     *
     *   $this->createTable('users', function($t) {
     *       $t->column('name', 'string');
     *   });
     *
     * Without a closure, returns the table definition for manual use:
     *
     *   $t = $this->createTable('users');
     *       $t->column('name', 'string');
     *   $t->end();
     */
    public function createTable($name, $options=null, $closure=null)
    {
        // createTable('name', function($t) { ... })
        if (is_callable($options)) {
            $closure = $options;
            $options = [];
        }
        if ($options === null) {
            $options = [];
        }

        $this->say("createTable($name" . ($closure ? ", {closure}" : "") . ")");

        $t = new Horde_Support_Timer();
        $t->push();
            $connection = Mad_Model_Base::connection();
            $tableDefinition = $connection->createTable($name, $options);
        $time = $t->pop();
        $this->say(sprintf("%.4fs", $time), 'subitem');

        if ($closure !== null) {
            $closure($tableDefinition);
            $tableDefinition->end();
            return;
        }

        return $tableDefinition;
    }

    /**
     * Proxy methods over to the connection
     * @param   string  $method
     * @param   array   $args
     */
    public function __call($method, $args)
    {
        $a = [];
        foreach ($args as $arg) {
            if (is_array($arg)) {
                $vals = [];
                foreach ($arg as $key => $value) {
                    $vals[] = "$key => ".var_export($value, true);
                }
                $a[] = 'array('.join(', ', $vals).')';
            } elseif ($arg instanceof Closure) {
                $a[] = '{closure}';
            } else {
                $a[] = $arg;
            }
        }
        $this->say("$method(".join(", ", $a).")");

        // benchmark method call
        $t = new Horde_Support_Timer();
        $t->push();
            $connection = Mad_Model_Base::connection();
            $result = call_user_func_array([$connection, $method], $args);
        $time = $t->pop();

        // print stats
        $this->say(sprintf("%.4fs", $time), 'subitem');
        if (is_int($result)) { $this->say("$result rows", 'subitem'); }

        return $result;
    }


    /*##########################################################################
    # Public
    ##########################################################################*/

    public function upWithBechmarks()
    {
        $this->migrate('up');
    }

    public function downWithBenchmarks()
    {
        $this->migrate('down');
    }
    
    /**
     * Execute this migration in the named direction
     */
    public function migrate($direction)
    {
        if (!method_exists($this, $direction)) { return;  }

        if ($direction == 'up')   { $this->announce("migrating"); }
        if ($direction == 'down') { $this->announce("reverting"); }

        $result = null;
        $t = new Horde_Support_Timer;
        $t->push();
            $result = $this->$direction();
        $time = $t->pop();

        if ($direction == 'up')   { 
            $this->announce("migrated (".sprintf("%.4fs", $time).")"); 
            $this->write();
        }
        if ($direction == 'down') { 
            $this->announce("reverted (".sprintf("%.4fs", $time).")"); 
            $this->write();
        }
        return $result;
    }

    /**
     * @param   string  $text
     */
    public function write($text='')
    {
        if (self::$verbose) print "$text\n";
    }

    /**
     * Announce migration
     * @param   string  $message
     */
    public function announce($message)
    {
        $text = "$this->version ".get_class($this).": $message";
        $length = 75-strlen($text) > 0 ? 75-strlen($text) : 0;

        $this->write(sprintf("== %s %s", $text, str_repeat('=', $length)));
    }

    /**
     * @param   string  $message
     * @param   boolean $subitem
     */
    public function say($message, $subitem=false)
    {
        $this->write(($subitem ? "   ->" : "--"). " $message");
    }
}