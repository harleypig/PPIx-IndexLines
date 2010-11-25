package PPIx::IndexLines;
# ABSTRACT: Given a line number, returns some basic information about where in the perl document you are

use strict;

use PPI;

sub new { PPI::Document->new( $_[1] ) }

package PPI::Document;

use strict;

sub index_lines {

  my $self = shift;

  my @el = $self->elements;

  my $package = 'main';
  my $info;

  my %lookup = (

    'PPI::Statement::Data'      => sub { '__DATA__' },
    'PPI::Statement::End'       => sub { '__END__' },
    'PPI::Statement::Package'   => sub { $package = $_[0]->namespace },
    'PPI::Statement::Scheduled' => sub { $_[0]->type },
    'PPI::Statement::Sub'       => sub { sprintf '%s::%s', $package, $_[0]->name },

    # Is this interesting enough to include?
    #'PPI::Token::Comment'       => sub { sprintf '%s (%s)', $package, 'comment' },

    'PPI::Token::Pod'           => sub { 'POD' },

  );

  my $last_line_number = 0;

  for my $e ( @el ) {

    my $line_number = $e->line_number;

    next if exists $self->{ 'line' }{ $line_number };

    $self->{ 'line' }{ $_ } = $info
      for $last_line_number+1 .. $line_number-1;

    $last_line_number = $line_number;

    my $node_type = ref $e;

    $self->{ 'line' }{ $line_number } = $info = exists $lookup{ $node_type } ? $lookup{ $node_type }->( $e ) : $package;

  }
}

sub line_type { $_[0]->{ 'line' } || '' }
