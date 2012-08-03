<?php

if (!defined('MAD_ENV')) define('MAD_ENV', 'test');
if (!defined('MAD_ROOT')) {
    require_once dirname(dirname(__FILE__)).'/config/environment.php';
}

if (!defined('PHPUnit_MAIN_METHOD')) {
    define('PHPUnit_MAIN_METHOD', 'AllTests::main');
}

class AllTests
{
    public static function main()
    {
        PHPUnit_TextUI_TestRunner::run(self::suite());
    }

    public static function suite()
    {
        $suite = new PHPUnit_Framework_TestSuite('Mad');

        $basedir = dirname(__FILE__);

        foreach (array('unit', 'functional') as $testdir) {
            $dir = "$basedir/$testdir/";
            $dirRegexp = preg_quote($dir, '/');

            foreach(new RecursiveIteratorIterator(
                     new RecursiveDirectoryIterator($dir)) as $file) {

                if ($file->isFile() && preg_match('/Test.php$/', $file->getFilename())) {
                    $pathname = $file->getPathname();
                    require_once $pathname;

                    $class = str_replace(DIRECTORY_SEPARATOR, '_', 
                                         preg_replace("/^{$dirRegexp}(.*)\.php/", '\\1', $pathname));
                    $suite->addTestSuite($class);
                }
            }
            
        }

        return $suite;
    }
}

if (PHPUnit_MAIN_METHOD == 'AllTests::main') {
    AllTests::main();
}
