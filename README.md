# Name

Module::Provision - Create Perl distributions with VCS and selectable toolchain

# Version

This documents version v0.5.$Rev: 57 $ of [Module::Provision](https://metacpan.org/module/Module::Provision)

# Synopsis

    # To reduce typing define a shell alias
    alias mp='module_provision --base ~/Projects'

    # Create a new distribution in your Projects directory with Git VCS
    mp dist Foo::Bar [ 'Optional one line abstract' ]

    # Add another module
    cd ~/Projects/Foo-Bar
    mp module Foo::Bat [ 'Optional one line abstract' ]

    # Add a program to the bin directory
    mp program bar-cli [ 'Optional one line abstract' ]

    # Add another test script
    mp test 11another-one.t

    # Update the version number
    mp update_version 0.1 0.2

    # Command line help
    mp -? | -H | -h [sub-command] | list_methods | dump_self

# Description

[Module::Provision](https://metacpan.org/module/Module::Provision) is used to create a skeletal CPAN distribution,
including basic builder scripts, tests, documentation, and module
code. It creates a VCS repository and, in the Git case, installs some
hooks that mimic the RCS Revision keyword expansion

On first use the directory `~/.code\_templates` is created and
populated with templates and an index file `index.json`. The author
name, id, and email are derived from the system (the environment
variables `AUTHOR` and `EMAIL` take precedence) and stored in the
`author`, `author\_id`, and `author\_email` files

If the default builder (`MB`) is used, then the project file
`Build.PL` loads `inc::Bob` which instantiates an inline subclass of
[Module::Build](https://metacpan.org/module/Module::Build). The code for the subclass is in
`inc::SubClass`. The file `inc::CPANTesting` allows for fine grained
control over which tests are run by which CPAN Testing smokers

If the Git VCS is used `precommit` and `commit-msg` hooks are
installed. The `precommit` hook will expand the RCS Revision keyword
in files on the master branch if the file `.distribution\_name.rev`
exists in the parent of the working tree. The `precommit` hook will
also update the version number and date/time stamp in the change log
(`Changes`).  The `commit-msg` hook will extract the first comment
line from the change log and use it as the commit message header. The
remainder of the commit message (if any) is used as the commit message
body. This means that so long as one detail line is added to the
change log no other commit message text is required. The following
makes for a suitable `git log` alias:

    alias gl='git log -10 --pretty=format:"%h %ci %s" | cut -c1-79'

The templates contain comment lines like:

    # @(#)Ident: Provision.pm 2013-04-15 13:52 pjf ;

These are expanded automatically by Emacs using this Lisp code:

    (setq time-stamp-active     t
          time-stamp-line-limit 10
          time-stamp-format     " %f %04y-%02m-%02d %02H:%02M %u "
          time-stamp-start      "Ident:"
          time-stamp-time-zone  "GMT"
          time-stamp-end        ";")

The alias:

    alias ident='ack "@\(#\)"'

uses the [App::Ack](https://metacpan.org/module/App::Ack) program to implement the old SYSV R4 `ident`
command

The template for `Build.PL` contains the following comment which is
interpreted by Emacs:

    # Local Variables:
    # eval: (load-project-state "[% appdir %]")
    # mode: perl
    # tab-title: [% project %]
    # tab-width: 3
    # End:

Perl mode is preferred over C-Perl mode since the former has better
syntax highlighting. Tabs are expanded to three spaces. The
`tab-title` variable is used by [Yakuake::Sessions](https://metacpan.org/module/Yakuake::Sessions) to set the tab
title for the terminal emulator. The `load-project-state` Lisp looks
like this:

    (defun load-project-state (state-file) "Recovers the TinyDesk state from file"
       (let ((session-path (concat "~/.emacs.d/config/state." state-file)))
          (if (file-exists-p session-path) (tinydesk-recover-state session-path)
             (message (concat "Not found: " state-file)))))

It assumes that the TinyDesk state file containing the list of files to edit
for the project has been saved in `~/.emacs.d/config/state.\[% appdir %\]`. To
work on a project; change directory to the working copy, edit the project
file `Build.PL` with Emacs, this will load all of the other files in the
project into separate buffers displaying each in the tab bar. This Lisp code
will load TinyDesk and turn tab bar mode on whenever a Perl file is edited:

    (add-hook 'perl-mode-hook
              '(lambda ()
                 (require 'fic-mode) (turn-on-fic-mode) (diminish 'fic-mode nil)
                 (require 'psvn) (require 'tinydesk) (tabbar-mode t)
                 (require 'tinyperl) (diminish 'tinyperl-mode nil)))

This Lisp code will do likewise when a `dist.ini` file is edited:

    (add-hook 'conf-windows-mode-hook
              '(lambda ()
                 (require 'tinydesk) (tabbar-mode t)))

# Configuration and Environment

Defines the following list of attributes which can be set from the
command line;

- `base`

    The directory which will contain the new project. Defaults to the users
    home directory

- `branch`

    The name of the initial branch to create. Defaults to `master` for
    Git and `trunk` for SVN

- `builder`

    Which of the three build systems to use. Defaults to `MB`, which is
    [Module::Build](https://metacpan.org/module/Module::Build). Can be `DZ` for [Dist::Zilla](https://metacpan.org/module/Dist::Zilla) or `MI` for
    [Module::Install](https://metacpan.org/module/Module::Install)

- `force`

    Overwrite the output files if they already exist

- `license`

    The name of the license used on the project. Defaults to `perl`

- `novcs`

    Do not create or use a VCS. Defaults to `FALSE`. Used by the test script

- `perms`

    Permissions used to create files. Defaults to `644`. Directories and
    programs have the execute bit turned on if the corresponding read bit
    is on

- `project`

    The class name of the new project. Should be the first extra argument on the
    command line

- `repository`

    Name of the directory containing the SVN repository. Defaults to `repository`

- `templates`

    Location of the code templates in the users home directory. Defaults to
    `.code\_templates`

- `vcs`

    The version control system to use. Defaults to `git`, can be `svn`

# Subroutines/Methods

The following methods constitute the public API

## create\_directories

    $self->create_directories;

Creates the required directories for the new distribution

## dist

    $exit_code = $self->dist;

Create a new distribution specified by the module name on the command line

## init\_templates

    $exit_code = $self->init_templates;

Initialise the `.code\_templates` directory and create the `index.json` file

## module

    $exit_code = $self->module;

Creates a new module specified by the class name on the command line

## post\_hook

    $self->post_hook;

Runs after the new distribution has been created

## pre\_hook

    $self->pre_hook;

Runs before the new distribution is created

## program

    $exit_code = $self->program;

Creates a new program specified by the program name on the command line

## render\_templates

    $self->render_templates;

Renders the list of templates in `$self->_template_list` be
repeatedly calling calling [Template](https://metacpan.org/module/Template) passing in the `$self->_stash`

## test

    $exit_code = $self->test;

Creates a new test specified by the test file name on the command line

## update\_copyright\_year

    $self->update_copyright_year;

Substitutes the existing copyright year for the new copyright year in all
files in the `MANIFEST`

## update\_version

    $self->update_version;

Substitutes the existing version number for the new version number in all
files in the `MANIFEST`

# Diagnostics

Add `-D` to command line to turn on debug output

# Dependencies

- [Class::Usul](https://metacpan.org/module/Class::Usul)
- [Date::Format](https://metacpan.org/module/Date::Format)
- [File::DataClass](https://metacpan.org/module/File::DataClass)
- [File::ShareDir](https://metacpan.org/module/File::ShareDir)
- [Module::Metadata](https://metacpan.org/module/Module::Metadata)
- [Perl::Version](https://metacpan.org/module/Perl::Version)
- [Pod::Markdown](https://metacpan.org/module/Pod::Markdown)
- [Template](https://metacpan.org/module/Template)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module.  Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Provision.  Source
code is on Github git://github.com/pjfl/Module-Provision.git. Patches
and pull requests are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

[Module::Starter](https://metacpan.org/module/Module::Starter) - For some of the documentation and tests

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2013 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/module/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
