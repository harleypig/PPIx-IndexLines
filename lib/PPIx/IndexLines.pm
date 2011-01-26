package PPIx::IndexLines;

# ABSTRACT: Given a line number, returns some basic information about where in the perl document you are

use strict;

use PPI;
use Scalar::Util 'blessed';


# VERSION

=method new

Accepts either a scalar or a scalar reference.  This is passed directly to
PPI::Document::new, so the same rules as in that method apply.

Basically, if you pass in a scalar, it will be assumed to be a filename and
said file will be loaded and parsed.

Otherwise, a scalar reference is assumed to be a PPI document and will be
parsed directly.

=cut

sub new { bless { 'document' => PPI::Document->new( $_[ 1 ] ) }, $_[ 0 ] }

=method index_lines

Call this method to index the lines for the new PPI::Document.

=cut

sub index_lines {

  my $self = shift;
  my $document = $self->{ 'document' };

  my $package = 'main';
  my $info;

  my %lookup = (

    'PPI::Statement::Data'      => sub { '__DATA__' },
    'PPI::Statement::End'       => sub { '__END__' },
    'PPI::Statement::Package'   => sub { $package = $_[ 0 ]->namespace },
    'PPI::Statement::Scheduled' => sub { $_[ 0 ]->type },
    'PPI::Statement::Sub'       => sub { sprintf '%s::%s', $package, $_[ 0 ]->name },

    # Is this interesting enough to include?
    #'PPI::Token::Comment'       => sub { sprintf '%s (%s)', $package, 'comment' },

    'PPI::Token::Pod' => sub { 'POD' },

  );

  my $last_line_number = 0;

  for my $e ( $document->elements ) {

    my $line_number = $e->line_number;

    next if exists $self->{ 'line' }{ $line_number };

    $self->{ 'line' }{ $_ } = $info for $last_line_number + 1 .. $line_number - 1;

    $last_line_number = $line_number;

    my $node_type = ref $e;

    $self->{ 'line' }{ $line_number } = $info = exists $lookup{ $node_type } ? $lookup{ $node_type }->( $e ) : $package;

  }
} ## end sub index_lines

=method line_type

Call this method with a line number, it will return one of

  BEGIN CHECK UNITCHECK INIT END POD __DATA__ __END__

or

  <PackageName>::<SubName>

=cut

sub line_type { $_[ 0 ]->{ 'line' }{ $_[ 1 ] } || '' }

1;

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use PPIx::IndexLines;
  my $document = PPIx::IndexLines->new( +shift );
  $document->index_lines;
  print $document->line_type( +shift );

=head1 SEE ALSO

L<PPIx::IndexOffsets>
L<PPIx::LineToSub>

=cut
