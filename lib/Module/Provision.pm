# @(#)Ident: Provision.pm 2013-05-10 20:47 pjf ;

package Module::Provision;

use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.12.%d', q$Rev: 7 $ =~ /\d+/gmx );

use Moose;

extends q(Module::Provision::Base);
with    q(Module::Provision::TraitFor::Rendering);
with    q(Module::Provision::TraitFor::CreatingDistributions);
with    q(Module::Provision::TraitFor::UpdatingContent);
with    q(Module::Provision::TraitFor::VCS);
with    q(Module::Provision::TraitFor::AddingFiles);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 Name

Module::Provision - Create Perl distributions with VCS and selectable toolchain

=head1 Version

This documents version v0.12.$Rev: 7 $ of L<Module::Provision>

=head1 Synopsis

   # To reduce typing define a shell alias
   alias mp='module_provision --base ~/Projects'

   # Create a new distribution in your Projects directory with Git VCS
   mp dist Foo::Bar 'Optional one line abstract'

   # Add another module
   cd ~/Projects/Foo-Bar
   mp module Foo::Bat 'Optional one line abstract'

   # Add a program to the bin directory
   mp program bar-cli 'Optional one line abstract'

   # Add another test script
   mp test 11another-one.t

   # Edit the project master file
   mp -q edit_project

   # Update the version numbers of the project files
   mp update_version 0.1 0.2

   # Regenerate meta data files
   mp metadata

   # Command line help
   mp -? | -H | -h [sub-command] | list_methods | dump_self

=head1 Description

L<Module::Provision> is used to create a skeletal CPAN distribution,
including basic builder scripts, tests, documentation, and module
code. It creates a VCS repository and, in the Git case, installs some
hooks that mimic the RCS Revision keyword expansion

On first use the directory F<~/.module_provision> is created and
populated with templates and an index file F<index.json>. The author
name, id, and email are derived from the system (the environment
variables C<AUTHOR> and C<EMAIL> take precedence). The can be
overridden by the values in the configuration file
F<~/.module_provision/module_provision.json>

If the default builder (C<MB>) is used, then the project file
F<Build.PL> loads C<inc::Bob> which instantiates an inline subclass of
L<Module::Build>. The code for the subclass is in
C<inc::SubClass>. The file C<inc::CPANTesting> allows for fine grained
control over which tests are run by which CPAN Testing smokers

The default builder used by the create distribution method can be
changed from the command line or from the configuration file

If the Git VCS is used C<precommit> and C<commit-msg> hooks are
installed. The C<precommit> hook will expand the RCS Revision keyword
in files on the master branch if the file F<.distribution_name.rev>
exists in the parent of the working tree. The C<precommit> hook will
also update the version number and date/time stamp in the change log
(F<Changes>).  The C<commit-msg> hook will extract the first comment
line from the change log and use it as the commit message header. The
remainder of the commit message (if any) is used as the commit message
body. This means that so long as one detail line is added to the
change log no other commit message text is required. The following
makes for a suitable C<git log> alias:

   alias gl='git log -5 --pretty=format:"%h %ci %s" | \
      cut -d" " -f1-3,5- | cut -c1-79'

The default VCS used by the create distribution methods can be
changed from the command line or from the configuration file

The templates contain comment lines like:

   # @(#)Ident: Provision.pm 2013-04-15 13:52 pjf ;

These are expanded automatically by Emacs using this Lisp code:

   (setq time-stamp-active     t
         time-stamp-line-limit 10
         time-stamp-format     " %f %04y-%02m-%02d %02H:%02M %u "
         time-stamp-start      "Ident:"
         time-stamp-time-zone  "UTC"
         time-stamp-end        ";")

The alias:

   alias ident='ack "@\(#\)"'

uses the L<App::Ack> program to implement the old SYSV R4 C<ident>
command

The templates for the project files F<dist.ini>, F<Build.PL>, and
F<Makefile.PL> contain the following comments which are interpreted by
Emacs:

   # Local Variables:
   # mode: perl
   # eval: (load-project-state "[% appdir %]")
   # tab-title: [% project %]
   # tab-width: 3
   # End:

Perl mode is preferred over C-Perl mode since the former has better
syntax highlighting. Tabs are expanded to three spaces. The
C<tab-title> variable is used by L<Yakuake::Sessions> to set the tab
title for the terminal emulator. The C<load-project-state> Lisp looks
like this:

   (defun load-project-state (state-file) "Recovers the TinyDesk state from file"
      (let ((session-path (concat "~/.emacs.d/config/state." state-file)))
         (if (file-exists-p session-path) (tinydesk-recover-state session-path)
            (message (concat "Not found: " state-file)))))

It assumes that the TinyDesk state file containing the list of files to edit
for the project has been saved in F<~/.emacs.d/config/state.[% appdir %]>. To
work on a project; change directory to the working copy, edit the project
file F<Build.PL> with Emacs, this will load all of the other files in the
project into separate buffers displaying each in the tab bar. This Lisp code
will load TinyDesk and turn tab bar mode on whenever a Perl file is edited:

   (add-hook 'perl-mode-hook
             '(lambda ()
                (require 'fic-mode) (turn-on-fic-mode) (diminish 'fic-mode nil)
                (require 'psvn) (require 'tinydesk) (tabbar-mode t)
                (require 'tinyperl) (diminish 'tinyperl-mode nil)))

This Lisp code will do likewise when a F<dist.ini> file is edited:

   (add-hook 'conf-windows-mode-hook
             '(lambda ()
                (require 'tinydesk) (tabbar-mode t)))

=head1 Configuration and Environment

The configuration file defaults to
F<~/.module_provision/module_provision.json>. All of the attributes listed in
L<Module::Provision::Config> can set from the configuration file in addition
to the attributes listed in L<Class::Usul::Config::Programs> and
L<Class::Usul::Config>. A typical file looks like;

   {
      "author": "<first_name> <last_name>",
      "author_email": "<userid>@example.com",
      "author_id": "<userid>",
      "base": "/home/<userid>/Projects",
      "doc_title": "Perl",
      "editor": "emacs",
      "home_page": "http://www.example.com"
   }

Creating F<logs> and F<tmp> directories in F<~/.module_provision> will cause
the log and temporary files to use them instead of F</tmp>

Extends L<Module::Provision::Base>. Applies these traits;
C<AddingFiles>, C<Config>, C<CreatingDistributions>, C<Rendering>,
C<UpdatingContent>, and C<VCS>

Defines no attributes

=head1 Subroutines/Methods

=head2 dist

   module_provision dist Foo::Bar 'Optional one line abstract'

Create a new distribution specified by the module name on the command line

=head2 edit_project

   module_provision -q edit_project

Edit the project file (one of; F<dist.ini>, F<Build.PL>, or
F<Makefile.PL>) in the project directory. The editor defaults to
C<emacs> but can be set on the command line, e.g C<-o editor=vim>

=head2 metadata

   module_provision metadata

Generates the distribution metadata files

=head2 init_templates

   module_provision init_templates

Initialise the F<.module_provision> directory and create the F<index.json> file

=head2 module

   module_provision module Foo::Bat 'Optional one line abstract'

Creates a new module specified by the class name on the command line

=head2 program

   module_provision program bar-cli 'Optional one line abstract'

Creates a new program specified by the program name on the command line

=head2 prove

   module_provision prove

Runs the projects tests

=head2 show_tab_title

   module_provision -q show_tab_title

Print the tab title for the current project. Can be used like this;

   alias ep='mp -q edit_project ; \
      yakuake_session set_tab_title_for_project $(mp -q show_tab_title)'

=head2 test

   module_provision test 11another-one.t

Creates a new test specified by the test file name on the command line

=head2 update_copyright_year

   module_provision update_copyright_year 2013 2014

Substitutes the existing copyright year for the new copyright year in all
files in the F<MANIFEST>

=head2 update_version

   module_provision update_version 0.1 0.2

Substitutes the existing version number for the new version number in all
files in the F<MANIFEST>

=head1 Diagnostics

Add C<-D> to command line to turn on debug output

=head1 Dependencies

=over 3

=item L<Module::Provision::Base>

=item L<Module::Provision::TraitFor::AddingFiles>

=item L<Module::Provision::TraitFor::CreatingDistributions>

=item L<Module::Provision::TraitFor::Rendering>

=item L<Module::Provision::TraitFor::UpdatingContent>

=item L<Module::Provision::TraitFor::VCS>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.  Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Provision.  Source
code is on Github git://github.com/pjfl/Module-Provision.git. Patches
and pull requests are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

L<Module::Starter> - For some of the documentation and tests

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2013 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
