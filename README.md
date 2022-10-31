# Main Website

This is the source code for the main part of the [6502.org](http://6502.org/) website, which is everything except the forum, users' pages, and the PDF files in the documents archive.

The website requires a Unix-like machine (e.g. Linux, macOS) and PHP version 5.4 through 7.4.  The PHP option `short_open_tag` must be enabled and the `pdo_sqlite` extension must be installed.  If these requirements are not met, an error message will be displayed saying so.

You can run the website locally using PHP's built-in webserver.  Start it from the `public/` directory:

```text
$ php -v
PHP 7.4.32 (cli) (built: Sep 29 2022 11:03:56) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
    with Zend OPcache v7.4.32, Copyright (c), by Zend Technologies

$ cd public/

$ php -d short_open_tag=on -S localhost:8000
[Sun Oct 30 19:42:27 2022] PHP 7.4.32 Development Server (http://localhost:8000) started
```

Open a browser to http://localhost:8000/ to view it.
