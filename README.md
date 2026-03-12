# Main Website

This is the source code for the main part of the [6502.org](http://6502.org/) website, which is everything except the forum, users' pages, and the PDF files in the documents archive.

The website requires a Unix-like machine (e.g. Linux, macOS) and PHP version 5.4 through 8.4 with the `pdo_sqlite` extension installed.

On Ubuntu Desktop 24.04 LTS, these commands will install the requirements:

```
$ sudo add-apt-repository ppa:ondrej/php

$ sudo apt update

$ sudo apt install git php8.4-cli php8.4-sqlite3
```

You can then clone this Git repository and run the website locally using PHP's built-in webserver:

```text
$ git clone --depth 1 https://github.com/6502org/6502.org.git
Cloning into '6502.org'...
remote: Enumerating objects: 640, done.
remote: Counting objects: 100% (640/640), done.
remote: Compressing objects: 100% (569/569), done.
remote: Total 640 (delta 51), reused 493 (delta 44), pack-reused 0 (from 0)
Receiving objects: 100% (640/640), 124.21 MiB | 1.53 MiB/s, done.
Resolving deltas: 100% (51/51), done.

$ cd 6502.org 

$ php8.4 -S localhost:8000 -t public/ local.php
[Wed Mar 11 22:32:03 2026] PHP 8.4.11 Development Server (http://localhost:8000) started
```

Open a browser to http://localhost:8000/ to view it.  

Although the PDF files for the documents archive are not included in this Git repository, they will be served from [archive.org](https://web.archive.org/web/*/6502.org) when the website is run locally.
