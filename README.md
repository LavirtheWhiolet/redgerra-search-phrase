Redgerra-search Phrase
======================

<!-- description -->
Search for the specific phrase in files or in Internet as specified by Redgerra.
<!-- end of description -->

Requirements
------------

You need [Ruby](http://ruby-lang.org) version 1.9.3 or higher and the development kit for it.

### Microsoft Windows XP and above ###

Download Ruby installer from http://rubyinstaller.org/downloads/. Version 1.9.3 or above is required. Run the installer.

Download Development Kit from http://rubyinstaller.org/downloads/ which corresponds to the Ruby version you have installed previously. Unpack it into the directory with the installed Ruby.

### GNU/Linux ###

In Ubuntu (http://www.ubuntu.com/) or Debian (https://www.debian.org/) you give the command (as root):

    apt-get install ruby ruby-dev

How to build
------------

Give the following command in this directory:

    gem build gem.gemspec

You will get an installation package named "*.gem" (e. g. "redgerra-search-phrase-1.2.3.gem").

How to install
--------------

Suppose you have got an installation package named "redgerra-search-phrase-1.2.3.gem". Give the following command (as root or as Administrator):

    gem install redgerra-search-phrase-1.2.3.gem

How to use
----------

### Redgerra::SearchPhraseWebApp ###

It is a [Rack](http://rack.github.io/)-compliant web-application for searching for the phrase in Internet.

The easiest way to start it is to give the following command:

    rackup -p PORT config.ru

Here `PORT` is the [port](https://en.wikipedia.org/wiki/Port_%28computer_networking%29) the web-server will run on; `config.ru` is "config.ru" from this directory. After that you open http://localhost:PORT/ in your Internet browser.

### `redgerra-search-phrase` ###

It is a command-line utility for searching for the phrase in local files.

You run it with the following command:

    redgerra-search-phrase SLOCH_OPTION dir_or_file1 dir_or_file2 ...

Here `SLOCH_OPTION` is one of the following:

- `-s sloch` - use specified sloch;
- `-f sloch_file` - read sloch from `sloch_file`.

`dir_or_file[n]` are files or directories which to search the phrase in.
