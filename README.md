seekrit
=======

seekrit is a password safe with the following features:

* Secret data is encrypted using AES-256
* The data is stored in an ordered line-oriented format to facilitate version control

Usage
-----

    seekrit COMMAND [PARAMETERS]

Commands:

    list                      List all entries.
    show name(s)              Show matching entries.
    edit name(s)              Create or modify entries.
    delete name(s)            Delete entries.
    rename old_name new_name  Rename entry.

Entries will be opened for editing in the editor defined by the `EDITOR`
environment variable, falling back to `vi` if it's not defined.

Storage
-------

Data is stored in `~/.config/seekrit/data`

Synchronisation
---------------

Two scripts are run before and after operations:

* `~/.config/seekrit/pre-load` is run before every lookup
* `~/.config/seekrit/post-save` is run after a change is made

For example, to synchronise your password automatically with a (preferably
private!) git repository, initialize a git repository in `~/.config/seekrit`,
set up the remote origin, and add the scripts:

`pre-load`

    #!/bin/sh
    git pull origin master || echo

`post-save`

    #!/bin/sh
    git status | grep secrets && \
    git add secrets && \
    git commit -m "Automatic" && git push origin master
