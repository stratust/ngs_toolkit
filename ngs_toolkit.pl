#!/usr/bin/env perl
#
#              INGLÊS/ENGLISH
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  HTTP://www.gnu.org/copyleft/gpl.html
#
#  Copyright (C) 2005  Fundação Hemocentro de Ribeirão Preto
#
#  Laboratório de Bioinformática
#  BiT -  Bioinformatic Team
#  Fundação Hemocentro de Ribeirão Preto
#  Rua Tenente Catão Roxo, 2501
#  Ribeirão Preto - São Paulo
#  Brasil
#  CEP 14051-140
#  Fone: 55 16 39639300 Ramal 9603
#
#  Thiago Yukio Kikuchi Oliveira
#  stratus@lgmb.fmrp.usp.br
#  http://lgmb.fmrp.usp.br
#  
# $Id$
# 

=head1 NAME 

    MyApp

=head1 SYNOPSIS
 
 This application requires Perl 5.10.0 or higher   
 This application requires, at least, the following modules to work:

    - App::Cmd
    - Bio::FeatureIO
    - Bio::SeqIO
    - Cache::FastMmap
    - Carp
    - Data::Dumper
    - File::Basename
    - File::Temp
    - Modern::Perl
    - Moose
    - Moose::Role
    - Moose::Util::TypeConstraints
    - MooseX::FileAttribute
    - MooseX::Getopt
    - MooseX::App::Cmd
    - MooseX::SimpleConfig
    - Test::Class::Sugar
    - Venn::Chart
    - WWW::Mechanize

  Here, you want to concisely show a couple of SIMPLE use cases.  You should describe what you are doing and then write code that will run if pasted into a script.  

  For example:

  USE CASE: PRINT A LIST OF PRIMARY IDS OF RELATED FEATURES

    my $gene = new Modware::Gene( -feature_no => 4161 );

    foreach $feature ( @{ $gene->features() } ) {
       print $feature->primery_id()."\n";
    }

=head1 DESCRIPTION

   Here, AT A MINIMUM, you explain why the object exists and where it might be used.  Ideally you would be very detailed here. There is no limit on what you can write here.  Obviously, lesser used 'utility' objects will not be heavily documented.

   For example: 

   This object attempts to group together all information about a gene
   Most of this information is returned as references to arrays of other objects.  For example
   the features array is one such association.  You would use this whenever you want to read or write any 
   properties of a gene.


=head1 AUTHOR

Thiago Yukio Kikuchi Oliveira E<lt>stratus@lgmb.fmrp.usp.brE<gt>

Copyright (c) 2010 Regional Blood Center of Ribeirao Preto

=head1 LICENSE

GNU General Public License

http://www.gnu.org/copyleft/gpl.html

=head1 METHODS

=cut

###################################################################################################################
#
#   THIS SCRIPT REQUIRES SOME MODULES FROM CPAN TO WORK. TO LIST THEM PLEASE USE "perldoc <this_script_name>"
#
#   This script uses Modern Perl programing style (aka Enlightened Perl) if you don't know what it means, please
#   read the book 'Modern Perl' by chromatic (http://www.onyxneon.com/books/modern_perl/index.html).
#
#   This script use MooseX::App::Cmd (a Command Line Inteface Framework associated with Moose).
#   Please read the MooseX::App::Cmd Documentation before try to alter this script.
#
###################################################################################################################

# This is just a Main Cmd:App - don't touch

package MyApp;
    use Moose;
    use Modern::Perl;
    extends 'MooseX::App::Cmd';

    #sub default_command { 'foo' }; # Use to change de default command (help is the default)

1;
#-------------------------------------------------------------------------------------------------------
# Base Command Classes and Roles
# Usually paramereters used by ALL commands should come here (e.g. config files with software path, etc)
#-------------------------------------------------------------------------------------------------------
package MyApp::Role::BaseAttributes;
{
    use Moose::Role;
    # Working with files na directoris as attributes
    use MooseX::FileAttribute;
 
    has_file 'seq1' => (
        required      => 1,
        traits        => ['Getopt'],
        cmd_aliases   => '1',
        must_exist    => 1,
        documentation => 'Sequence file of first pair',
    );
    has_file 'seq2' => (
        required      => 0,
        traits        => ['Getopt'],
        cmd_aliases   => '2',
        must_exist    => 1,
        documentation => 'Sequence file of second pair',
    );

    has 'input_format' => (
        isa         => 'Str',
        is          => 'rw',
        required    => 0,
        traits      => ['Getopt'],
        cmd_aliases => 'f',
        default     => 'fastq',
        documentation =>
          'Sequence file(s) format (only accept Fastq for now)',
    );

    # Outpuf path for generated files
    has 'output_path' => (
        traits        => ['Getopt'],
        cmd_aliases   => 'o',
        required      => 1,
        is            => 'rw',
        isa           => 'Str',
        documentation => 'Where the output files should be placed',

    );

}
1;

package UCSC::Role;
{
    use Moose::Role;
    use Modern::Perl;
    use Carp;
    # Working with files na directoris as attributes
    use MooseX::FileAttribute;
    use WWW::Mechanize;
    use Bio::FeatureIO;
    use Cache::FastMmap;

    import MyApp::Feature::Bed;

    my $mech = WWW::Mechanize->new();
   
    my $cache_file = '/tmp/BEDcache';
   
    my $cache = Cache::FastMmap->new( expire_time => '5d', share_file => $cache_file, unlink_on_exit => 0, page_size => '20000k', compress => 1, cache_size => '100m');


    has 'genome' => (
        isa           => 'Str',
        is            => 'rw',
        required      => 1,
        documentation => 'The UCSC genome database name (e.g.: hg18, mm9, ...)',
    );

    has 'use_ucsc' => (
        isa           => 'Bool',
        is            => 'rw',
        documentation => 'Use UCSC main site to retrieve the sequences. The default URL is http://genome-mirror.bscb.cornell.edu',
    );
    
    has 'url' => (
        isa           => 'Str',
        is            => 'rw',
        documentation => 'The default URL is http://genome-mirror.bscb.cornell.edu',
        lazy_build => 1,
    );

    sub _build_url {
        my ($self) = @_;
        if ( $self->use_ucsc ) {
            return 'http://genome.ucsc.edu';
        }
        else {
            return 'http://genome-mirror.bscb.cornell.edu';
        }
    }

    sub _get_indexed_genes {
        my ($self, $type, ,$out) = @_;

        # First try to get object information from cache
        my $key_index = 'geneindex_' . $self->genome;
        my $index     = $cache->get($key_index);

        unless ($index) {
            my $kgXref = $self->_fetch_kgXref;
            my $kgEns  = $self->_fetch_knownToEnsembl;
            my $kgSymbol  = $self->_fetch_kgAlias;

            $index = $kgXref;

            # Indexing kg

            foreach my $kg ( keys %{ $kgEns->{kg} } ) {
                $index->{'kg'}->{$kg}->{'ensembl'} = $kgEns->{kg}->{$kg};
                # All kg should have an alias form kgAlias
                $index->{'kg'}->{$kg}->{'symbol'} = $kgSymbol->{kg}->{$kg} unless $index->{'kg'}->{$kg}->{'symbol'};
                $index->{'symbol'}->{$kgSymbol->{kg}->{$kg}}->{kg} = $kg if $kgSymbol->{kg}->{$kg}; 
            }

            # Indexing refseq
            foreach my $refseq ( keys %{ $kgXref->{refseq} } ) {
                my $this_kg     = $kgXref->{refseq}->{$refseq}->{kg};
                my $this_ensmbl = $index->{kg}->{$this_kg}->{ensembl};
                $index->{refseq}->{$refseq}->{'ensembl'} = $this_ensmbl;
                $index->{symbol}->{$kgSymbol->{kg}->{$this_kg}}->{refseq} = $refseq if $kgSymbol->{kg}->{$this_kg};
                $index->{'symbol'}->{$kgSymbol->{kg}->{$this_kg}}->{kg} = $this_kg if $kgSymbol->{kg}->{$this_kg}; 
            }

            #Indexing ensembl
            foreach my $ensembl ( keys %{ $kgEns->{ensembl} } ) {
                my $this_kg = $kgEns->{ensembl}->{$ensembl};
                my $symbol  = $index->{kg}->{$this_kg}->{symbol};
                my $refseq  = $index->{kg}->{$this_kg}->{refseq};

                $index->{'ensembl'}->{$ensembl}->{'kg'}     = $this_kg;
                $index->{'ensembl'}->{$ensembl}->{'symbol'} = $symbol
                  if $symbol;
                $index->{'ensembl'}->{$ensembl}->{'refseq'} = $refseq
                  if $refseq;
                $index->{symbol}->{$kgSymbol->{kg}->{$this_kg}}->{ensembl} = $ensembl if $kgSymbol->{kg}->{$this_kg};
            }
            

            $cache->set( $key_index, $index );
        }
        return $index;
    }

    sub _fetch_kgXref {
        my ($self) = @_;

        my %aux;
        my %selectedFields = (
            'hgta_fs.check.mm9.kgXref.kgID'       => 1,
            'hgta_fs.check.mm9.kgXref.geneSymbol' => 1,
            'hgta_fs.check.mm9.kgXref.refseq'     => 1,
        );

        my $file = $self->fetch_ucsc_table( 'kgXref', 'selectedFields',\%selectedFields );

        open( my $in, '<', \$file );

        while ( my $row = <$in> ) {
            next if $row =~ /^#/;
            chomp $row;
            my @f = split( /\s+/, $row );
            my ( $kg, $symbol, $refseq ) = ( $f[0], $f[1], $f[2] );
            $aux{'kg'}->{$kg} = {
                'refseq' => $refseq,
                'symbol' => $symbol,
            } if $kg;
            $aux{'refseq'}->{$refseq} = { 
                'kg' => $kg,
                'symbol' => $symbol,
            } if $refseq;
        }

        close($in);
        return \%aux;
    }

    sub _fetch_knownToEnsembl {
        my ($self) =@_;
        my $file = $self->fetch_ucsc_table('knownToEnsembl','primaryTable');

        open( my $in, '<', \$file );
        my %aux;
        while ( my $row = <$in> ) {
            next if $row =~ /^#/;
            chomp $row;
            my ( $kg, $ensembl ) = split("\t", $row); 
            $aux{'kg'}->{$kg} = $ensembl;
            
            $aux{'ensembl'}->{$ensembl} = $kg;
        }

        close($in);
        return \%aux;

    }

=head2 _fetch_kgAlias

 Title   : _fetch_kgAlias
 Usage   : _fetch_kgAlias()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub _fetch_kgAlias {
        my ($self) = @_;
        my $file = $self->fetch_ucsc_table( 'kgAlias', 'primaryTable' );

        open( my $in, '<', \$file );
        my %aux;
        while ( my $row = <$in> ) {
            next if $row =~ /^#/;
            chomp $row;
            my ($kg,$symbol) = split( /\t/, $row );
            $aux{'kg'}->{$kg} = $symbol unless $symbol eq $kg;
        }

        close($in);
        return \%aux;

    }

    
=head2 fetch_ucsc_table

 Title   : fetch_ucsc_table
 Usage   : fetch_ucsc_table()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub fetch_ucsc_table {
        my ( $self, $table_name, $format, $selected_fields ) = @_;
        
        my @formats = ('bed', 'primaryTable', 'selectedFields');
        # Permit just valid output formats
        croak "You must suply a valid format"
          unless  $format ~~ @formats ;

        my $url = $self->url . '/cgi-bin/hgTables?db=' . $self->genome;

        # Accessing URL
        $mech->get($url);
       
        my $ta;
        if ($format =~ /bed/){
            $ta = 'hgta_track';
        }
        else {
            $ta = 'hgta_table';
        }
        
        # Submitting form
        $mech->submit_form(
            form_number => 1,
            fields      => {
                db              => $self->genome,
                hgta_regionType => 'genome',
                hgta_outputType => $format, 
                $ta => $table_name,
            },
            button => 'hgta_doTopSubmit',
        );



        if ( $format =~ /bed/i ) {
            $mech->submit_form(
                form_number => 1,
                button      => 'hgta_doGetBed'
            );
        }
        elsif ($format =~/selectedFields/){
             $mech->submit_form(
                form_number => 1,                
                button      => 'hgta_doPrintSelectedFields',
                fields =>  $selected_fields,
               
            );

        }

        return $mech->content;

    }


=head2 parse_BED_file

 Title   : parse_BED_file
 Usage   : parse_BED_file( 'my_bed.txt')
 Function: 
 Returns : An Arrayref of MyApp::Feature::Bed objects
 Args    : a bed file

=cut 

    sub parse_BED_file {
        my ( $self, $bed_file, $table_name ) = @_;
        
            my @fields = (
                qw/
                  chrom
                  chromStart
                  chromEnd
                  name
                  score
                  strand
                  thickStart
                  thickEnd
                  itemRgb
                  blockCount
                  blockSizes
                  blockStarts
                  /
            );

            open( my $in, '<', $bed_file );
            
            my $index;
            
            my @tables = ('knownGene', 'ensGene', 'refGene');
            
            my %types = (
                knownGene => 'kg',
                ensGene => 'ensembl',
                refGene => 'refseq',
            );

            $index = $self->_get_indexed_genes if $table_name ~~ @tables;

            my @features;
            while ( my $row = <$in> ) {
                chomp $row;
                my @f = split( "\t", $row );
                my %aux = ( genome => $self->genome, table_name => $table_name);
                my $i = 0;                
                foreach my $value (@f) {
                    $aux{ $fields[$i] } = $value;
                    $i++;
                }
                if ($index) {
                    my $type = $types{$table_name};

                    my $symbol  = $index->{$type}->{ $f[3] }->{symbol};
                    my $refseq  = $index->{$type}->{ $f[3] }->{refseq};
                    my $kg      = $index->{$type}->{ $f[3] }->{kg};
                    my $ensembl = $index->{$type}->{ $f[3] }->{ensembl};
                    
                    if ($table_name =~ /knownGene/){
                        $aux{kg} = $f[3];
                        $aux{symbol} = $symbol if $symbol;
                        $aux{refseq} = $refseq if $refseq;
                        $aux{ensembl} = $ensembl if $ensembl;
                    }
                    if ($table_name =~ /refGene/){
                        $aux{refseq} = $f[3];
                        $aux{symbol} = $symbol if $symbol;
                        $aux{kg} = $kg if $kg;
                        $aux{ensembl} = $ensembl if $ensembl;
                    }
                    if ($table_name =~ /ensGene/){
                        $aux{ensembl} = $f[3];
                        $aux{symbol} = $symbol if $symbol;
                        $aux{refseq} = $refseq if $refseq;
                        $aux{kg} = $kg if $kg;
                    }

                }
                my $feature = MyApp::Feature::Bed->new(%aux);
                push( @features, $feature );

            }
            close($in);

           return \@features;

    }


=head2 get_ucsc_features

 Title   : get_ucsc_features
 Usage   : get_ucsc_features()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub get_ucsc_features {
        my ( $self, $table_name ) = @_;
        croak 'No track table specified!' unless ($table_name);

        # First try to get object information from cache 
        my $key_object = 'object_' . $self->genome . '_' . $table_name;
        my $object = $cache->get($key_object);
        
        # or build object again 
        unless ($object) {
            # Try to get Bed file from cache
            my $key_bed = 'bed_'.$self->genome . '_' . $table_name;
            my $bed = $cache->get($key_bed);
            
            # Or fetch BED file again and make cache
            unless ($bed) {

                $bed = $self->fetch_ucsc_table($table_name, 'bed');
                $cache->set( $key_bed, $bed );

            }

            $object = $self->parse_BED_file( \$bed, $table_name );
            # Cache object
            $cache->set( $key_object, $object );
        }

        return $object;

    }



=head2 _fetch_chrominfo

 Title   : _fetch_chrominfo
 Usage   : _fetch_chrominfo()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub _fetch_chrominfo {
        my ($self) = @_;
        my $file = $self->fetch_ucsc_table( 'chromInfo', 'primaryTable' );

        open( my $in, '<', \$file );
        my %aux;
        while ( my $row = <$in> ) {
            next if $row =~ /^#/;
            chomp $row;
            my ( $chrom, $size, $filename ) = split( /\t/, $row );
            $aux{$chrom}->{size}     = $size;
            $aux{$chrom}->{filename} = $filename;
        }

        close($in);
        return \%aux;

    }

    

=head2 get_chrominfo

 Title   : get_chrominfo
 Usage   : get_chrominfo()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub get_chrominfo {
        my ( $self ) = @_;

        # First try to get hash information from cache 
        my $key_hash = 'hash_' . $self->genome . '_chrominfo';
        my $hash = $cache->get($key_hash);
        
        # or build object again 
        unless ($hash) {
            $hash = $self->_fetch_chrominfo;
            $cache->set($key_hash,$hash);
        }

        return $hash;

     }

}
1;

package MyApp::Role::PrimerType;
{
    use Moose::Role;

    # Working with files na directoris as attributes
    use Moose::Util::TypeConstraints;
    subtype 'PrimerType' => as Str => where { $_ =~ m/[myc|igh|custom]/i } =>
      message { "You need provide a valid primer type (myc|igh|custom)!" };

    has 'primer_type' => (
        isa           => 'PrimerType',
        is            => 'rw',
        traits        => ['Getopt'],
        required      => 1,
        documentation => 'Primer Type (igh or myc or custom)',
        trigger => sub {
            my ($self) = @_;
            $self->insert_size(&_build_insert_size);
            $self->primer_chr(&_build_primer_chr);
            $self->primerF_start(&_build_primerF_start);
            $self->primerR_end(&_build_primerR_end);
          }
    );

    has 'have_insert' => (
        isa           => 'Bool',
        is            => 'ro',
        traits        => ['Getopt'],
        documentation => 'If the Reference Genome have an insert (default:0)',
    );

    has 'insert_size' => (
        isa           => 'Int',
        is            => 'rw',
        traits        => ['Getopt'],
        lazy_build    => 1,
        documentation => 'Insert size (just applied if have_insert = 1)',
    );

    has 'primer_chr' => (
        isa           => 'Str',
        is            => 'rw',
        traits        => ['Getopt'],
        lazy_build    => 1,
        documentation => 'Chromosome where primer should align',
    );

    has 'primerF_start' => (
        isa           => 'Int',
        is            => 'rw',
        traits        => ['Getopt'],
        lazy_build    => 1,
        documentation => 'Foward Primer Start position',
    );

    has 'primerR_end' => (
        isa           => 'Int',
        is            => 'rw',
        traits        => ['Getopt'],
        lazy_build    => 1,
        documentation => 'Reverse Primer End position',
    );


# METHODS SHOULD BE HERE
# =================================================================================================

=head2 _build_insert_size

 Title   : _build_insert_size
 Usage   : _build_insert_size()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub _build_insert_size {
        my ($self) = @_;
        if ( $self->have_insert ) {
            return 137 if $self->primer_type =~ /igh/i;
            return 114 if $self->primer_type =~ /myc/i;
        }
        else {
            return 0;
        }
    }

=head2 _build_primer_chr

 Title   : _build_primer_chr
 Usage   : _build_primer_chr()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub _build_primer_chr {
        my ($self) = @_;
        return 'chr12' if $self->primer_type =~ /igh/i;
        return 'chr15' if $self->primer_type =~ /myc/i;
    }

=head2 _build_primerF_start

 Title   : _build_primerF_start
 Usage   : _build_primerF_start()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub _build_primerF_start {
        my ($self) = @_;
        return 114664845 if $self->primer_type =~ /igh/i;
        return 61818182  if $self->primer_type =~ /myc/i;
    }

=head2 _build_primerR_end

 Title   : _build_primerR_end
 Usage   : _build_primerR_end()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub _build_primerR_end {
        my ($self) = @_;
        return ( 114665029 + $self->insert_size )
          if $self->primer_type =~ /igh/i;
        return ( 61818392 + $self->insert_size )
          if $self->primer_type =~ /myc/i;
    }


=head2 _set_read_size

 Title   : _set_read_size
 Usage   : _set_read_size()
 Function: 
 Returns : 
 Args    : 

=cut 

sub _set_read_size {
    my ( $self, $read ) = @_;

    my $read_size;
    
    my $size = length $read;
    
    if ( $size < 40 ) {
        $read_size = 36;
    }
    else {
        $read_size = 54;
    }
    
    return $read_size;
}


=head2 find_primer_orientation

 Title   : find_primer_orientation
 Usage   : find_primer_orientation()
 Function: 
 Returns : 
 Args    : 

=cut 

sub find_primer_orientation {

    my ($self, $line) = @_;

    my @f = split( "\t", $line );
    
    # Getting the size of read
    my $read_size = $self->_set_read_size( $f[9] );

    my ( $primerF_start, $primerR_end, $insert_size, $chr ) = (
        $self->primerF_start, $self->primerR_end,
        $self->insert_size,   $self->primer_chr
    );

    if (
        (

            # For primer as mate1
            # Primer R
            (
                   $f[2] =~ /$chr/
                && $f[3] >= ( $primerR_end - $read_size - 10 )
                && ( $f[3] + $read_size ) <= ( $primerR_end + 5 )
            )
            ||

            # For primer as mate2
            # Primer R

            (
                ( $f[6] =~ /$chr/ || ( $f[2] =~ /$chr/ && $f[6] eq '=' ) )
                && $f[7] >=
                ( $primerR_end - $read_size - 10 )

                && ( $f[7] + $read_size ) <= ( $primerR_end + 5 )
            )

        )
      )
    {
        unless ($self->primer_type =~ /igh/i) {
            return 'F';
        }
        else {
            return 'R';
        }
    }
    else {
        unless ($self->primer_type =~ /igh/i) {
            return 'R';
        }
        else {
            return 'F';
        }

    }

}


=head2 find_mate_primer

 Title   : find_mate_primer
 Usage   : find_mate_primer()
 Function: 
 Returns : 
 Args    : 

=cut 

sub find_mate_primer {
    my ($self, $line ) = @_;

    my @f = split( "\t", $line );

    my $read_size = $self->_set_read_size( $f[9] );
    my ( $primerF_start, $primerR_end, $insert_size, $chr ) = (
        $self->primerF_start, $self->primerR_end,
        $self->insert_size,   $self->primer_chr
    );

    if (

        # For primer as mate1
        # Primer R
        $f[2] =~ /$chr/
        && $f[3] >= ( $primerR_end - $read_size - 10 )
        && ( $f[3] + $read_size ) <= ( $primerR_end + 5 )
      )
    {
        return 'R1';
    }

    if (

        # For primer as mate2
        # Primer R

        ( $f[6] =~ /$chr/ || ( $f[2] =~ /$chr/ && $f[6] eq '=' ) )
        && $f[7] >=
        ( $primerR_end - $read_size - 10 )

        && ( $f[7] + $read_size ) <= ( $primerR_end + 5 )

      )
    {
        return 'R2';
    }

    if

      # Primer F Mate1
      (    $f[2] =~ /$chr/
        && $f[3] >= ( $primerF_start - 5 )
        && ( $f[3] + $read_size ) <= ( $primerF_start + $read_size + 10 ) )
    {
        return 'F1';
    }

    if (   ( $f[6] =~ /$chr/ || ( $f[2] =~ /$chr/ && $f[6] eq '=' ) )
        && $f[7] >= ( $primerF_start - 5 )
        && ( $f[7] + $read_size ) <= ( $primerF_start + $read_size + 10 ) )
    {
        return 'F2';
    }

}

}
1;

package MyApp::Base::BedTools;
{
    use Moose;
    # Working with files na directoris as attributes
    use MooseX::FileAttribute;

    has_directory 'bedtools_path' => (
        traits     => ['Getopt'],
        must_exist => 1,
        required   => 1,
        default    => sub {
            my ($self) = @_;
            die "No bedtools_path attribute specified in configfile"
              unless $self->bedtools_path;

        },
        documentation => 'Path to Bedtools binary',
    );

}
1;

package MyApp::Role::Bowtie;
{
    use Moose::Role;
    # Working with files na directoris as attributes
    use MooseX::FileAttribute;
    with 'MyApp::Role::BaseAttributes';

    has 'bowtie_threads' => (
        isa         => 'Str',
        is          => 'rw',
        default     => 2,
        documentation =>
          'Number of threads that Bowtie should use (default: 2)',
    );
    
    has 'bowtie_params' => (
        isa     => 'Str',
        is      => 'rw',
        default => \&default_bowtie_params,
        documentation =>
            'Bowtie Parameters (default: -S --best --chunkmbs 256 if paired end plus: [-fr -X 1000 ])',

    );

    has 'bowtie_genome_files' => (
        isa           => 'Str',
        is            => 'rw',
        required      => 1,
        documentation => 'Reference Genome file without extension',

    );

    has 'bowtie_unaligned_seqfile' => (
        isa      => 'Str',
        is       => 'rw',
        default  => 'unaligned.fq',
        documentation =>
          'Filename for unaligned output sequences (default: unaligned.fq)',

    );

    has 'bowtie_aligned_seqfile' => (
        isa      => 'Str',
        is       => 'rw',
        default  => 'aligned.fq',
        documentation =>
          'Filename for aligned output sequences (default: aligned.fq)',

    );

    has 'bowtie_alignment_file' => (
        isa      => 'Str',
        is       => 'rw',
        default  => 'valid_alignments.sam',
        documentation =>
          'Filename for aligment sequence (default: valid_alignments.sam)',

    );

    has_directory 'bowtie_output_path' => (
        traits     => ['Getopt'],
        is => 'rw',
        documentation => 'Path to output Bowtie files (If not define will use --ouput_path entry)',

    );

=head2 default_bowtie_params

 Title   : default_bowtie_params
 Usage   : default_bowtie_params()
 Function: 
 Returns : 
 Args    : 

=cut 

sub default_bowtie_params {
    my($self) = @_;
    if ($self->seq2){
        return ' -S --best --chunkmbs 256 -fr -X 1000 -q ';
    }
    else {
        return ' -S --best --chunkmbs 256 -q';
    }
}


=head2 run_bowtie

 Title   : run_bowtie
 Usage   : run_bowtie()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub run_bowtie {
        my($self) = @_;
        
        $self->bowtie_output_path($self->output_path) unless $self->bowtie_output_path;
        #bowtie bin
        my $bowtie_bin = "bowtie";

        # If paired end or not
        my $sequences;
        if ($self->seq2){
            $sequences = ' -1 '. $self->seq1;
            $sequences .= ' -2 '. $self->seq2; 
        }
        else {
            $sequences = $self->seq1;
        }
        
        #unalign sequences file
        my $unaligned_sequences_output =
          '--un ' . $self->bowtie_output_path . '/'. $self->bowtie_unaligned_seqfile;

        #align sequences file
        my $aligned_sequences_output =
          '--al ' . $self->bowtie_output_path . '/'. $self->bowtie_aligned_seqfile;

        # Sam file
        my $sam_alignment_output =
          $self->bowtie_output_path . '/' . $self->bowtie_alignment_file;
        
        # Create command string
        my $bowtie_cmd_string =
            $bowtie_bin . ' '
          . $self->bowtie_params . ' -p '
          . $self->bowtie_threads . ' '
          . $self->bowtie_genome_files . ' '
          . $sequences . ' '
          . $unaligned_sequences_output . ' '
          . $aligned_sequences_output . ' '
          . $sam_alignment_output;

        # Show command string
        print "Running Command:\n";
        print $bowtie_cmd_string. "\n";

        # Run command
        system( 'time ' . $bowtie_cmd_string )
          && die "Could not execute :'" . $bowtie_cmd_string . "'\n";

    }

}
1;

package MyApp::Base::Bowtie;
{
    use Moose;
    # Working with files na directoris as attributes
    use MooseX::FileAttribute;
    with 'MyApp::Role::BaseAttributes', 'MyApp::Role::Bowtie';

=head2 run_bowtie

 Title   : run_bowtie
 Usage   : run_bowtie()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub run_bowtie {
        my($self) = @_;
        
        $self->bowtie_output_path($self->output_path) unless $self->bowtie_output_path;
        #bowtie bin
        my $bowtie_bin = "bowtie";

        # If paired end or not
        my $sequences;
        if ($self->seq2){
            $sequences = ' -1 '. $self->seq1;
            $sequences .= ' -2 '. $self->seq2; 
        }
        else {
            $sequences = $self->seq1;
        }
        
        #unalign sequences file
        my $unaligned_sequences_output =
          '--un ' . $self->bowtie_output_path . '/'. $self->bowtie_unaligned_seqfile;

        #align sequences file
        my $aligned_sequences_output =
          '--al ' . $self->bowtie_output_path . '/'. $self->bowtie_aligned_seqfile;

        # Sam file
        my $sam_alignment_output =
          $self->bowtie_output_path . '/' . $self->bowtie_alignment_file;
        
        # Create command string
        my $bowtie_cmd_string =
            $bowtie_bin . ' -p '
          . $self->bowtie_threads . ' '
          . $self->bowtie_params . ' '
          . $self->bowtie_genome_files . ' '
          . $sequences . ' '
          . $unaligned_sequences_output . ' '
          . $aligned_sequences_output . ' '
          . $sam_alignment_output;

        # Show command string
        print "Running Command:\n";
        print $bowtie_cmd_string. "\n";

        # Run command
        system( 'time ' . $bowtie_cmd_string )
          && die "Could not execute :'" . $bowtie_cmd_string . "'\n";

    }

}
1;

package MyApp::Base::Samtools;
{
    use Moose;
    # Working with files na directoris as attributes
    use MooseX::FileAttribute;

    has_directory 'samtools_path' => (
        traits     => ['Getopt'],
        must_exist => 1,
        required   => 1,
        default    => sub {
            my ($self) = @_;
            die "No samtools_path attribute specified in configfile"
              unless $self->samtools_path;

        }
    );

}
1;

package MyApp::Base::Config;
{
    use Moose;

# A Moose role for setting attributes from a simple configfile
# It uses Config:Any so it can handle many formats (YAML, Apace, JSON, XML, etc..)
    with 'MooseX::SimpleConfig';

    # Extends Base classes
#    extends  'MyApp::Base::Bowtie';
#      'MyApp::Base::BedTools',
#      'MyApp::Base::Samtools';

    # Control the '--configfile' option
    has '+configfile' => (
        traits      => ['Getopt'],
        cmd_aliases => 'c',
        isa         => 'Str',
        is          => 'rw',
        required    => 1,
        documentation =>
'Configuration file (accept the following formats: YAML, CONF, XML, JSON, etc)',
    );

# Class attributes (program options - MooseX::Getopt)
# traits => ['NoGetopt'] remove the attribute from the list in help command (all values will be filled by the config file)
# the above behavior can be achieved using an underscore in the begining of a attribute.

    # Not showing attributes as Getopt (they should be in confifile)
#    has '+bedtools_path' => ( traits => ['NoGetopt'] );

    #    has '+bowtie_path'   => ( traits => ['NoGetopt'] );
#    has '+samtools_path' => ( traits => ['NoGetopt'] );

}
1;

package MyApp::Feature::Bed;
{
    use Moose;
    use Modern::Perl;
    use Cache::FastMmap;
    with 'UCSC::Role';
    my $cache_file = '/tmp/BEDcache';

    my  $cache = Cache::FastMmap->new( expire_time => '5d', share_file => $cache_file, unlink_on_exit => 0, page_size => '20000k', compress => 1, cache_size => '100m');

    my %Xref_tables = (
        knownGene => 'kg',
        refgene => 'kg',
        knownGene => 'kg',
    );


    # BED Fields
    has 'chrom'       => ( is => 'ro', isa => 'Str', required => 1 );
    has 'chromStart'  => ( is => 'ro', isa => 'Int', required => 1 );
    has 'chromEnd'      => ( is => 'ro', isa => 'Int', required => 1 );
    has 'name'        => ( is => 'ro', isa => 'Str' );
    has 'score'       => ( is => 'ro', isa => 'Int' );
    has 'strand'      => ( is => 'ro', isa => 'Str' );
    has 'thickStart'  => ( is => 'ro', isa => 'Int' );
    has 'thickEnd'    => ( is => 'ro', isa => 'Int' );
    has 'itemRgb'     => ( is => 'ro', isa => 'Str' );
    has 'blockCount'  => ( is => 'ro', isa => 'Str' );
    has 'blockSizes'  => ( is => 'ro', isa => 'Str' );
    has 'blockStarts' => ( is => 'ro', isa => 'Str' );

    # Attributes used to get gene names 
    has 'genome' =>  ( is => 'ro', isa => 'Str', required => 1 );

    has 'table_name' => ( is => 'ro', isa => 'Str', );
    has 'symbol'     => ( is => 'rw', isa => 'Str', );
    has 'refseq'     => ( is => 'rw', isa => 'Str', );
    has 'ensembl'    => ( is => 'rw', isa => 'Str', );
    has 'kg'         => ( is => 'rw', isa => 'Str', );


    sub _build_gene_merged {
        my ($self) = @_;
        my $index = $self->_get_indexed_genes;
        if ( $self->table_name =~ /knownGene/ ) {
            $self->symbol( $index->{kg}->{ $self->name }->{symbol} ) if ( $index->{kg}->{ $self->name }->{symbol} ) ;
            $self->refseq( $index->{kg}->{ $self->name }->{refseq} ) if ( $index->{kg}->{ $self->name }->{refseq} ) ;
            $self->ensembl( $index->{kg}->{ $self->name }->{ensembl} ) if ( $index->{kg}->{ $self->name }->{ensembl} );
            $self->kg( $self->name );
        }
        elsif ( $self->table_name =~ /refGene/ ){
            $self->symbol( $index->{refseq}->{ $self->name }->{symbol} )
              if ( $index->{refseq}->{ $self->name }->{symbol} );
            $self->kg( $index->{refseq}->{ $self->name }->{kg} )
              if ( $index->{refseq}->{ $self->name }->{kg} );
            $self->ensembl( $index->{refseq}->{ $self->name }->{ensembl} )
              if ( $index->{refseq}->{ $self->name }->{ensembl} );
            $self->refseq( $self->name );

        }
        elsif ( $self->table_name =~ /ensGene/ ){
            $self->symbol( $index->{ensembl}->{ $self->name }->{symbol} ) if ( $index->{ensembl}->{ $self->name }->{symbol} );
            $self->refseq( $index->{ensembl}->{ $self->name }->{refseq} ) if ( $index->{ensembl}->{ $self->name }->{refseq} );
            $self->kg( $index->{ensembl}->{ $self->name }->{kg} ) if ( $index->{ensembl}->{ $self->name }->{kg} );
            $self->ensembl( $self->name );
                        
        }

    } 
    



}
1;



#-------------------------------------------------------------------------------------------------------
# Base Classes that can be used without command inteface
#-------------------------------------------------------------------------------------------------------

# Class remove_barcode
package RemoveBarcode;
{
    use Moose;
    # Working with files and directories as attributes
    use MooseX::FileAttribute;
    use File::Basename;
    with 'MyApp::Role::BaseAttributes';    
    # Special Modules used by this class    
    use Bio::SeqIO;
    
    has '+seq2' => ( required => 1 );

    # Class attributes (program options - MooseX::Getopt)
    has 'barcode' => (
        isa           => 'Str',
        is            => 'rw',
        required      => 0,
        traits        => ['Getopt'],
        cmd_aliases   => 'b',
        default       => 'CGCGCCT',
        documentation => 'The barcode sequence (default: CGCGCCT)',
    );
  
    has 'bioperl' => (
        isa           => 'Bool',
        is            => 'rw',
        required      => 0,
        default     => 0,
        traits        => ['Getopt'],
        documentation => 'Boolean. Use the Bio::SeqIO::fastq to parse files. Should be slow. (default: 0)',
    );
  
    has 'exact_match' => (
        isa           => 'Bool',
        is            => 'rw',
        required      => 0,
        default     => 0,
        traits        => ['Getopt'],
        documentation => 'Exact Match the barcode. (default: 0)',
    );
  
    # Make main attribute output_path required
    has '+output_path' => (
        required      => 1,

    );

    # METHODS SHOULD BE HERE
    # =================================================================================================

=head2 index_barcode_string

 Title   : index_barcode_string
 Usage   : index_barcode_string()
 Function: Given a sequence (barcode) generate all possible regex strings with wildcards
 Returns : An array with all regular expressions of barcode
 Args    : none

=cut 

    sub index_barcode_string {
        my ($self) = @_;

        my @index;
        my $bc    = $self->barcode;
        my $rv_bc = $bc;

        #translate
        $rv_bc =~ tr/[ATCGatcg]/[TAGCtagc]/;

        #reverse
        $rv_bc = reverse $rv_bc;

        my @barcode = split( '', $bc );

        # Using Wildcards
        for ( my $i = 0 ; $i <= $#barcode ; $i++ ) {
            my @aux         = split( '', $bc );
            my @aux_reverse = split( '', $rv_bc );
            $aux[$i]         = "[ATCGnatcgn\.]";
            $aux_reverse[$i] = "[ATCGNatcgn\.]";
            my $regex         = join( '', @aux );
            my $regex_reverse = join( '', @aux_reverse );

            push( @index, qr/$regex/ );
            push( @index, qr/$regex_reverse/ );

            # A maxium of 1 indels before plus a mismatch
            push( @index, qr/[ATCGNatcgn\.]{1,1}$regex/ );
            push( @index, qr/[ATCGNatcgn\.]{1,1}$regex_reverse/ );

        }

        # Emulate a maximum of 1 indels after
        substr( $bc, 0, 1 ) = '';
        push( @index, qr/$bc/ );

        # reverse
        substr( $rv_bc, 0, 1 ) = '';
        push( @index, qr/$rv_bc/ );

        return @index;

    }

=head2 filter_fastq

 Title   : filter_fastq
 Usage   : filter_fastq()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub filter_fastq {
        my ($self) = @_;

        # path where generated files will be send
        my $path_out = $self->output_path;

        # grabs the FASTQ parser, specifies the Illumina variant
        my $in1 = Bio::SeqIO->new(
            -format => 'fastq-illumina',
            -file   => $self->seq1,
        );

        my $in2 = Bio::SeqIO->new(
            -format => 'fastq-illumina',
            -file   => $self->seq2,
        );

        mkdir "$path_out" unless ( -e "$path_out" );

        # Create object Bio::SeqIO to write new files
        my $out1 = Bio::SeqIO->new(
            -format => 'fastq-illumina',
            -file   => ">$path_out/"
              . basename( $self->seq1 )
              . ".barcode_matched",
            -quality_header => 1,
        );

        my $out2 = Bio::SeqIO->new(
            -format => 'fastq-illumina',
            -file   => ">$path_out/"
              . basename( $self->seq2 )
              . ".barcode_matched",
            -quality_header => 1,

        );

        # Get barcode regex
        my @index = $self->index_barcode_string();

        my $total_seq                = 0;
        my $total_match              = 0;
        my $total_match_file1        = 0;
        my $total_match_file2        = 0;
        my $total_nomatch            = 0;
        my $total_duplicated_barcode = 0;

        while ( my $seq1 = $in1->next_seq ) {

            # Get the second file seq;
            my $seq2 = $in2->next_seq;

            # Making IDs became identical
            $seq1->display_id( $self->strip_id( $seq1->display_id ) );
            $seq2->display_id( $self->strip_id( $seq2->display_id ) );

            # Initialize match counter;
            my $c_match = 0;

            my $seq1_truncated;
            foreach my $regex (@index) {
                if ( $seq1->seq =~ m/^$regex/i ) {

                    #triming the barcode
                    $seq1_truncated = $seq1->trunc( $+[0] + 1, $seq1->length );

                    $c_match++;
                    last;
                }
            }

            my $seq2_truncated;
            foreach my $regex (@index) {
                if ( $seq2->seq =~ m/^$regex/i ) {

                    #triming the barcode
                    $seq2_truncated = $seq2->trunc( $+[0] + 1, $seq2->length );

                    $c_match++;
                    last;
                }
            }

            if ( $c_match == 1 ) {
                if ( defined $seq1_truncated ) {
                    $out1->write_seq($seq1_truncated);
                    $total_match_file1++;
                }
                else {
                    $out1->write_seq($seq1);
                }

                if ( defined $seq2_truncated ) {
                    $out2->write_seq($seq2_truncated);
                    $total_match_file2++;
                }
                else {
                    $out2->write_seq($seq2);
                }

                #count match
                $total_match++;
            }
            elsif ( $c_match < 1 ) {
                $total_nomatch++;
            }
            else {
                $total_duplicated_barcode++;
            }

            $total_seq++;
        }

        # output informations
        open( my $out_info, ">", "$path_out/barcode_filter_info.txt" );

        print $out_info "Filter Information\n";
        print $out_info
          "-------------------------------------------------------------\n\n";
        print $out_info "Total of sequences:            $total_seq\n";
        print $out_info "Total of matched sequences:    $total_match\n";
        print $out_info "Total of matched seq file1:    $total_match_file1\n";
        print $out_info "Total of matched seq file2:    $total_match_file2\n";
        print $out_info "Total of nomatched sequence:   $total_nomatch\n";
        print $out_info
          "Total of duplicated barcode:   $total_duplicated_barcode\n";
        print $out_info
          "-------------------------------------------------------------\n";

        close($out_info);

        # Print in the screen
        print "Filter Information\n";
        print
          "-------------------------------------------------------------\n\n";
        print "Total of sequences:            $total_seq\n";
        print "Total of matched sequences:    $total_match\n";
        print "Total of matched seq file1:    $total_match_file1\n";
        print "Total of matched seq file2:    $total_match_file2\n";
        print "Total of nomatched sequence:   $total_nomatch\n";
        print "Total of duplicated barcode:   $total_duplicated_barcode\n";
        print "-------------------------------------------------------------\n";

    }

=head2 filter_fastq_nobioperl

 Title   : filter_fastq_nobioperl
 Usage   : filter_fastq_nobioperl()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub filter_fastq_nobioperl {
        my ($self) = @_;

        # path where generated files will be send
        my $path_out = $self->output_path;

        # Open FASTQ files
        open( my $in1, "<", $self->seq1 );

        open( my $in2, "<", $self->seq2 );

        mkdir "$path_out" unless ( -e "$path_out" );

        # Create output file handles to write new files
        open( my $out1, ">",
            "$path_out/" . basename( $self->seq1 ) . ".barcode_matched" );
        open( my $out2, ">",
            "$path_out/" . basename( $self->seq2 ) . ".barcode_matched" );

        # Get barcode regex
        my @index = $self->index_barcode_string();
        my $barcode = $self->barcode;

        my $total_seq                = 0;
        my $total_match              = 0;
        my $total_match_file1        = 0;
        my $total_match_file2        = 0;
        my $total_nomatch            = 0;
        my $total_duplicated_barcode = 0;

        local $/ = "@";
        while ( my $seq1 = <$in1> ) {

            # Get the second file seq;
            $/ = "@";
            my $seq2 = <$in2>;

            next if $seq1 =~ /^\@/;

            $seq1 =~ s/\@$//;
            $seq2 =~ s/\@$//;

            # Making IDs became identical
            my $id1;
            $id1 = $1 if ( $seq1 =~ /^(\S+)\n/ );
            my $id1_strip = $self->strip_id($id1);
            $seq1 =~ s/$id1/$id1_strip/g;

            my $id2;
            $id2 = $1 if ( $seq2 =~ /^(\S+)\n/ );
            my $id2_strip = $self->strip_id($id2);
            $seq2 =~ s/$id2/$id2_strip/g;

            # Initialize match counter;
            my $c_match        = 0;
            my $seq1_truncated = 0;

            my ( $sid1, $sequence1, $quality1 );
            ( $sid1, $sequence1, $quality1 ) = ( $1, $2, $3 )
              if ( $seq1 =~ /^(\S+)\n(\S+)\n\S+\n(\S+)\n/ );

            if ( $self->exact_match ) {
                if ( $sequence1 =~ m/^$barcode/i ) {
                    my $seq_truncated = substr $sequence1, $+[0],
                      length $sequence1;
                    my $qual_truncated = substr $quality1, $+[0],
                      length $quality1;
                    $seq1 = "$sid1\n$seq_truncated\n\+$sid1\n$qual_truncated\n";

                    #$seq1 =~ s/\Q$sequence\E/\Q$seq_truncated\E/;
                    #$seq1 =~ s/\Q$quality\E/\Q$qual_truncated\E/;

                    $seq1_truncated = 1;
                    $c_match++;
                }

            }
            else {
                foreach my $regex (@index) {

                    if ( $sequence1 =~ m/^$regex/i ) {
                        my $seq_truncated = substr $sequence1, $+[0],
                          length $sequence1;
                        my $qual_truncated = substr $quality1, $+[0],
                          length $quality1;
                        $seq1 =
                          "$sid1\n$seq_truncated\n\+$sid1\n$qual_truncated\n";

                        #$seq1 =~ s/\Q$sequence\E/\Q$seq_truncated\E/;
                        #$seq1 =~ s/\Q$quality\E/\Q$qual_truncated\E/;

                        $seq1_truncated = 1;
                        $c_match++;
                        last;
                    }
                }
            }
            my $seq2_truncated = 0;

            my ( $sid2, $sequence2, $quality2 );
            ( $sid2, $sequence2, $quality2 ) = ( $1, $2, $3 )
              if ( $seq2 =~ /^(\S+)\n(\S+)\n\S+\n(\S+)\n/ );

            if ( $self->exact_match ) {
                    if ( $sequence2 =~ m/^$barcode/i ) {
                        my $seq_truncated = substr $sequence2, $+[0],
                          length $sequence2;
                        my $qual_truncated = substr $quality2, $+[0],
                          length $quality2;

                        $seq2 =
                          "$sid2\n$seq_truncated\n\+$sid2\n$qual_truncated\n";

                        #$seq2 =~ s/\Q$sequence\E/\Q$seq_truncated\E/;
                        #$seq2 =~ s/\Q$quality\E/\Q$qual_truncated\E/;

                        $seq2_truncated = 1;

                        $c_match++;
                    }

            }
            else {

                #        exit if $total_seq == 4;
                foreach my $regex (@index) {
                    if ( $sequence2 =~ m/^$regex/i ) {
                        my $seq_truncated = substr $sequence2, $+[0],
                          length $sequence2;
                        my $qual_truncated = substr $quality2, $+[0],
                          length $quality2;

                        $seq2 =
                          "$sid2\n$seq_truncated\n\+$sid2\n$qual_truncated\n";

                        #$seq2 =~ s/\Q$sequence\E/\Q$seq_truncated\E/;
                        #$seq2 =~ s/\Q$quality\E/\Q$qual_truncated\E/;

                        $seq2_truncated = 1;

                        $c_match++;
                        last;
                    }
                }
            }

            if ( $c_match == 1 ) {
                if ($seq1_truncated) {
                    $total_match_file1++;
                }
                print $out1 '@' . $seq1;

                if ($seq2_truncated) {
                    $total_match_file2++;
                }

                print $out2 '@' . $seq2;

                #count match
                $total_match++;
            }
            elsif ( $c_match < 1 ) {
                $total_nomatch++;
            }
            else {
                $total_duplicated_barcode++;
            }

            $total_seq++;
        }

        # output informations
        open( my $out_info, ">", "$path_out/barcode_filter_info.txt" );

        print $out_info "Filter Information\n";
        print $out_info
          "-------------------------------------------------------------\n\n";
        print $out_info "Exact Match:                   ".$self->exact_match."\n";
        print $out_info "Total of sequences:            $total_seq\n";
        print $out_info "Total of matched sequences:    $total_match\n";
        print $out_info "Total of matched seq file1:    $total_match_file1\n";
        print $out_info "Total of matched seq file2:    $total_match_file2\n";
        print $out_info "Total of nomatched sequence:   $total_nomatch\n";
        print $out_info
          "Total of duplicated barcode:   $total_duplicated_barcode\n";
        print $out_info
          "-------------------------------------------------------------\n";

        close($out_info);

        # Print in the screen
        print "Filter Information\n";
        print
          "-------------------------------------------------------------\n\n";
        print "Exact Match:                   ".$self->exact_match."\n";
        print "Total of sequences:            $total_seq\n";
        print "Total of matched sequences:    $total_match\n";
        print "Total of matched seq file1:    $total_match_file1\n";
        print "Total of matched seq file2:    $total_match_file2\n";
        print "Total of nomatched sequence:   $total_nomatch\n";
        print "Total of duplicated barcode:   $total_duplicated_barcode\n";
        print "-------------------------------------------------------------\n";

    }

=head2 strip_id

 Title   : strip_id
 Usage   : strip_id()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub strip_id {
        my ( $self, $display_id ) = @_;
        $display_id =~ s/_read_\d//g;
        $display_id =~ s/\/\d$/\//g;
        return $display_id;
    }
   
}
1;

package Search::Rearranged::Pairs;
{
    use Moose;
 
    # Working with files and directories as attributes
    use MooseX::FileAttribute;
    use File::Basename;
    
    with 'MyApp::Role::PrimerType';

    # Class attributes (program options - MooseX::Getopt)
    has_file 'input' => (
        required      => 1,
        traits        => ['Getopt'],
        must_exist => 1,
        documentation => 'Input file in SAM format (All sequences should be aggrouped in pairs)',
    );
    
    # Make main attribute output_path required
    has_directory 'output_path' => (
        is            => 'rw',
        required      => 1,
        traits        => ['Getopt'],
        documentation => 'Output Path',

    );

# METHODS SHOULD BE HERE
# =================================================================================================

=head2 search_rearranged_pairs

 Title   : search_rearranged_pairs
 Usage   : search_rearranged_pairs()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub search_rearranged_pairs {
        my ($self) = @_;
        
        my $dir_name      = $self->output_path;

        my $print_next = 0;
        my $invalid    = 0;

        open( my $in, '<', $self->input );

        open( my $sam, '>', $dir_name . '/translocated_pairs.sam' );

        open( my $sam_invalid, '>', $dir_name . '/invalid_pairs.sam' );

        open( my $out, '>', $dir_name . '/info.txt' );

        my $total_pairs              = 0;
        my $total_nomapped_pairs     = 0;
        my $total_translocated_pairs = 0;
        my $total_invalid_pairs      = 0;

        while ( my $line = <$in> ) {

            if ( $line =~ /^@/ ) {
                print $sam $line;
                next;
            }

            $total_pairs++;

            my @f = split( "\t", $line );

            if ( $f[2] =~ /\*/ || $f[6] =~ /\*/ ) {
                $total_nomapped_pairs++;
                next;
            }

            if ($print_next) {
                $print_next = 0;
                print $sam $line;
                $total_translocated_pairs++;
            }
            elsif ($invalid) {
                $invalid = 0;
                $total_invalid_pairs++;
                print $sam_invalid $line;
                next;
            }
            else {
                my $read_size;
                my $read = length $f[9];
                if ( $read < 40 ) {
                    $read_size = 36;
                }
                else {
                    $read_size = 59;
                }

                my ( $primerF_start, $primerR_end, $chr ) = ($self->primerF_start, $self->primerR_end, $self->primer_chr);

                if (
                    (

                        # For primer as mate1
                        # igH Primer R
                        (
                               $f[2] =~ /$chr/
                            && $f[3] >= ( $primerR_end - $read_size - 10 )
                            && ( $f[3] + $read_size ) <= ( $primerR_end + 5 )
                        )
                        ||

                        # igH Primer F
                        (
                               $f[2] =~ /$chr/
                            && $f[3] >= ( $primerF_start - 5 )
                            && ( $f[3] + $read_size ) <=
                            ( $primerF_start + $read_size + 10 )
                        )
                    )
                    ||

                    # For primer as mate2
                    # igH Primer R
                    (
                        (
                            (
                                $f[6] =~ /$chr/
                                || ( $f[2] =~ /$chr/ && $f[6] eq '=' )
                            )
                            && $f[7] >=
                            ( $primerR_end - $read_size - 10 )

                            && ( $f[7] + $read_size ) <= ( $primerR_end + 5 )
                        )
                        ||

                        # igH Primer F
                        (
                            (
                                $f[6] =~ /$chr/
                                || ( $f[2] =~ /$chr/ && $f[6] eq '=' )
                            )
                            && $f[7] >= ( $primerF_start - 5 )
                            && ( $f[7] + $read_size ) <=
                            ( $primerF_start + $read_size + 10 )
                        )
                    )
                  )
                {
                    $print_next = 1;
                    $total_translocated_pairs++;
                    print $sam $line;
                }
                else {
                    $total_invalid_pairs++;
                    $invalid = 1;
                    print $sam_invalid $line;
                }

            }
        }
        close($sam);

        print $out "  Filter Summary\n";
        print $out
          "--------------------------------------------------------------\n";
        print $out "Total of pairs:                  "
          . ( $total_pairs / 2 ) . "\n";
        print $out "Total of nonmapped pairs:        "
          . ( $total_nomapped_pairs / 2 ) . "\n";
        print $out "Total of invalid pairs:          "
          . ( $total_invalid_pairs / 2 ) . "\n";
        print $out "Total of translocated pairs:     "
          . ( $total_translocated_pairs / 2 ) . "\n";
        print $out
          "--------------------------------------------------------------\n";
        print $out " Filter Attributes\n";
        print $out
          "--------------------------------------------------------------\n";
        print $out "Primer Chromossome:              "
          . ( $self->primer_chr ) . "\n";
        print $out "PrimerF Start:                   "
          . ( $self->primerF_start ) . "\n";
        print $out "PrimerR End:                     "
          . ( $self->primerR_end ) . "\n";
        print $out "Insert Size:                     "
          . ( $self->insert_size ) . "\n";
        print $out
          "--------------------------------------------------------------\n";
        close($out);

        print "  Filter Summary\n";
        print
          "--------------------------------------------------------------\n";
        print "Total of pairs:                  " . ( $total_pairs / 2 ) . "\n";
        print "Total of nonmapped pairs:        "
          . ( $total_nomapped_pairs / 2 ) . "\n";
        print "Total of invalid pairs:          "
          . ( $total_invalid_pairs / 2 ) . "\n";
        print "Total of translocated pairs:     "
          . ( $total_translocated_pairs / 2 ) . "\n";
        print
          "--------------------------------------------------------------\n";
        print  " Filter Attributes\n";
        print 
          "--------------------------------------------------------------\n";
        print  "Primer Chromossome:              "
          . ( $self->primer_chr ) . "\n";
        print  "PrimerF Start:                   "
          . ( $self->primerF_start ) . "\n";
        print  "PrimerR End:                     "
          . ( $self->primerR_end ) . "\n";
        print  "Insert Size:                     "
          . ( $self->insert_size ) . "\n";
        print 
          "--------------------------------------------------------------\n";

    }

}
1;

package Cluster::Translocations;
{
    use Moose;
 
    # Working with files and directories as attributes
    use MooseX::FileAttribute;
    use File::Basename;
    with 'MyApp::Role::PrimerType';
    use Data::Dumper;

    # Class attributes (program options - MooseX::Getopt)
    has_file 'input' => (
        required      => 1,
        traits        => ['Getopt'],
        must_exist => 1,
        documentation => 'Input file in SAM format (All sequences should be aggrouped in pairs)',
    );
    
    # Make main attribute output_path required
    has_directory 'output_path' => (
        is            => 'rw',
        required      => 1,
        traits        => ['Getopt'],
        documentation => 'Output Path',
    );

    has 'cluster_cutoff' => (
        is            => 'rw',
        isa  => 'Int',
        required      => 1,
        traits        => ['Getopt'],
        documentation => 'Report only cluster with hits higher than this value',
    );

# METHODS SHOULD BE HERE
# =================================================================================================


=head2 cluster_translocations

 Title   : cluster_translocations
 Usage   : cluster_translocations()
 Function: 
 Returns : 
 Args    : 

=cut 

sub cluster_translocations {

    my($self) = @_;
    
    open( my $in, '<', $self->input );
    
    open( my $out, '>', $self->output_path . "/cluster_translocated_pairs.sam" );

    open( my $info, '>', $self->output_path . "/info.txt" );

    my %unique;
    
    my $number_of_pairs;
    my $number_of_pairs_without_primers;
    
    while ( my $pair_1 = <$in> ) {
    
        if ( $pair_1 =~ /^\@/ ) {
        
            print $out $pair_1;
            next;

        }

        $number_of_pairs++;

        my $pair_2 = <$in>;

        my ( $id1, $flag1, $chr_1, $pos_read1, $maq1, $cirgar1, $chr_mate1,
            $pos_mate1 )
          = split( "\t", $pair_1 );
        my ( $id2, $flag2, $chr_2, $pos_read2, $maq2, $cirgar2, $chr_mate2,
            $pos_mate2 )
          = split( "\t", $pair_2 );
        
        #Skip sequences with both pairs in the same strand
        my $o1;
        if ( $flag1 & 16 ) {
            $o1 = "R";
        }
        else {
            $o1 = "F";
        }
         my $o2;
        if ( $flag2 & 16 ) {
            $o2 = "R";
        }
        else {
            $o2 = "F";
        }
        # Skip R and R and F and F sequences
        # PS: can't do that because rearrangements can allow RR and FF
        #next if $o1 eq $o2;

        # Find primer (F or R) and mate who have the primer (1 or 2);
        my $mate_primer = $self->find_mate_primer($pair_1);
        
        my $key;
        # If the primer is on  first mate
        if ($mate_primer =~ m/1/){
#            $key = "$flag1|$flag2|$chr_2|$pos_read2";
            $key = "$o2|$chr_2|$pos_read2";
        }

        # If the primer is on  second  mate
        elsif ( $mate_primer =~ m/2/){
            #           $key = "$flag2|$flag1|$chr_1|$pos_read1";
            $key = "$o1|$chr_1|$pos_read1";
        }
        # Or no primer found
        else{
            next;        
        }

        if ( defined $unique{$key} ) {
            $unique{$key}{count}++;
            push(@{$unique{$key}{others_alignments}},$pair_1.$pair_2);
        }
        else {

            $unique{$key}{alignment} = $pair_1 . $pair_2;
            $unique{$key}{count}++;
            $unique{$key}{primer} = $self->find_primer_orientation( $pair_1 );

        }

    }

    my $i;
    foreach my $key ( keys %unique ) {
        my $count = $unique{$key}{count};
        next if $count <= $self->cluster_cutoff;
        $i++;
        my $alignment = $unique{$key}{alignment};
        my $pair_id;
        $pair_id = $1 if $alignment =~ /^(\S+)\t/;

        my $primer = $unique{$key}{primer};
        my $new_id = "pair" . $i . "_c" . $count . "_" . $primer;
        $alignment =~ s/$pair_id/$new_id/g;

        print $out $alignment;

    }
    close($out);
 
    my $number_of_clusters = $i;
        
    $number_of_clusters = 0 unless $number_of_clusters;
    $number_of_pairs    = 0 unless $number_of_pairs;

    print $info "  Filter Information\n";
    print $info
      "--------------------------------------------------------------\n";
    print $info "Total of pairs:           " . $number_of_pairs . "\n";
    print $info "Total of clusters:        " . $number_of_clusters . "\n";
    print $info "Cut-off:                  >" . $self->cluster_cutoff . "\n";
    print $info
      "--------------------------------------------------------------\n";
    print $info Dumper(%unique);
    close($info);

    print "  Filter Information\n";
    print "--------------------------------------------------------------\n";
    print "Total of pairs:           " . $number_of_pairs . "\n";
    print "Total of clusters:        " . $number_of_clusters . "\n";
    print "Cut-off:                  >" . $self->cluster_cutoff . "\n";
    print "--------------------------------------------------------------\n";


}


}
1;

package Split::Clusters::Chrs;
{
    use Moose;

    # Working with files and directories as attributes
    use MooseX::FileAttribute;
    use File::Basename;
    with 'MyApp::Role::PrimerType', 'UCSC::Role';

    # Class attributes (program options - MooseX::Getopt)
    has_file 'input' => (
        required   => 1,
        traits     => ['Getopt'],
        must_exist => 1,
        documentation =>
'Input file of clusters in SAM format (All sequences should be aggrouped in pairs)',
    );

    # Make main attribute output_path required
    has_directory 'output_path' => (
        is            => 'rw',
        required      => 1,
        traits        => ['Getopt'],
        documentation => 'Output Path',
    );

# METHODS SHOULD BE HERE
# =================================================================================================

=head2 split_clusters_by_chrs

 Title   : split_clusters_by_chrs
 Usage   : split_clusters_by_chrs()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub split_clusters_by_chrs {
        my ($self) = @_;
        open( my $in, '<', $self->input );
        open( my $sam_out, '>', $self->output_path.'/cluster_partner.sam' );


        my %read;
        my $number_of_pairs;
        while ( my $pair_1 = <$in> ) {
            if ( $pair_1 =~ /^\@/ ) {
                print $sam_out $pair_1;
                next;
            }
            $number_of_pairs++;

            my $pair_2 = <$in>;

            my ( $id1, $flag1, $chr_1, $pos_read1, $maq1, $cirgar1, $chr_mate1,
                $pos_mate1 )
              = split( "\t", $pair_1 );
            my ( $id2, $flag2, $chr_2, $pos_read2, $maq2, $cirgar2, $chr_mate2,
                $pos_mate2 )
              = split( "\t", $pair_2 );

            # Find primer (F or R) and mate who have the primer (1 or 2);
            
            #           $self->primer_type('igh');
            my $mate_primer = $self->find_mate_primer($pair_1);

            #unless ($mate_primer){
            #    $self->primer_type('myc');
            #    $mate_primer = $self->find_mate_primer($pair_1);
            #}
            
            my $key;
            my $alignment;
            if ( $mate_primer =~ m/1/ ) {
                my %hash;
                $hash{id}  = $id1;
                $hash{pos} = $pos_read2;
                push( @{ $read{$chr_2} }, \%hash );
                print $sam_out  $pair_2;
            }
            elsif ($mate_primer =~ m/2/) {
                my %hash;
                $hash{id}  = $id1;
                $hash{pos} = $pos_read1;
                push( @{ $read{$chr_1} }, \%hash );
                print $sam_out  $pair_1;
            }
            else{
                die "Could not find Mate Primer!";
            }

        }
        close($in);
        close($sam_out);
        my %chr_number;

        foreach my $key ( keys %read ) {

            open( my $out, '>', $self->output_path . "/$key.txt" );

            foreach my $entry ( @{ $read{$key} } ) {
                $chr_number{$key}++;
                print $out "$key\t$entry->{id}\t$entry->{pos}\n";
            }
            close($out);
        }

        open( my $info, '>', $self->output_path . "/info.stats" );

        my $chrominfo = $self->get_chrominfo();

        my @chr_names;

        foreach my $chrm ( keys %{$chrominfo} ) {
            push( @chr_names, $chrm ) if $chrm !~ /random/;
        }

        foreach my $key (@chr_names) {
            $chr_number{$key} = 0 unless $chr_number{$key};
            print $info "$key\t$chr_number{$key}\n";
        }
        close($info);

        print "Sorting chromossomes per position...\n";
        system( 'for i in '
              . $self->output_path
              . '/*.txt; do sort -k3n,3 "$i" > "$i.sorted"; done' );

    }

}
1;

package Find::Hotspots;
{
    use Moose;
    use Modern::Perl;

    # Working with files and directories as attributes
    use MooseX::FileAttribute;
    use File::Basename;
    use List::Util qw(first max maxstr min minstr reduce shuffle sum);

    with 'UCSC::Role';

    # Class attributes (program options - MooseX::Getopt)
    # Make main attribute output_path required

    has_directory 'output_path' => (
        is            => 'rw',
        required      => 1,
        traits        => ['Getopt'],
        documentation => 'Output Path',
    );

    has 'hotspot_wsize' => (
        is       => 'rw',
        isa      => 'Int',
        required => 0,
        traits   => ['Getopt'],
        documentation =>
          'Minimum distance between two hotspots (default: 2000)',
        default => 2000,
    );

    has 'hotspot_cutoff' => (
        is            => 'rw',
        isa           => 'Int',
        required      => 0,
        traits        => ['Getopt'],
        documentation => 'Report only cluster with hits higher than this value',
    );

# METHODS SHOULD BE HERE
# =================================================================================================

=head2 find_hotspots

 Title   : find_hotspots
 Usage   : find_hotspots()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub find_hotspots {
        my ($self) = @_;

        # My window size

        my $w_size = $self->hotspot_wsize;

        say "Sliding Window...\n";

        my $chrominfo = $self->get_chrominfo();

        my @chrs;

        foreach my $chrm ( keys %{$chrominfo} ) {
            push( @chrs, $chrm ) if $chrm !~ /random/;
        }

        open( my $out, ">", $self->output_path."/hotspots.txt" ) or die "Cannot create ".$self->output_path()."/hotspots.txt";
        ;

        my $y;

        foreach my $chrm (@chrs) {
            next
              unless ( -e 'STEP8-Defining_regions/' . $chrm . '.txt.sorted' );

            open( my $in, '<',
                'STEP8-Defining_regions/' . $chrm . '.txt.sorted' )
              or die "cannot open file $chrm.txt.sorted";

            # Number of reads

            my $first_pos = 0;
            my %frame;
            while ( my $line = <$in> ) {
                chomp $line;
                my ( $chr, $id, $pos ) = split( '\t', $line );
                my %h = (
                    'chr' => $chr,
                    'id'  => $id,
                    'pos' => $pos,
                );
                if ($first_pos) {
                    if ( $pos <= $first_pos + $w_size ) {
                        push( @{ $frame{$first_pos} }, \%h );
                    }
                    else {
                        push( @{ $frame{$pos} }, \%h );
                        $first_pos = $pos;
                    }
                }
                else {
                    $first_pos = $pos;
                    push( @{ $frame{$first_pos} }, \%h );
                    next;
                }

            }
            close($in);

            foreach ( sort { $a <=> $b } keys %frame ) {

                for ( my $i = 0 ; $i < $#{ $frame{$_} } ; $i++ ) {
                    say "Lower value before found "
                      . $frame{$_}->[ ( $i + 1 ) ]->{pos} . "<"
                      . $frame{$_}->[$i]->{pos}
                      if ( $frame{$_}->[ ( $i + 1 ) ]->{pos} <
                        $frame{$_}->[$i]->{pos} );
                }

            }

            say "$chrm : Merging windows with less than window size";
            my @final;

            foreach my $key ( sort { $a <=> $b } keys %frame ) {

                unless ( defined $final[0] ) {
                    push( @final, $frame{$key} );
                    next;
                }

                if (
                    $frame{$key}->[0]->{pos} < (
                        $final[$#final][ $#{ $final[$#final] } ]->{pos} +
                          $w_size
                    )
                  )
                {

                    my @new = ( @{ $final[$#final] }, @{ $frame{$key} } );

                    my @sorted = sort { $a->{pos} <=> $b->{pos} } @new;
                    $final[$#final] = \@sorted;

                    for ( my $i = 0 ; $i < $#{ $final[$#final] } ; $i++ ) {
                        say "Lower value before found "
                          . $final[$#final]->[ ( $i + 1 ) ]->{pos} . "<"
                          . $final[$#final]->[$i]->{pos}
                          if ( $final[$#final]->[ ( $i + 1 ) ]->{pos} <
                            $final[$#final]->[$i]->{pos} );
                    }

                }
                else {

                    push( @final, $frame{$key} );

                }
            }

            # Print in any order
            foreach my $window (@final) {

                my @positions_cluster;
                my $nR = 0;
                my $nF = 0;
                foreach ( @{$window} ) {
                    $y++;
                    push( @positions_cluster, $_->{pos} );
                    if ( $_->{id} =~ m/R$/ ) {
                        $nR++;
                    }
                    else {
                        $nF++;
                    }
                }

#                if (   ( $nR / ( $#{$window} + 1 ) ) >= 0.25
#                    && ( $nR / ( $#{$window} + 1 ) ) <= 0.75
#                    && $#{$window} >= 0 )
#                {
                    if ( $#{$window} > 0 ) {
                        print $out $chrm . "\t"
                          . min(@positions_cluster) . "\t"
                          . max(@positions_cluster) . "\t"
                          . ( $#{$window} + 1 ) . "\t"
                          . ( $nR / ( $#{$window} + 1 ) ) . "\t"
                          . $nF . "\t"
                          . $nR."\n";


                    }

#                }
            }
        }
        close($out);
    }

    
    
}
1;

package Get::UCSC::DNA;
{
    use Moose;
    use WWW::Mechanize;
    with 'UCSC::Role';

    my $mech = WWW::Mechanize->new();
    
    has 'seq_name' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        documentation => 'Give a sequence name (optional)',

    );

=head2 get_dna

 Title   : get_dna
 Usage   : get_dna(chr12,100, 200)
 Function: 
 Returns : DNA fragment for UCSC
 Args    : chr, start, end, before_start, after_start, masked, lower_case, reverse

=cut 

    sub get_dna {
        my ($self, $chr, $start, $end, $before_start, $after_end, $masked, $lower_case, $reverse  ) = @_;
        
        my $case = 'upper';
        $case = 'lower' if $lower_case;
        

        my $url = $self->url.'/cgi-bin/hgc?g=getDna&c='.$chr.'&l='.$start.'&r='.$end.'&db='.$self->genome;
        
        # Accessing URL
        $mech->get($url);
        
        # Submitting form
        $mech->submit_form(
            form_number => 1,
            fields      => {
                'hgSeq.padding5'    => $before_start,
                'hgSeq.padding3'    => $after_end,
                'hgSeq.casing'      => $case,
                'hgSeq.maskRepeats' => $masked,
                'hgSeq.repMasking'  => 'N',
                'hgSeq.revComp'     => $reverse,

            }
        );
        # Getting sequence
        my $seq = $mech->text;
        # Removing spaces in the begining
        $seq =~ s/^\s+//g;
        if ($self->seq_name){
            my $old_name = $self->genome.'_dna';
            my $new_name = $self->seq_name;
            $seq =~ s/^\>$old_name/\>$new_name/;      
        }
        return $seq;       

    }


}
1;

package Get::UCSC::TSS;
{
    use Moose;
    use WWW::Mechanize;
    with 'UCSC::Role';

    
=head2 get_tss_position

 Title   : get_tss_position
 Usage   : get_tss_position()
 Function: 
 Returns : 
 Args    : 

=cut 

sub get_tss_positions {
    my($self,$table_name, $range) = @_;

    $range = 2000 unless $range;

    my $bed = $self->get_ucsc_features($table_name);
    
    my @out;
    foreach my $feat ( @{$bed} ) {
        my $tss;
        if ( $feat->strand =~ /\+/ ) {
            $tss = $feat->chromStart;
        }
        else {
            $tss = $feat->chromEnd;
        }

        my $less_range;

        if ( $tss - $range < 0 ) {
            $less_range = 0;
        }
        else {
            $less_range = $tss - $range;
        }

        my $line =
            $feat->chrom . "\t"
          . ($less_range) . "\t"
          . ( $tss + $range ) . "\t"
          . $feat->name . "\t";
        push( @out, $line );
    }

    my $txt = join( "\n", @out );

    return $txt;

}


=head2 get_tss_given_a_list

 Title   : get_tss_given_a_list
 Usage   : get_tss_given_a_list()
 Function: 
 Returns : 
 Args    : 

=cut 

sub get_tss_given_a_list {
    my($self, $table_name, $range, $list, $type) = @_;
    
    $type = 'symbol' unless $type;

    $range = 2000 unless $range;

    my $bed = $self->get_ucsc_features($table_name);
    
    my @out;
    
    foreach my $feat ( @{$bed} ) {
        my $id = $feat->$type;
        if ( 
            $id && /^$id$/i ~~ $list 
        
        ){
        my $tss;
        if ( $feat->strand =~ /\+/ ) {
            $tss = $feat->chromStart;
        }
        else {
            $tss = $feat->chromEnd;
        }

        my $less_range;

        if ( $tss - $range < 0 ) {
            $less_range = 0;
        }
        else {
            $less_range = $tss - $range;
        }

        my $line =
            $feat->chrom . "\t"
          . ($less_range) . "\t"
          . ( $tss + $range ) . "\t"
          . $feat->name . "\t"
          . $feat->symbol . "\t";

        push( @out, $line );
        }
    }

    my $txt = join( "\n", @out );

    return $txt;

}


}
1;

package Venn::BED::Two;
{
    use Moose;
    use Modern::Perl;
    use Venn::Chart;

    # Attributes
    has 'file1' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => '1',
        required      => 1,
        documentation => 'BED File 1',
    );

    has 'file2' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => '2',
        required      => 1,
        documentation => 'BED File2',
    );

    has 'output_file' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'o',
        required      => 1,
        documentation => 'Diagram output filename',
    );

    has 'title' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 't',
        required      => 0,
        documentation => 'Graph Title',
        default       => 'Venn Diagram',
    );

    has 'alias1' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'a1',
        required      => 0,
        documentation => 'File 1 alias to show on diagram',
    );

    has 'alias2' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'a2',
        required      => 0,
        documentation => 'File 2 alias to show on diagram',
    );

=head2 generate_diagram

 Title   : generate_diagram
 Usage   : generate_diagram()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub generate_diagram {
        my ($self) = @_;

        my $f1 = $self->file1;
        my $f2 = $self->file2;

        my $cmd =
"intersectBed -a '$f1' -b  '$f2' -v | sort -k1,1 -k2n,2 -k3n,3 | uniq | wc -l";

        my $only_a = qx/$cmd/;
        chomp $only_a;

        $cmd =
"intersectBed -b '$f1' -a '$f2' -v | sort -k1,1 -k2n,2 -k3n,3 | uniq | wc -l";
        my $only_b = qx/$cmd/;
        chomp $only_b;

        $cmd =
"intersectBed -a '$f1' -b '$f2' | sort -k1,1 -k2n,2 -k3n,3 | uniq | wc -l";
        my $intersection = qx/$cmd/;
        chomp $intersection;

        # create array, only A
        my @a;
        foreach my $j ( 1 .. $only_a ) {
            push @a, 'a' . $j;
        }

        # create array, only B
        my @b;
        foreach my $j ( 1 .. $only_b ) {
            push @b, 'b' . $j;
        }

        # create array intersection
        my @i;
        foreach my $j ( 1 .. $intersection ) {
            push @i, 'i' . $j;
        }

        # A + I
        @a = ( @a, @i );

        # B + I
        @b = ( @b, @i );

        # Create the Venn::Chart constructor
        my $venn_chart = Venn::Chart->new( 400, 400 ) or die("error : $!");

        # Set a title and a legend for our chart
        $venn_chart->set_options( -title => $self->title()
         );
        
        my $l1;
        if ($self->alias1){
            $l1 = $self->alias1();
            
        }
        else{
            $l1 = $self->file1();
            
        }
        my $l2;
        if ($self->alias2){
            $l2 = $self->alias2();
            
        }
        else{
            $l2 = $self->file2();
            
        }

        $venn_chart->set_legends( $l1, $l2  );

        # Create a diagram with gd object
        my $gd_venn = $venn_chart->plot( \@a, \@b );

        # Create a Venn diagram image in png, gif and jpeg format
        open my $fh_venn, '>', $self->output_file.'.png'
          or die("Unable to create png file\n");
        binmode $fh_venn;
        print {$fh_venn} $gd_venn->png;
        close $fh_venn or die('Unable to close file');

    }

}
1;
1;

package Remove::From::List;
{
    use Moose;

    has 'list_a' => (
        is          => 'rw',
        isa         => 'Str',
        traits      => ['Getopt'],
        cmd_aliases => 'a',
        required    => 1,
        documentation =>
'List that will be compared with list b and intersection will be removed',
    );

    has 'list_b' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'b',
        required      => 1,
        documentation => 'List b (fasta format)',
    );

    has 'output' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        required      => 1,
        documentation => 'Output file',
    );

=head2 get_elements_in_B

 Title   : get_elements_in_B
 Usage   : get_elements_in_B()
 Function: Build an array with Ids from a fasta file
 Returns : A reference to an Array
 Args    : 

=cut 

    sub get_elements_in_B {
        my ($self) = @_;
        open( my $in, '<', $self->list_b );
        my @list;
        while ( my $row = <$in> ) {
            chomp $row;
            push( @list, $1 ) if ( $row =~ /^\>(\S+)/ );
        }
        close($in);
        return \@list;

    }

=head2 remove_elements_from_list

 Title   : remove_elements_from_list
 Usage   : remove_elements_from_list()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub remove_elements_from_list {
        my ($self) = @_;

        my $list_b = $self->get_elements_in_B();

        open( my $in,  '<', $self->list_a );
        open( my $out, '>', $self->output );
        while ( my $row = <$in> ) {
            if ($row =~ /^@/){
                print $out $row;
                next;
            }

            my $id;
            $id = $1 if $row =~ /^(\S+)\t/;
            print $out $row unless ( $id ~~ $list_b );
        }
        close($out);
        close($in);

    }

}
1;

#-------------------------------------------------------------------------------------------------------
# Command Classes 
# All Command should be create as classes and listed below
#-------------------------------------------------------------------------------------------------------
package MyApp::Command::RemoveBarcode;
{
    use Moose;
    # Working with files and directories as attributes
    extends 'MooseX::App::Cmd::Command', 'RemoveBarcode';
    
    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================

    # Description of this command in first help
    sub abstract { 'Remove Barcode sequence from Paired End Sequences'; }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;
        if ( $self->bioperl){
            $self->filter_fastq;
        }
        else{
            $self->filter_fastq_nobioperl;
        }
    }

}
1;

package MyApp::Command::Search_Rearranged_Pairs;
{
    use Moose;
    # Working with files and directories as attributes
    extends 'MooseX::App::Cmd::Command', 'Search::Rearranged::Pairs';
    
    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================

    # Description of this command in first help
    sub abstract { 'Search for rearragements pairs in a SAM file'; }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;
            $self->search_rearranged_pairs;

    }

}
1;

package MyApp::Command::Run_Bowtie;
{
    use Moose;

    # Working with files and directories as attributes
    extends 'MooseX::App::Cmd::Command', 'MyApp::Base::Bowtie';

    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================
    has '+seq2' => ( required => 0);
    # Description of this command in first help
    sub abstract { 'Run Bowtie software.'; }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;
        $self->run_bowtie;
    }

}
1;

package MyApp::Command::Get_DNA;
{
    use Moose;

    # Working with files and directories as attributes
    extends 'MooseX::App::Cmd::Command', 'Get::UCSC::DNA';
    use Data::Dumper;

    has 'chr'          => ( isa => 'Str',  is => 'rw', documentation => 'Chromosome', required => 1 );
    has 'start'        => ( isa => 'Int',  is => 'rw', documentation => 'Start Position', required => 1 );
    has 'end'          => ( isa => 'Int',  is => 'rw', documentation => 'End Position', required => 1 );
    has 'before_start' => ( isa => 'Int',  is => 'rw', documentation => '5\' padding' );
    has 'after_end'    => ( isa => 'Int',  is => 'rw', documentation => '3\' padding' );
    has 'masked'       => ( isa => 'Bool', is => 'rw', documentation => 'Masked repeats with N' );
    has 'lower_case'   => ( isa => 'Bool', is => 'rw', documentation => 'Return sequence in lowercase' );
    has 'reverse'      => ( isa => 'Bool', is => 'rw', documentation => 'Return de Reverse Complement' );

    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================
    # Description of this command in first help
    sub abstract { 'Get a UCSC DNA given a chromosome region.'; }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;

        my $seq =  $self->get_dna(
            $self->chr, 
            $self->start, 
            $self->end, 
            $self->before_start,
            $self->after_end, 
            $self->masked, 
            $self->lower_case, 
            $self->reverse
        );

        print $seq;
    }

}
1;

package MyApp::Command::Get_DNA_from_Bed;
{
    use Moose;

    # Working with files and directories as attributes
    extends 'MooseX::App::Cmd::Command', 'Get::UCSC::DNA';
    use MooseX::FileAttribute;
    
    has '+seq_name'    => ( traits => ['NoGetopt'] );
    has_file 'input'   => ( is => 'rw', documentation => 'BED file' );
    has 'before_start' => ( isa => 'Int',  is => 'rw', documentation => '5\' padding' );
    has 'after_end'    => ( isa => 'Int',  is => 'rw', documentation => '3\' padding' );
    has 'masked'       => ( isa => 'Bool', is => 'rw', documentation => 'Masked repeats with N' );
    has 'lower_case'   => ( isa => 'Bool', is => 'rw', documentation => 'Return sequence in lowercase' );
    has 'reverse'      => ( isa => 'Bool', is => 'rw', documentation => 'Return de Reverse Complement' );

    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================
    # Description of this command in first help
    sub abstract { 'Get a UCSC DNA given a list of  chromosome region in BED format.'; }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;
               
        open(my $in,'<',$self->input );

        while ( my $row = <$in> ) {
            chomp $row;
            my @f = split( /\s+/, $row );
            $self->seq_name( $f[3] ) if $f[3];
            my $seq =
              $self->get_dna( 
                  $f[0], 
                  $f[1], 
                  $f[2], 
                  $self->before_start,
                  $self->after_end, 
                  $self->masked, 
                  $self->lower_case,
                  $self->reverse 
              );

            print $seq;
        }
        close($in);
    }

}

package MyApp::Command::Get_TSS;
{
    use Moose;

    # Working with files and directories as attributes
    extends 'MooseX::App::Cmd::Command', 'Get::UCSC::TSS';
    use Data::Dumper;

    has 'range'          => ( isa => 'Int',  is => 'rw', documentation => 'Range before and after TSS' );
    has 'trackname'       => ( isa => 'Str', is => 'rw', documentation => 'knownGene, ensGene or refGene', required => 1 );
    has 'list'       => ( isa => 'Str', is => 'rw', documentation => 'A list of gene symbols', required => 0 );
    has 'type'       => ( isa => 'Str', is => 'rw', documentation => 'Type of the input list (symbol,refseq,ensembl,kg)', required => 0 );

    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================
    # Description of this command in first help
    sub abstract { 'Get a TSS plus a range for all genes.'; }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;
        if ( $self->list ) {
            open (my $in,'<',$self->list) or die "can't open ". $self->list;
            my @symbols;
            while ( my $symbol = <$in> ) {
                chomp $symbol;
                push @symbols, $symbol;
            }
            close($in);

            my $list =
              $self->get_tss_given_a_list( $self->trackname, $self->range, \@symbols, $self->type);
            
            say $list;
                
        }
        else {
            my $list =
              $self->get_tss_positions( $self->trackname, $self->range, );

            say $list;
        }
    }

}
1;

package MyApp::Command::bed2html;
{
    use Moose;
    use Modern::Perl;

    extends qw/MooseX::App::Cmd::Command/;

    # Description of this command in first help
    sub abstract { 'Convert BED file into HTML file.'; }

    has 'input' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'i',
        required      => 1,
        documentation => 'Input file in BED format',
    );

    

    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;

        #Transform Genes.txt into HTML
        my $html_file;
        $html_file .= "<html>";
        $html_file .= "<header>";
        $html_file .= "<title>List of Hotspots</title>";
        $html_file .= "</header>";
        $html_file .= "<body>";

        $html_file .= "<table width=800 border=1>";
        open( my $in, "<", $self->input ) or die "cannot open";
        my $i;
        while (<$in>) {
            $i++;
            chomp;
            my @f = split( "\t", $_ );
            $html_file .= "<tr>";
            $html_file .= "<td>";
            $html_file .= "<b>$i</b>";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "<b>$f[0]</b>";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[1]";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[2]";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[3]";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[4]";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[5]";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[6]";
            $html_file .= "</td>";

            $html_file .= "<td>";
            $html_file .= "$f[7]" if ( $f[7] );
            $html_file .= "</td>";

            my ( $start, $end ) = ( $f[1], $f[2] );

            $html_file .= "<td>";
            $html_file .=
"<a href='http://maclab.dyndns-home.com/cgi-bin/hgTracks?clade=mammal&org=Mouse&db=mm9&position=$f[0]:"
              . ($start) . "-"
              . ( $end + 54 )
              . "&hgtsuggest=&pix=1800&Submit=submit&hgsid=168' target='_blank'>See region</a>";
            $html_file .= "</td>";

            $html_file .= "</tr>";
        }
        close($in);
        $html_file .= "</table>";
        $html_file .= "<body>";
        $html_file .= "</html>";

        # Send HTML to file
        my $output_name = $self->input;
        $output_name =~ s/\.\S+$/\.html/g;
        open( my $out, '>', $output_name );
        print $out $html_file;
        close($out);

    }


}
1;


package MyApp::Command::breaking_spreading;
{
    use Moose;
    use Modern::Perl;
    use Data::Dumper;
    use File::Temp;


    extends qw/MooseX::App::Cmd::Command/;
    with 'UCSC::Role';

    # Description of this command in first help
    sub abstract { 'Given a chromosome with a break site position try to find how far of the break the number of events became similar to background.'; }

    has 'break_file' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        required      => 1,
        documentation => 'File containing the positions of breaks of a given chromossome',
    );

    has 'chrs_txt_dir' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        required      => 1,
        documentation => 'STEP-8 directory path',
    );

    has 'chr' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        required      => 1,
        documentation => 'Name of the chromosome with break (if in the chrs_tab_file)',
    );
   
    has 'window_size' => (
        is            => 'rw',
        isa           => 'Int',
        traits        => ['Getopt'],
        required      => 1,
        default       => 5000,
        documentation => 'Window or bin size to search from break',
    );

    

    # MooseX::App:Cmd Execute method (call all your above methods bellow)
    # =================================================================================================
    
    sub get_avg_and_chr_size {
        my ($self) = @_;
        
        my $total_of_events;
        my $total_size;
        my $chr_break_size;

        my $chrominfo = $self->get_chrominfo();

        my %chr_summary;

        foreach my $chr ( keys %{$chrominfo} ) {
            next if ( $chr =~ /random/ || $chr =~ /chr[YXM]/ );
            my $cmd    = "wc -l " . $self->chrs_txt_dir . "/" . $chr . ".txt";
            my $events = qx/$cmd/;
            chomp $events;
            $events =~ s/^(\d+).*/$1/;
            if ( $self->chr !~ /$chr/ ) {
                $total_size += $chrominfo->{$chr}->{size};
                $total_of_events += $events;
                $chr_summary{$chr}{events} = $events;
                $chr_summary{$chr}{avg} = $events / $chrominfo->{$chr}->{size};

            }
            else {
                $chr_break_size = $chrominfo->{$chr}->{size};
            }

        }

        my $avg = $total_of_events/$total_size;

        my %hash = (
            avg            => $avg,
            chr_break_size => $chr_break_size,
            summary => \%chr_summary,

        );

        return \%hash;

    }

    sub parse_breakfile {
        my ($self) = @_;

        my %hash;

        open( my $in, '<', $self->break_file );
        
        while ( my $row = <$in> ) {
            chomp $row;
            if ( $row =~ /^(\S+)\s+(\d+)\s+(\d+)/ ) {
                %hash = (
                    chr   => $1,
                    start => $2,
                    end   => $3,
                );
            }
            else {
                die "The break_file seems to be in a wrong format!";
            }

        }
        close( $in );
        
        return \%hash;      
        

    }

    sub search_break {
        my ($self) = @_;
        
        my $break_info = $self->parse_breakfile();

        # Create temporary bed file for windows
        my $fh = File::Temp->new();
        my $fname = $fh->filename;
    
        # Search left        
        for (
            my $i = $break_info->{start} - $self->window_size ;
            $i >= 0 ;
            $i = $i - $self->window_size
          )
        {
            
            say $fh $break_info->{chr}."\t".$i."\t".($i + $self->window_size - 1);
            
            
        }

        my $cmd = 'cut -f1,3 '.$self->chrs_txt_dir.'/'.$break_info->{chr}.'.txt.sorted | perl -pne \'$s = $1 +1 if $_ =~ /(\d+)$/;$_ =~ s/$/\t$s/\' |  coverageBed -a stdin -b '.$fname.' | sort -k2rn,2';
        my $left = qx/$cmd/;

        # Create temporary bed file for windows
       $fh = File::Temp->new();
       $fname = $fh->filename;
       my $hash = $self->get_avg_and_chr_size();
        # Search right       
        for (
            my $i = $break_info->{start} + $self->window_size ;
            $i <= $hash->{chr_break_size} ;
            $i = $i + $self->window_size
          )
        {
            
            say $fh $break_info->{chr}."\t".($i - $self->window_size)."\t".($i - 1);
            
            
        }

       $cmd = 'cut -f1,3 '.$self->chrs_txt_dir.'/'.$break_info->{chr}.'.txt.sorted | perl -pne \'$s = $1 +1 if $_ =~ /(\d+)$/;$_ =~ s/$/\t$s/\' |  coverageBed -a stdin -b '.$fname.' | sort -k2n,2';
        my $right = qx/$cmd/;
        

        open(my  $in, '<', \$left );
        
        my $b_start = 0;
        my $low_count = 0;
        my $n_windows;
        while ( my $row = <$in> ){
            $n_windows++;
            chomp $row;
            my ($chr,$start,$end,$hits) = split "\t", $row;
            if ($hits >= 2){
                $low_count =0;
            }
            else{ 
                $low_count++;
            }
            
            if ($low_count == 3){
                $b_start = $start;
                last;
            }


        }
        close( $in );
        say "Merged windows left: $n_windows";
        
        open( $in, '<', \$right );
        
        my $b_end = 0;
        $low_count = 0;
        $n_windows = 0;
        while ( my $row = <$in> ){
            $n_windows++;
            chomp $row;
            my ($chr,$start,$end,$hits) = split "\t", $row;
            if ($hits >= 2){
                $low_count =0;
            }
            else{ 
                $low_count++;
            }
            
            if ($low_count == 3){
                $b_end = $end;
                last;
            }


        }
        close( $in );
        
        say "Merged windows right: $n_windows";

        say "$b_start-$b_end";

        open( my $out, '>', "right.txt" );
            print $out $right;
        close( $out );
        
         open($out, '>', "left.txt" );
            print $out $left;
        close( $out );
        
        


    }

    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;

        #my $cmd = "intersectBed -b '$f1' -a '$f2' -v | sort -k1,1 -k2n,2 -k3n,3 | uniq | wc -l";
        #my $only_b = qx/$cmd/;
        #chomp $only_b;

#        my $hash = $self->get_avg_and_chr_size();
        $self->search_break
   
    }


}
1;


# Class Nussenzweig Translocations
package MyApp::Command::Translocations_Pipeline;
{
    use Moose;
    use MooseX::FileAttribute;
    use File::Basename;

    import RemoveBarcode;
    import MyApp::Base::Bowtie;
    import Search::Rearranged::Pairs;
    import Cluster::Translocations;

    extends 'MooseX::App::Cmd::Command', 'MyApp::Base::Config';
    with 'MyApp::Role::BaseAttributes', 'MyApp::Role::Bowtie', 'MyApp::Role::PrimerType';
    
    # Class attributes (program options - MooseX::Getopt)
    has '+configfile' => ( required => 0 );
 
    has 'exact_match' => (
        isa           => 'Bool',
        is            => 'rw',
        required      => 0,
        default     => 0,
        traits        => ['Getopt'],
        documentation => 'Exact Match the barcode. (default: 0)',
    );
 
    has 'wolfgang_params' => (
        isa           => 'Bool',
        is            => 'rw',
        required      => 0,
        default     => 1,
        traits        => ['Getopt'],
        documentation => 'Use Wolfgang\'s params. (default: 1)',
    );
    has 'long_reads' => (
        isa           => 'Bool',
        is            => 'rw',
        required      => 0,
        default     => 0,
        traits        => ['Getopt'],
        documentation => 'Turn on when using reads higher than 36bp. (default: 0)',
    );

    # Creating STEPs directories attributes
    my @dir_name = (
        'STEP1-barcode_filtered',
        'STEP2-paired_alignment',
        'STEP3-single_alignment',
        'STEP4-ordered_single_alignment',
        'STEP5-merged_single_alignment',
        'STEP6-translocated_pairs',
        'STEP7-clustered_translocated_pairs',
        'STEP8-Defining_regions',
        'STEP9',
    );

    foreach my $i ( 1 .. 7 ) {
        has_directory 'step' 
          . $i
          . '_path' => (
            required => 1,
            default       => $dir_name[$i-1],
            traits => ['NoGetopt'],
            documentation => 'step' . $i . ' Path (Optional)',
          );
    }


=cut
    sub BUILD {
        my ($self) = @_;
        my $meta = __PACKAGE__->meta;

        foreach my $att ( $meta->get_attribute_list ) {
            if ($att =~ /step/i){
                 use autodie 'mkdir';
                 mkdir $self->output_path.'/'.$self->$att unless -d $self->output_path .'/'. $self->$att;
            }
        }

    }
=cut


=head2 step1

 Title   : step1
 Usage   : step1()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub step1 {
        my ($self, $step_path) = @_;

        print "Filtering and Spliting Barcode Sequences...\n\n";
        
        my $barcode = RemoveBarcode->new(
            seq1 => $self->seq1,
            seq2 => $self->seq2,
            output_path => $step_path,
            exact_match => $self->exact_match,
        );
        
        $barcode->filter_fastq_nobioperl();
    }


=head2 step2

 Title   : step2
 Usage   : step2()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub step2 {
        my ($self, $step_path) = @_;
 
        print "Align Paired-end Sequences...\n";
        print "--------------------------------------------\n\n";
        
        my $meta = MyApp::Role::Bowtie->meta;
        
        my %attributes;
        foreach my $att ($meta->get_attribute_list){
            $attributes{$att} = $self->$att;
        }
        
        $attributes{'seq1'} = $self->output_path .'/'. $self->step1_path . '/' . basename($self->seq1) . '.barcode_matched';
        $attributes{'seq2'} = $self->output_path .'/'. $self->step1_path . '/' . basename($self->seq2) . '.barcode_matched';
        $attributes{'bowtie_output_path'} = $step_path;

        my $bowtie = MyApp::Base::Bowtie->new( %attributes );
        
       $bowtie->run_bowtie();
    }


=head2 step3

 Title   : step3
 Usage   : step3()
 Function: 
 Returns : 
 Args    : 

=cut 

    sub step3 {
        my ($self, $step_path) = @_;
        
        my $meta = MyApp::Role::Bowtie->meta;
        
        my %attributes;
        foreach my $att ($meta->get_attribute_list){
            $attributes{$att} = $self->$att;
        }

        delete $attributes{'seq2'};
        $attributes{'bowtie_output_path'} = $step_path;

        my  $seq1 = $self->bowtie_unaligned_seqfile;
        my $seq2 = $seq1;
        $seq1 =~ s/\.(\S*)$/_1\.$1/;
        $seq2 =~ s/\.(\S*)$/_2\.$1/;

        print "Align Pair One Sequences as single-ends...\n";
        print "--------------------------------------------\n\n";

        $attributes{'seq1'} = $self->output_path .'/'. $self->step2_path . '/' . $seq1;
        $attributes{'bowtie_unaligned_seqfile'} = 'single_unalignment1.fq';
        $attributes{'bowtie_alignment_file'} = 'single_alignment1.sam';
        

        my $bowtie = MyApp::Base::Bowtie->new( %attributes );
        
        $bowtie->run_bowtie();

        print "Align Pair Two Sequences as single-ends...\n";
        print "--------------------------------------------\n\n";

        $attributes{'seq1'} = $self->output_path .'/'. $self->step2_path . '/' . $seq2;
        $attributes{'bowtie_unaligned_seqfile'} = 'single_unalignment2.fq';
        $attributes{'bowtie_alignment_file'} = 'single_alignment2.sam';

        $bowtie = MyApp::Base::Bowtie->new( %attributes );
        
        $bowtie->run_bowtie();

    }


=head2 step4

 Title   : step4
 Usage   : step4()
 Function: 
 Returns : 
 Args    : 

=cut 

sub step4 {
    my ( $self, $step_path ) = @_;

    my $last_step_path = $self->output_path . '/' . $self->step3_path;
    print "Creating BAM Alignment File One...\n";
    system(
"samtools view -bS -o $step_path/single_alignment1.bam $last_step_path/single_alignment1.sam"
    );

    print "Creating BAM Alignment File Two...\n";
    system(
"samtools view -bS -o $step_path/single_alignment2.bam $last_step_path/single_alignment2.sam"
    );

}



=head2 step5

 Title   : step5
 Usage   : step5()
 Function: 
 Returns : 
 Args    : 

=cut 

sub step5 {
    my($self,$step_path) = @_;

    my $last_step_path = $self->output_path . '/' . $self->step4_path;
    print "Merging single_alignment1.bam and single_alignment2.bam ...\n";
    system(
"samtools merge -n  $step_path/merged.bam  $last_step_path/single_alignment1.bam $last_step_path/single_alignment2.bam"
    );

    print "Sorting Mate Pairs ...\n";
    system(
"samtools sort -n $step_path/merged.bam  $step_path/merged.sorted"
    );

    print "Fixing Mate Pairs ...\n";
    system(
"samtools fixmate $step_path/merged.sorted.bam  $step_path/merged.sorted.fixed.bam"
    );

    print "Converting to SAM ...\n";
    system(
"samtools view -h $step_path/merged.sorted.fixed.bam > $step_path/merged.sorted.fixed.sam"
    );
}


=head2 step6

 Title   : step6
 Usage   : step6()
 Function: 
 Returns : 
 Args    : 

=cut

sub step6 {
    my ( $self, $step_path ) = @_;
    my $last_step_path = $self->output_path . '/' . $self->step5_path;
    
    my $meta = MyApp::Role::PrimerType->meta;

    my %attributes;
    foreach my $att ( $meta->get_attribute_list ) {
        $attributes{$att} = $self->$att;
    }
    
    $attributes{input} = $last_step_path . '/merged.sorted.fixed.sam';
    $attributes{output_path} = $step_path;

    my $object = Search::Rearranged::Pairs->new(
        %attributes
    );
    print "Generating Translocated Pairs SAM list ...\n";
    $object->search_rearranged_pairs;

    print "Convert Translocated Pairs to BAM list ...\n";
    if ($self->wolfgang_params){
        if ($self->long_reads){
            if ($self->primer_type =~ /igh/i){
                system("echo \">left\nACTGTGGCTGCCTCTGGCTTACCATTTGCGGTGCCTGGTTTCGGAGAGGTCCAGAGTCT\" > $step_path/primers.fa;");
                system("echo \">right\nCAGAAGCCACAACCATACATTCCCAGGTCTGGGTGGGAGACCCAAAGTCCAGGCCTACC\" >> $step_path/primers.fa;");
            }
            if ($self->primer_type =~ /myc/i){
                system("echo \">left\nCTTGGGGGAAACCAGAGGGAATCCTCACATTCCTACTTGGGATCCGCGGGTATCCCTCG\" > $step_path/primers.fa;");
                system("echo \">right\nCACCCAGTGCTGAATCGCTGCAGGGTCTCTGGTGCAGTGGCGTCGCGGTTTAGAGTGTA\" >> $step_path/primers.fa;");
            }
        }
        else{
             if ($self->primer_type =~ /igh/i){
                system("echo \">left\nACTGTGGCTGCCTCTGGCTTACCATTTGCGGTGCCT\" > $step_path/primers.fa;");
                system("echo \">right\nGGTAGGCCTGGACTTTGGGTCTCCCACCCAGACCTG\" >> $step_path/primers.fa;");
            }
            if ($self->primer_type =~ /myc/i){
                system("echo \">left\nCTTGGGGGAAACCAGAGGGAATCCTCACATTCCTAC\" > $step_path/primers.fa;");
                system("echo \">right\nTACACTCTAAACCGCGACGCCACTGCACCAGAGACC\" >> $step_path/primers.fa;");
            }
       
        }

        # Create index
        system("bowtie-build $step_path/primers.fa $step_path/primers &> /dev/null");
        # Run bowtie
        my $bowtie_opts =  "-v2 -k2 -m1 --threads=4 --suppress=2,4,5,6,7 --un unaligned_primers.fa";
        # Getting primers
        system(' perl -lane \'print ">$F[0]\n$F[9]" if ($F[5] == 36 || $F[5] == 59)\' '.$step_path.'/translocated_pairs.sam | bowtie '.$bowtie_opts.' '.$step_path.'/primers --un '.$step_path.'/unaligned_primers.fa -f - > '.$step_path.'/valid_primers.txt');
        my $remove_list = Remove::From::List->new( 
            list_a => "$step_path/translocated_pairs.sam",
            list_b => "$step_path/unaligned_primers.fa",
            output => "$step_path/translocated_pairs_removed_primers.sam",
        );
        $remove_list->remove_elements_from_list;
        system("rm $step_path/translocated_pairs.sam");
        system("mv $step_path/translocated_pairs_removed_primers.sam $step_path/translocated_pairs.sam");
        

    }

    system("samtools view -bS -o $step_path/translocated_pairs.bam  $step_path/translocated_pairs.sam");

    #print "Sorting Translocated Pairs to BAM list ...\n";
    #system("samtools sort $step_path/translocated_pairs.bam  $step_path/translocated_pairs.sorted");
    #

}


=head2 step7

 Title   : step7
 Usage   : step7()
 Function: 
 Returns : 
 Args    : 

=cut 

sub step7 {
    
    my ( $self, $step_path ) = @_;
    
    my $last_step_path = $self->output_path . '/' . $self->step6_path;
    
    my $meta = MyApp::Role::PrimerType->meta;

    my %attributes;
    
    foreach my $att ( $meta->get_attribute_list ) {
        $attributes{$att} = $self->$att;
    }
 
    $attributes{input}          = $last_step_path . '/translocated_pairs.sam';
    $attributes{output_path}    = $step_path;
    $attributes{cluster_cutoff} = 1;

    my $object = Cluster::Translocations->new( %attributes );

    print "Generating Translocated Pairs SAM list ...\n";
    
    $object->cluster_translocations;


}


    # Description of this command in first help
    sub abstract {
        'Pipeline used to detect AID translocations and rearrangements';
    }
    
    # method used to run the command
sub execute {
        my ( $self, $opt, $args ) = @_;
        
        foreach my $i ( 1 .. 7 ) {
            my $sub = 'step' . $i;
            if ( $self->can($sub) ) {
                my $step_attr = 'step' . $i . '_path';
                my $step_path = $self->output_path . '/' . $self->$step_attr;
                print "--------------------------------\n";
                print " STEP$i\n";
                print "--------------------------------\n";

                if ( -e $step_path ) {
                    print "Skipping STEP$i...\n";
                }
                else {
                    mkdir $step_path or die 'Couln\'t create' . $step_path;
                    $self->$sub($step_path);
                }
            }
        }
    }

}
1;

package MyApp::Command::Hotspot_Finder;
{
    use Moose;
    use MooseX::FileAttribute;
    use File::Basename;
    use File::Temp;

    import Split::Clusters::Chrs;
    import Find::Hotspots;

    extends 'MooseX::App::Cmd::Command', 'MyApp::Base::Config';
    with 'MyApp::Role::PrimerType', 'UCSC::Role';

    # Class attributes (program options - MooseX::Getopt)
    has '+configfile' => ( required => 0 );
  
    # Creating STEPs directories attributes
    my @dir_name = (
        'STEP1-barcode_filtered',
        'STEP2-paired_alignment',
        'STEP3-single_alignment',
        'STEP4-ordered_single_alignment',
        'STEP5-merged_single_alignment',
        'STEP6-translocated_pairs',
        'STEP7-clustered_translocated_pairs',
        'STEP8-Defining_regions',
        'STEP9',
    );

    foreach my $i ( 8 .. 9 ) {
        has_directory 'step' 
          . $i
          . '_path' => (
            required => 1,
            default       => $dir_name[$i-1],
            traits => ['NoGetopt'],
            documentation => 'step' . $i . ' Path (Optional)',
          );
    }

    # Outpuf path for generated files
    has 'output_path' => (
        traits        => ['Getopt'],
        cmd_aliases   => 'o',
        required      => 1,
        is            => 'rw',
        isa           => 'Str',
        documentation => 'Where the output files should be placed',

    );


sub step8 {
    
    my ( $self, $step_path ) = @_;
    
    my $meta = MyApp::Role::PrimerType->meta;

    my %attributes;
    
    foreach my $att ( $meta->get_attribute_list ) {
        $attributes{$att} = $self->$att;
    }

    $meta = UCSC::Role->meta;
     foreach my $att ( $meta->get_attribute_list ) {
        $attributes{$att} = $self->$att;
    }

 
    $attributes{input}          = 'STEP7-clustered_translocated_pairs/cluster_translocated_pairs.sam';
    $attributes{output_path}    = $step_path;

    my $object =  Split::Clusters::Chrs->new( %attributes );

    print "Splitting and sorting clusters in chromossomes ...\n";
    
    $object->split_clusters_by_chrs;


}

sub step9 {
    
    my ( $self, $step_path ) = @_;
    

    my %attributes; 
    $attributes{output_path}    = $step_path;
    $attributes{genome}    = $self->genome();
    ;

    my $object =  Find::Hotspots->new( %attributes );

    print "Search for hotspots ...\n";
    
    $object->find_hotspots();
    
    chdir $step_path;
    
    # Create temporary bed file for genes
    my $fh = File::Temp->new();
    my $fname = $fh->filename;
    
    my $features = $self->get_ucsc_features('knownGene');
    
    foreach my $feat (@{$features}) {
        my $symbol = $feat->symbol;
        $symbol = $feat->name unless $symbol;

        print $fh $feat->chrom."\t"
        . $feat->chromStart."\t"
        . $feat->chromEnd."\t"
        . $symbol."\n";
    }
    
    
    # Intersect hotspots with genes
    say "Searching overlaps  between Hotspots and Genes";
    my $genes = qx/windowBed -a hotspots.txt -b $fname -w 0  | cut -f1,2,3,4,5,6,7,11 | sort -k1,1 -k2n,2 -k8,8 | uniq/;

    # Find no intersections
    say "Searching for non-overlaps between Hotspots and Genes";
    my $no_genes = qx/windowBed -a hotspots.txt -b $fname -w 0 -v | cut -f1,2,3,4,5,6,7,11 | sort -k4nr,4/;
    
    
    # Save no intersection in a file
    open(my $out,'>','no_genes.txt');
    print $out $no_genes;
    close($out);
    
    # Save no intersection in a file
    open($out,'>','genes.bed');
    print $out $genes;
    close($out);
   
    # Merge hotspots that intersect more than one gene
    #----------------------------------
    my $bed_file = \$genes;

    my %same;
    open( my $in, "<", $bed_file );

    while (<$in>) {
        chomp;
        my ( $chr, $start, $end, $event, $r_ratio, $f, $r, $gene ) = split "\t",
          $_;
        $gene = '*' unless ($gene);
        push( @{ $same{"$chr,$start,$end,$event,$r_ratio,$f,$r"} }, $gene );
    }

    close($in);
    
    my $final_genes;
    foreach my $key ( keys %same ) {
        my @aux = split( ',', $key );
        $final_genes .= join( "\t", @aux );
        my $genes = join( ", ", @{ $same{$key} } );
        $genes =~ s/, \*//g;

        #    $genes =~ s/\*//g;
        $final_genes .= "\t" . $genes . "\n";
    }

    open($out,'>','genes.txt');
    print $out $final_genes;
    close($out);



    #Transform Genes.txt into HTML
    my $combine_files = $final_genes.$no_genes;
    my $html_file;
    $html_file .= "<html>";
    $html_file .= "<header>";
    $html_file .= "<title>List of Hotspots</title>";
    $html_file .= "</header>";
    $html_file .= "<body>";

    $html_file .= "<table width=800 border=1>";
    open( $in, "<", \$combine_files ) or die "cannot open";
    my $i;
    while (<$in>) {
        $i++;
        chomp;
        my @f = split( "\t", $_ );
        $html_file .= "<tr>";
        $html_file .= "<td>";
        $html_file .= "<b>$i</b>";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "<b>$f[0]</b>";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "$f[1]";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "$f[2]";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "$f[3]";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "$f[4]";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "$f[5]";
        $html_file .= "</td>";

        $html_file .= "<td>";
        $html_file .= "$f[6]";
        $html_file .= "</td>";
    
        
        $html_file .= "<td>";       
        $html_file .= "$f[7]" if ($f[7]);
        $html_file .= "</td>";

        my ( $start, $end ) = ( $f[1], $f[2] );

        $html_file .= "<td>";
        $html_file .=
"<a href='http://maclab.dyndns-home.com/cgi-bin/hgTracks?clade=mammal&org=Mouse&db=mm9&position=$f[0]:"
          . ($start) . "-"
          . ( $end + 54 )
          . "&hgtsuggest=&pix=1800&Submit=submit&hgsid=168' target='_blank'>See region</a>";
        $html_file .= "</td>";

        $html_file .= "</tr>";
    }
    close($in);
    $html_file .= "</table>";
    $html_file .= "<body>";
    $html_file .= "</html>";
    
    # Send HTML to file
    open($out,'>','genes.html');
    print $out $html_file;
    close($out);


}


    # Description of this command in first help
    sub abstract {
        'Translocation Hotspot Finder';
    }
    
    # method used to run the command
sub execute {
        my ( $self, $opt, $args ) = @_;
        
        foreach my $i ( 8 .. 9 ) {
            my $sub = 'step' . $i;
            if ( $self->can($sub) ) {
                my $step_attr = 'step' . $i . '_path';
                my $step_path = $self->output_path . '/' . $self->$step_attr;
                print "--------------------------------\n";
                print " STEP$i\n";
                print "--------------------------------\n";

                if ( -e $step_path ) {
                    print "Skipping STEP$i...\n";
                }
                else {
                    mkdir $step_path or die 'Couln\'t create' . $step_path;
                    $self->$sub($step_path);
                }
            }
        }
    }

}
1;

#-------------------------------------------------------------------------------------------------------
# TESTING METHODS 
#-------------------------------------------------------------------------------------------------------

# class test - test all your classes here!
#-------------------------------------------------------------------------------------------------------
package MyApp::Command::TestApp;
{
    use Moose;
    # Working with files and directories as attributes
    #use MooseX::FileAttribute;
    use Test::Class::Sugar;
    use App::Cmd::Tester;
    use FindBin qw($Bin);
    
    my $Bin = $Bin;
    extends 'MooseX::App::Cmd::Command';
    

    my $seq1 = "$Bin/t/files/seq1.fq";
    my $seq2 = "$Bin/t/files/seq2.fq";

    my %attr = (
        seq1        => $seq1,
        seq2        => $seq2,
        output_path => '/tmp',
        barcode     => 'CGCGCCT',
        bowtie_genome_files => $Bin.'/t/files/bowtie/indexes/e_coli',
    );

    my $object;

# RemoveBarcode 
#-------------------------------------------------------------------------------------------------------
    testclass exercises RemoveBarcode {
        # Test::Most has been magically included
        # 'warnings' and 'strict' are turned on

        use File::Basename;

        test constructor >> 3 {
            my $class = $test->subject;
            can_ok $class, 'new';
            ok $object = $class->new( %attr ),
              '... and the constructor should succeed';
            isa_ok $object, $class, '... and the object it returns';
        }
         
        test index_barcode_string {

            my @got = $object->index_barcode_string;

            my @seqs = ( 
                  '[ATCGnatcgn.]GCGCCT',
                  '[ATCGNatcgn.]GGCGCG',
                  '[ATCGNatcgn\.]{1,1}[ATCGnatcgn.]GCGCCT',
                  '[ATCGNatcgn\.]{1,1}[ATCGNatcgn.]GGCGCG',
                  'C[ATCGnatcgn.]CGCCT',
                  'A[ATCGNatcgn.]GCGCG',
                  '[ATCGNatcgn\.]{1,1}C[ATCGnatcgn.]CGCCT',
                  '[ATCGNatcgn\.]{1,1}A[ATCGNatcgn.]GCGCG',
                  'CG[ATCGnatcgn.]GCCT',
                  'AG[ATCGNatcgn.]CGCG',
                  '[ATCGNatcgn\.]{1,1}CG[ATCGnatcgn.]GCCT',
                  '[ATCGNatcgn\.]{1,1}AG[ATCGNatcgn.]CGCG',
                  'CGC[ATCGnatcgn.]CCT',
                  'AGG[ATCGNatcgn.]GCG',
                  '[ATCGNatcgn\.]{1,1}CGC[ATCGnatcgn.]CCT',
                  '[ATCGNatcgn\.]{1,1}AGG[ATCGNatcgn.]GCG',
                  'CGCG[ATCGnatcgn.]CT',
                  'AGGC[ATCGNatcgn.]CG',
                  '[ATCGNatcgn\.]{1,1}CGCG[ATCGnatcgn.]CT',
                  '[ATCGNatcgn\.]{1,1}AGGC[ATCGNatcgn.]CG',
                  'CGCGC[ATCGnatcgn.]T',
                  'AGGCG[ATCGNatcgn.]G',
                  '[ATCGNatcgn\.]{1,1}CGCGC[ATCGnatcgn.]T',
                  '[ATCGNatcgn\.]{1,1}AGGCG[ATCGNatcgn.]G',
                  'CGCGCC[ATCGnatcgn.]',
                  'AGGCGC[ATCGNatcgn.]',
                  '[ATCGNatcgn\.]{1,1}CGCGCC[ATCGnatcgn.]',
                  '[ATCGNatcgn\.]{1,1}AGGCGC[ATCGNatcgn.]',
                  'GCGCCT',
                  'GGCGCG',
                  );
            my @expected = map {qr/$_/} @seqs;
            
            is_deeply (\@got, \@expected);
        }

        test strip_id {
            my $input_id = '@HWUSI-EAS1600:Txcap_read_2:6_30_2010:0:7:120:19875:13263#0/2';
            my $got = $object->strip_id($input_id);
            my $expected = '@HWUSI-EAS1600:Txcap:6_30_2010:0:7:120:19875:13263#0/';
            is ($got, $expected);
            
        }

        test filter_fastq >> 4{

            # Run the filter and see if return 1
            my $got = $object->filter_fastq;
            my $expected = 1;
            is ($got, $expected);

            # open filtered seq1 file and compare
            open(my $in,'<', $object->output_path.'/'. basename($object->seq1) .'.barcode_matched');
            my @file_got = <$in>; 
            open($in,'<', $Bin.'/t/files/'. basename($object->seq1) . '.barcode_matched');
            my @file_expected = <$in>;
            is_deeply (\@file_got,\@file_expected, 'Sequence 1 corrected filtered');
     
            # open filtered seq2 file and compare
            open($in,'<', $object->output_path.'/'. basename($object->seq2) .'.barcode_matched');
            @file_got = <$in>; 
            open($in,'<', $Bin.'/t/files/'. basename($object->seq2) . '.barcode_matched');
            @file_expected = <$in>;
            is_deeply (\@file_got,\@file_expected, 'Sequence 2 corrected filtered');

            # Test Output info
            open($in,'<', $object->output_path.'/barcode_filter_info.txt');
            @file_got = <$in>; 
            open($in,'<', $Bin.'/t/files/barcode_filter_info.txt');
            @file_expected = <$in>;
            is_deeply (\@file_got,\@file_expected, 'Filter info.txt is ok');


        }

        test filter_fastq_nobioperl >> 4{

            # Run the filter and see if return 1
            my $got = $object->filter_fastq_nobioperl;
            my $expected = 1;
            is ($got, $expected);

            # open filtered seq1 file and compare
            open(my $in,'<', $object->output_path.'/'. basename($object->seq1) .'.barcode_matched');
            my @file_got = <$in>; 
            open($in,'<', $Bin.'/t/files/'. basename($object->seq1) . '.barcode_matched');
            my @file_expected = <$in>;
            is_deeply (\@file_got,\@file_expected, 'Sequence 1 corrected filtered');
     
            # open filtered seq2 file and compare
            open($in,'<', $object->output_path.'/'. basename($object->seq2) .'.barcode_matched');
            @file_got = <$in>; 
            open($in,'<', $Bin.'/t/files/'. basename($object->seq2) . '.barcode_matched');
            @file_expected = <$in>;
            is_deeply (\@file_got,\@file_expected, 'Sequence 2 corrected filtered');

            # Test Output info
            open($in,'<', $object->output_path.'/barcode_filter_info.txt');
            @file_got = <$in>; 
            open($in,'<', $Bin.'/t/files/barcode_filter_info.txt');
            @file_expected = <$in>;
            is_deeply (\@file_got,\@file_expected, 'Filter info.txt is ok');


        }
      
    }

# MyApp::Base::Bowtie 
#-------------------------------------------------------------------------------------------------------
    testclass exercises MyApp::Base::Bowtie {
        # Test::Most has been magically included
        # 'warnings' and 'strict' are turned on

        use File::Basename;

        test constructor >> 3 {
            $attr{seq1} = $Bin.'/t/files/bowtie/reads/e_coli_1000.fq';
            delete $attr{seq2};
            my $class = $test->subject;
            can_ok $class, 'new';
            ok $object = $class->new( %attr ),
              '... and the constructor should succeed';
            isa_ok $object, $class, '... and the object it returns';
        }
         
        test run_bowtie {

           my $got = $object->run_bowtie;

           is $got, 0;

#           my @expected = map {qr/$_/} @seqs;
            
#           is_deeply (\@got, \@expected);

        }
    }
    # Description of this command in first help
    sub abstract { 'Test Classes and Methods'; }


    # method used to run the command
    sub execute {
        my ( $self, $opt, $args ) = @_;
        Test::Class->runtests;
    }

}
1;


#-------------------------------------------------------------------------------------------------------
# Running the Application 
#-------------------------------------------------------------------------------------------------------
package main;
{
    MyApp->run;
}
1;
 
