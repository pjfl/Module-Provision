# @(#)Ident: Rendering.pm 2013-05-02 03:38 pjf ;

package Module::Provision::TraitFor::Rendering;

use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.9.%d', q$Rev: 3 $ =~ /\d+/gmx );

use Moose::Role;
use Class::Usul::Constants;
use Class::Usul::Functions qw(is_arrayref throw);
use MooseX::Types::Moose   qw(ArrayRef Bool);

requires qw(_template_dir vcs);

# Object attributes (public)
has 'force'          => is => 'ro', isa => Bool, default => FALSE,
   documentation     => 'Overwrite files if they already exist',
   traits            => [ 'Getopt' ], cmd_aliases => q(f), cmd_flag => 'force';

# Object attributes (private)
has '_template_list' => is => 'ro', isa => ArrayRef, traits => [ 'Array' ],
   handles           => { all_templates => 'elements', }, lazy => TRUE,
   builder           => '_build__template_list', init_arg => undef;

# Public methods
sub init_templates : method {
   my $self = shift; $self->_template_list; return OK;
}

sub render_template {
   my ($self, $template, $target) = @_;

   $template or throw 'No template specified';
   $target   or throw 'No template target specified';

   $target->exists and $target->is_dir
      and $target = $target->catfile( $template );
   $template = $self->_template_dir->catfile( $template );

   $template->exists or
      return $self->log->warn( $self->loc( 'Path [_1] not found', $template ) );

   my $file  = $target->filename; my $prompt;

   $target->exists and not $self->force
      and $prompt = $self->add_leader( "File ${file} exists, overwrite?" )
      and not $self->yorn( $prompt, FALSE, TRUE )
      and return $target;

   my $conf  = { ABSOLUTE => TRUE, }; my $text = NUL;

   $conf->{VARIABLES}->{loc} = sub { return $self->loc( @_ ) };

   my $tmplt = Template->new( $conf ) or throw $Template::ERROR;

   $tmplt->process( $template->pathname, $self->_stash, \$text )
      or throw $tmplt->error();
   $target->perms( $self->perms )->print( $text ); $target->close;
   return $target;
}

sub render_templates {
   my $self = shift; $self->output( $self->loc( 'Rendering templates' ) );

   for my $tuple ($self->all_templates) {
      for (my $i = 0, my $max = @{ $tuple }; $i < $max; $i++) {
         if (is_arrayref $tuple->[ $i ]) {
            my $method = $tuple->[ $i ]->[ 0 ];

            '_' eq substr $method, 0, 1
               and $tuple->[ $i ]->[ 0 ] = $self->$method();
            $tuple->[ $i ] = $self->io( $tuple->[ $i ] );
         }
         else {
            my $method = $tuple->[ $i ];

            '_' eq substr $method, 0, 1 and $tuple->[ $i ] = $self->$method();
         }
      }

      $self->render_template( @{ $tuple } );
   }

   return;
}

# Private methods
sub _build__template_list {
   my $self = shift; my $index = $self->_template_dir->catfile( 'index.json' );

   my $data; $index->exists and $data = $self->file->data_load
      ( paths => [ $index ], storage_class => 'Any' )
      and return $self->_merge_lists( $data );
   my $builders  = {
      DZ => [ [ 'dist.ini',           '_appldir' ], ],
      MB => [ [ 'Build.PL',           '_appldir' ],
              [ 'Bob.pm',             '_incdir'  ],
              [ 'CPANTesting.pm',     '_incdir'  ],
              [ 'SubClass.pm',        '_incdir'  ], ],
      MI => [ [ 'MI_Makefile.PL',   [ '_appldir', 'Makefile.PL' ], ], ], };
   my $templates = [ [ 'Changes',         '_appldir'     ],
                     [ 'MANIFEST.SKIP',   '_appldir'     ],
                     [ 'perl_module.pm',  '_dist_module' ],
                     [ '01always_pass.t', '_testdir'     ],
                     [ '02pod.t',         '_testdir'     ],
                     [ '03podcoverage.t', '_testdir'     ],
                     [ '04critic.t',      '_testdir'     ],
                     [ '05kwalitee.t',    '_testdir'     ],
                     [ '06yaml.t',        '_testdir'     ],
                     [ '07podspelling.t', '_testdir'     ],
                     [ '10test_script.t', '_testdir'     ], ];
   my $vcs = {
      git => [ [ 'gitcommit-msg', [ '_appldir', '.gitcommit-msg' ] ],
               [ 'gitignore',     [ '_appldir', '.gitignore'     ] ],
               [ 'gitpre-commit', [ '_appldir', '.gitpre-commit' ] ], ],
      svn => [], };

   $self->output( "Creating index ${index}" );
   $data = { builders => $builders, templates => $templates, vcs => $vcs };
   $self->file->data_dump
      ( data => $data, path => $index, storage_class => 'Any' );
   return $self->_merge_lists( $data );
}

sub _merge_lists {
   my ($self, $args) = @_; my $list = $args->{templates};

   push @{ $list }, @{ $args->{builders}->{ $self->builder } };
   $self->vcs ne 'none' and push @{ $list }, @{ $args->{vcs}->{ $self->vcs } };

   return $list;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Module::Provision::TraitFor::Rendering - Renders Templates

=head1 Synopsis

   use Moose;

   extends 'Module::Provision::Base';
   with    'Module::Provision::TraitFor::Rendering';

=head1 Version

This documents version v0.9.$Rev: 3 $ of L<Module::Provision::TraitFor::Rendering>

=head1 Description

Renders templates

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<force>

Overwrite the output files if they already exist

=back

=head1 Subroutines/Methods

=head2 init_templates

   module_provision init_templates

Initialise the F<.module_provision> directory and create the F<index.json> file

=head2 render_template

   $target = $self->render_template( $template, $target );

Renders a single template using L<Template>

=head2 render_templates

Renders the list of templates in C<< $self->_template_list >> be
repeatedly calling calling L<Template> passing in the C<< $self->_stash >>.

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moose::Role>

=item L<MooseX::Types>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
