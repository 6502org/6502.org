# Main Website

This is the source code for the main part of the [6502.org](http://6502.org/) website, which is everything except the forum, users' pages, and the PDF files in the documents archive.

## Requirements

The website requires a Unix-like machine (e.g. Linux, macOS) and PHP version 5.4 through 8.4 with the `curl` and `pdo_sqlite` extensions installed.

On Ubuntu 24.04 LTS, these commands will install the requirements:

```
$ sudo apt update

$ sudo apt install git php-cli php-curl php-sqlite3
```

## Development

Clone this Git repository and run the website locally using PHP's built-in webserver:

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

$ php -S localhost:8000 -t public/ local.php
[Wed Mar 11 22:32:03 2026] PHP 8.3.6 Development Server (http://localhost:8000) started
```

Open a browser to http://localhost:8000/ to view it.  

It will be a fully functional 6502.org, missing only the hosted sub-sites and the forum.

## Documents

The files in the [Documents Archive](http://6502.org/documents), such as the datasheet PDFs, are not included in this repository. When running the website locally, documents will be served from a public mirror if they do not exist on disk.

A script is provided to automatically download the documents from the public mirrors to the local disk.  With no arguments, the script will download the entire archive:


```
$ php script/download_documents
Destination: /home/user/6502.org/public/documents
Found 658 files (17.0 GB total)

Checking existing files...
  0 OK, 658 to download

[1/658] Downloading appnotes/6502_assembler_in_basic.pdf
```

A file will only be downloaded if it is missing or if its SHA1 hash does match the expected one.  If a mirror is down or the script is interrupted, the script can be run again and it will only try to download the remaining files.

Use ``--help`` for a list of options.  The ``--filter`` option in particular is useful if you only want a subset of the documents to be downloaded.  For example, if you only want to download the datasheets:

```
$ php script/download_documents --filter=datasheets
```
