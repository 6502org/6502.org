<?php
/**
 * @category   Mad
 * @package    Mad_Task
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */

/**
 * Built-in framework tasks for testing.
 *
 * @category   Mad
 * @package    Mad_Task
 * @copyright  (c) 2007-2009 Maintainable Software, LLC
 * @license    http://opensource.org/licenses/bsd-license.php BSD
 */
class Mad_Task_BuiltinSet_Testing extends Mad_Task_Set
{
    /**
     * Test all units and functionals
     */
    public function test()
    {
        $this->_chdir("test");
        $this->_phpunit();
    }

    /**
     * Run the unit tests
     */
    public function test_units()
    {
        $this->_chdir("test/unit");
        $this->_ensureAnnotated('unit');
        $this->_phpunit('--group unit');
    }

    /**
     * Run the functional tests
     */
    public function test_functionals()
    {
        $this->_chdir("test/functional");
        $this->_ensureAnnotated('functional');
        $this->_phpunit('--group functional');
    }

    private function _chdir($reldir)
    {
        $path = MAD_ROOT . '/' . $reldir;

        if (! is_dir($path)) {
            echo "Directory does not exist: $path";
            exit(1);
        }

        chdir($path);
    }

    private function _phpunit($args = '')
    {
        $bootstrap = MAD_ROOT . '/test/AllTests.php';
        passthru("MAD_ENV=" . MAD_ENV . " phpunit --bootstrap $bootstrap --do-not-cache-result $args .", $exitCode);
        exit($exitCode);
    }

    /**
     * Check that test files in the current directory have the expected
     * group annotation. Without it, PHPUnit --group will silently
     * skip them.
     */
    private function _ensureAnnotated($group)
    {
        $missing = [];
        foreach (glob("*Test.php") as $file) {
            $contents = file_get_contents($file);
            if (strpos($contents, "Group('$group')") === false &&
                strpos($contents, "@group $group") === false) {
                $missing[] = basename($file);
            }
        }

        if (!empty($missing)) {
            echo "Error: The following test files are missing the '$group' group annotation:\n";
            foreach ($missing as $file) {
                echo "  $file\n";
            }
            echo "\nAdd #[\\PHPUnit\\Framework\\Attributes\\Group('$group')] before the class declaration.\n";
            exit(1);
        }
    }

}
