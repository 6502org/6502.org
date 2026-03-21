# Main Website

This is the source code for the main part of the [6502.org](http://6502.org/) website.

The website requires a Unix-like machine (e.g. Linux, macOS) and PHP version 5.4 through 8.4 with the `curl`, `pdo_sqlite`, and `zip` extensions installed.  To run the test suite, `phpunit` is also required.

On Ubuntu 24.04 LTS, these commands will install the requirements:

```
$ sudo apt update

$ sudo apt install git php-cli php-curl php-sqlite3 php-zip phpunit sqlite3
```

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

$ php ./script/server
[Wed Mar 11 22:32:03 2026] PHP 8.3.6 Development Server (http://localhost:3000) started
```

Open a browser to http://localhost:3000/ to view it.  It will be a fully functional 6502.org, missing only the hosted sub-sites and the forum.

(To use a port other than the default `3000`, see ``php ./script/server --help``.)

## Documents Achive

6502.org hosts many gigabytes of large files in the [Documents Archive](http://6502.org/documents), such as the datasheet PDFs. These files are not included in this Git repository.

When running the website locally, documents will be served from a public mirror if they do not exist on disk.  A script is provided to automatically download the documents from the public mirrors to the local disk.  With no arguments, the script will download the entire archive:

```
$ php script/download_documents
Destination: /home/user/6502.org/public/documents
Found 658 files (17.0 GB total)

Checking existing files...
  0 OK, 658 to download

[1/658] Downloading appnotes/6502_assembler_in_basic.pdf
```

A file will only be downloaded if it is missing or corrupt.  If a mirror is down or the script is interrupted, the script can be run again and it will only try to download the remaining files.

Use ``--help`` for a list of options.  The ``--filter`` option in particular is useful if you only want a subset of the documents to be downloaded.  For example, if you only want to download the datasheets:

```
$ php script/download_documents --filter=datasheets
```

## Hosted Sites

6502.org also hosts various sub-sites with 6502-related content.  At the time of writing, these are:

- `/users/alexis`: [Alexis Kotlowy-Brown's "ROMless 6502" Project](https://github.com/6502org/alexis)
- `/users/andre`: [André Fachat's 8-bit Pages](https://github.com/6502org/andre)
- `/users/obelisk`: [Andrew Jacobs' "Obelisk" Pages](https://github.com/6502org/obelisk)
- `/users/dallas`: [Dallas Shell's SYM-1 Pages](https://github.com/6502org/dallas)
- `/users/dieter`: [Dieter Mueller's TTL CPU Pages](https://github.com/6502org/dieter)
- `/users/garth`: [Garth Wilson's Project Pages](https://github.com/6502org/garth)
- `/users/idoc`: [Peter Krefting's "iDoc=" Website](https://github.com/6502org/idoc)
- `/users/krzysztof`: [Krzysztof Swiecicki's Project Pages](https://github.com/6502org/krzysztof)
- `/users/mike`: [Mike Naberezny's 6504 Project](https://github.com/6502org/mike)
- `/users/mycorner`: [Lee Davison's "My Corner" Website](https://github.com/6502org/mycorner)

Each link above is a GitHub repository under 6502.org's [GitHub organization](https://github.com/6502org).  To build the complete 6502.org website, each of these websites must be installed under the [`public/users/`](./public/users/) directory.  All of these are static websites but some of the repositories require running a build step to generate the static files.  See the instructions in each repository.

## Forum

The forum runs on [phpBB](https://www.phpbb.com/) and is installed under [`public/forum/`](./public/forum).  Since the forum's phpBB database contains passwords and private messages, it is not included in 6502.org's public GitHub organization.  The phpBB installation must be provided by one of the 6502.org maintainers with access to it.
