# Main Website

This is the source code for the main part of the [6502.org](http://6502.org/) website, which is everything except the forum, users' pages, and the PDF files in the documents archive.

The website requires a Unix-like machine (e.g. Linux, macOS) and PHP version 5.4 through 7.4.  The PHP option `short_open_tag` must be enabled and the `pdo_sqlite` extension must be installed.

On Ubuntu 18.04 LTS, this will install the requirements:

```
$ sudo apt install php7.2-cli php7.2-sqlite3
```

You can run the website locally using PHP's built-in webserver:

```text
$ git clone https://github.com/6502org/6502.org.git 
Cloning into '6502.org'...
remote: Enumerating objects: 5079, done.
remote: Counting objects: 100% (326/326), done.
remote: Compressing objects: 100% (163/163), done.
remote: Total 5079 (delta 191), reused 267 (delta 161), pack-reused 4753
Receiving objects: 100% (5079/5079), 225.12 MiB | 10.33 MiB/s, done.
Resolving deltas: 100% (3459/3459), done.

$ cd 6502.org 

$ php -d short_open_tag=on -S localhost:8000 -t public/ local.php
[Tue Nov  1 12:55:02 2022] PHP 7.4.32 Development Server (http://localhost:8000) started
```

Open a browser to http://localhost:8000/ to view it.
