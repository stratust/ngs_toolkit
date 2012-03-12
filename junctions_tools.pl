#!/usr/bin/env perl

use Moose;
use MooseX::Declare;
use 5.10.0;

=cut
class MooseX::Bio::DB::Bam::Query {
    has 'display_name' => (
        is            => 'rw',
        isa           => 'Str',
        required      => 0,
    );
 
    has 'start' => (
        is            => 'rw',
        isa           => 'Int',
        required      => 0,
    );

    has 'end' => (
        is            => 'rw',
        isa           => 'Int',
        required      => 0,
    );

    has 'dna' => (
        is       => 'rw',
        isa      => 'Str',
        required => 0,
    );

    has 'primary_tag' => (
        is       => 'rw',
        isa      => 'Str',
        required => 0,
    );

    has 'source_tag' => (
        is       => 'rw',
        isa      => 'Str',
        required => 0,
    );

    has 'seq' => (
        is       => 'rw',
        isa      => 'Object',
        required => 0,
    );

#    has 'qscore' => (
        #is       => 'rw',
        #isa      => 'ArrayRef[Int]',
        #required => 0,
    #);

    has 'strand' => (
        is       => 'rw',
        isa      => 'Int',
        required => 0,
    );

}

class MooseX::Bio::DB::Bam::Alignment {
     
    has 'seq_id' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has 'start' => (
        is       => 'rw',
        isa      => 'Int',
        required => 1,
    );

    has 'end' => (
        is       => 'rw',
        isa      => 'Int',
        required => 1,
    );
    has 'length' => (
        is       => 'rw',
        isa      => 'Int',
        required => 1,
    );

    has 'strand' => (
        is       => 'rw',
        isa      => 'Int',
        required => 1,
    );
    has 'mstrand' => (
        is       => 'rw',
        isa      => 'Int',
        required => 1,
    );

    has 'dna' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

     has 'seq' => (
        is       => 'rw',
        isa      => 'Object',
        required => 1,
    );
      has 'query' => (
        is       => 'rw',
        isa      => 'Object',
        required => 1,
    );
     has 'target' => (
        is       => 'rw',
        isa      => 'Object',
        required => 1,
    );
#    has 'hit' => (
        #is       => 'rw',
        #isa      => 'Object',
        #required => 1,
    #);
      has 'primary_id' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

     has 'cigar_str' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has 'ref_padded' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );
      has 'matches_padded' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );
    has 'query_padded' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );
    has 'aux' => (
        is            => 'rw',
        isa           => 'Str',
        required      => 1,
    );
     has 'tam_line' => (
        is            => 'rw',
        isa           => 'Str',
        required      => 1,
    );
 
    method padded_alignment() {

        return ( $self->ref_padded, $self->matches_padded, $self->query_padded );

    }

}

# Build a fake Bio::DB::Bam::Alignment object
# to be able to store in KiokuDB
class Fake::Bio::DB::Bam {
    use Data::Dumper;
    import MooseX::Bio::DB::Bam::Alignment;
    import MooseX::Bio::DB::Bam::Query;

    method fake_align_obj($align) {
        
        # create fake query Object
        my $fake_query = MooseX::Bio::DB::Bam::Query->new(
            display_name => $align->query->display_name,
            start        => $align->query->start,
            end          => $align->query->end,
            dna          => $align->query->dna,
            primary_tag  => $align->query->primary_tag,
            source_tag   => $align->query->source_tag,
            seq          => $align->query->seq,
#            qscore       => $align->query->qscore,
            strand       => $align->query->strand,
        );
 
        # create fake target Object
        my $fake_target = MooseX::Bio::DB::Bam::Query->new(
            display_name => $align->target->display_name,
            start        => $align->target->start,
            end          => $align->target->end,
            dna          => $align->target->dna,
            primary_tag  => $align->target->primary_tag,
            source_tag   => $align->target->source_tag,
            seq          => $align->target->seq,
#            qscore       => $align->target->qscore,
            strand       => $align->target->strand,
        );
        

        my ($ref,$matches,$query) = $align->padded_alignment;

        # create fake align Object
        my $fake_align = MooseX::Bio::DB::Bam::Alignment->new(
            'seq_id'         => $align->seq_id,
            'start'          => $align->start,
            'end'            => $align->end,
            'length'         => $align->length,
            'strand'         => $align->strand,
            'mstrand'        => $align->mstrand,
            'dna'            => $align->dna,
            'seq'            => $align->seq,
            'query'          => $fake_query,
            'target'         => $fake_target,
#            'hit'            => $align->hit,
            'primary_id'     => $align->primary_id,
            'cigar_str'      => $align->cigar_str,
            'ref_padded'     => $ref,
            'matches_padded' => $matches,
            'query_padded'   => $query,
            'aux'            => $align->aux,
            'tam_line'       => $align->tam_line,

        );
        
        return $fake_align;
    }

}
=cut 

class Target::Classification {

    use MooseX::Attribute::Dependent;

    has 'is_translocation' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['is_rerrangement'],
    );

    has 'is_rearrangement' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['is_translocation'],
    );

    has 'is_inversion' => (
        is            => 'rw',
        isa           => 'Bool',
    );

    has 'is_blunt' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['has_deletion'],
    );

    has 'has_deletion' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['is_blunt'],
    );

    has 'deletion_size' => (
        is            => 'rw',
        isa           => 'Int',
        dependency => All['has_deletion'],
    );

    has 'has_insertion' => (
        is            => 'rw',
        isa           => 'Bool',
    );

    has 'insertion_size' => (
        is            => 'rw',
        isa           => 'Int',
        dependency => All['has_insertion'],
    );

    has 'has_microhomology' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['has_insertion'],
    );

    has 'microhomology_size' => (
        is            => 'rw',
        isa           => 'Int',
        dependency => All['has_microhomology'],
    );


    
}

# This is just a Main Cmd:App - don't touch
class MyApp extends MooseX::App::Cmd {

}

class MyApp::Command {
    # A Moose role for setting attributes from a simple configfile
    # It uses Config:Any so it can handle many formats (YAML, Apace, JSON, XML, etc..)
    with 'MooseX::SimpleConfig';

    # Control the '--configfile' option
    has '+configfile' => (
        traits      => ['Getopt'],
        cmd_aliases => 'c',
        isa         => 'Str',
        is          => 'rw',
        required    => 1,
        documentation => 'Configuration file (accept the following formats: YAML, CONF, XML, JSON, etc)',
    );

}

class MyApp::Command::Classify {
    extends 'MooseX::App::Cmd::Command';
    use MooseX::FileAttribute;
    use Carp;
    use Bio::DB::Sam;
    use Data::Dumper;
    use List::Util qw(max);
    use Text::Padding;
    import Fake::Bio::DB::Bam;

    # Class attributes (program options - MooseX::Getopt)
    has_file 'input_file' => (
        traits        => ['Getopt'],
        cmd_aliases   => 'i',
        required      => 1,
        must_exist    => 1,
        documentation => 'Input file to be processed',
    );
    
    has_file 'fasta_file' => (
        traits        => ['Getopt'],
        cmd_aliases   => 'f',
        required      => 0,
        must_exist    => 1, 
        documentation => 'Chromosome fasta file',
    );

    has 'bait_position' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'b',
        required      => 0,
        default       => 'chr15:61818182-61818333',
        documentation => 'Bait position (from primer to break). Default: chr15:61818182-61818333',
    );

    has_file 'alignment_output_file' => (
        traits        => ['Getopt'],
        cmd_aliases   => 'a',
        required      => 0,
        must_exist    => 0,
        default => 'alignments_file.txt',
        documentation => 'Name given for alignment file generated (default: alignments_file.txt)',
    );

    has 'output_path' => (
        is            => 'rw',
        isa           => 'Str',
        traits        => ['Getopt'],
        cmd_aliases   => 'o',
        required      => 0,
        default => '.',
        documentation => 'Path where the genereated files will be placed',
    );
    
    
   
    # Description of this command in first help
    sub abstract { 'Classify rearrangements in a BAM file'; }

=head2 match_all_positions

 Title   : match_all_positions
 Usage   : match_all_positions($regex,$string)
 Function: Given a string and a regex pattern return all start,end for each
 match
 Returns : An array of arrays with [ star, end ] position of matches
 Args    : pattern and a string

=cut 

    method match_all_positions( Str $regex, Str $string ) {

        my @ret;

        while ( $string =~ /$regex/g ) {
            push @ret, [ $-[0], $+[0] ];
        }

        return @ret;

    }

    method get_start_end( Str $regex, Str $string ) {

        my @pos = $self->match_all_positions( $regex, $string );
        return ( $pos[0]->[0], ( $pos[$#pos]->[1] - $pos[0]->[0]));

    }

    method fix_padded_alignment( Object $align ) {

        my ( $ref, $match, $query ) = $align->padded_alignment;
        my ( $offset, $length ) = $self->get_start_end( '\|', $match );
        my $new_ref   = substr $ref,   $offset, $length;
        my $new_match = substr $match, $offset, $length;
        my $new_query = substr $query, $offset, $length;
        return ($new_ref,$new_match,$new_query);

    }

    method split_string( Str $string, Num $step = 60 ) {

        my @splited = $string =~ /.{1,$step}/g;

        return @splited;
    }

    method pretty_alignment( Object $align) {

        # Getting the alignment fixed.
        my ( $ref, $match, $query ) = $self->fix_padded_alignment($align);
        
        # Defining the padding for position numbers based on max chromosome
        # position
        my $string_pos_length = max(length($align->start), length($align->end));
        my $read = $align->query;
        my $pad = Text::Padding->new();
        
        
        # Define the reference start (always '+' strand)
        my $ref_start = $align->start;
        
        # Define the query start (strand dependent)
        my $query_start;
        
        # Keep the ">>>" or "<<<" to add to match line
        my $direction;

        # Strand matters
        # Postitive strand
        if ( $align->strand == 1 ) {
            $query_start = $align->query->start;
            $direction .= '>' for 1 .. $string_pos_length;
        }
        # Negative strand
        else{
            $query_start = length($align->query->seq->seq) - $align->query->start;
            $direction .= '<' for 1..$string_pos_length;
        }
 
        # Spliting sequence
        my $step = 60;
        my @refs    = $self->split_string( $ref,   $step );
        my @matches = $self->split_string( $match, $step );
        my @queries = $self->split_string( $query, $step );


        # Building Alignment representation
        #==========================================================================
        my @alignment;

        for ( my $i = 0 ; $i <= $#refs ; $i++ ) {

            # Calculate position in reference (indels are not taken into account)
            # -------------------------------------------------------------------

            my $ref_part = $refs[$i];
            $ref_part =~ s/\-//g;

            # remove one because is zero based
            my $ref_part_length = length($ref_part) - 1;

            push(
                @alignment,
                "\t"
                  . $pad->left( $ref_start, $string_pos_length ) . " "
                  . $refs[$i] . " "
                  . $pad->left(
                    ( $ref_start + $ref_part_length ),
                    $string_pos_length
                  )
            );

            # Calculate match line
            # --------------------------
            push( @alignment,
                "\t" . $direction . " " . $matches[$i] . " " . $direction );



            # Calculate position in query (indels are not taken into account)
            # -------------------------------------------------------------------
            my $query_part = $queries[$i];
            $query_part =~ s/\-//g;

            # remove one because is zero based
            my $query_part_length = length($query_part) - 1;

            if ( $align->strand == 1 ) {

                push(
                    @alignment,
                    "\t"
                      . $pad->left( $query_start, $string_pos_length ) . " "
                      . $queries[$i] . " "
                      . $pad->left(
                        ( $query_start + $query_part_length ),
                        $string_pos_length
                      )
                );
                
                # Query step if strand +
                $query_start += $query_part_length + 1;

            }
            else {

                push(
                    @alignment,
                    "\t"
                      . $pad->left( $query_start, $string_pos_length ) . " "
                      . $queries[$i] . " "
                      . $pad->left(
                        ( $query_start - $query_part_length ),
                        $string_pos_length
                      )
                );

                # Query step if strand -
                $query_start -= $query_part_length + 1;

            }

            # Reference step (is always +)
            $ref_start += $ref_part_length + 1;

        }

        return @alignment;    

    }

=cut

    Given a read splitting in two fragments in the same chromosome:

    ***********************
    * Legend:             *
    *                     *
    * > or < : direction  *
    *                     *
    * # : break junction  *
    *                     *
    ***********************

    When a bait(primer) and target have the same orientation

                ----------       E      S
                | Primer |------>#      #-------->
                ----------

    S           ----------       E
    #------->   | Primer |------>#
                ----------
 
   Possibly a microhomology:

                ----------       E  
                | Primer |------>#      
                ----------   #------->
                             S
  
    
    When a bait(primer) and target have different orientation

                ----------       E               E
                | Primer |------>#      <--------#
                ----------

            E   ----------       E
    <-------#   | Primer |------>#
                ----------


    This shouldn't be a microhomology because reads have different directions

                ----------       E  
                | Primer |------>#      
                ----------   <-------#
                                     E
   
   RULES OF THE THUMB:
   
   1) Bait and targets in the same direction have junctions in END of the Bait
   and in the START of the target
   2) Bait and targets in different directons have junctions in END of the Bait
   and in the END of the target
   3) Microhomology just occurs when the bait and target are in the same
   strand

=cut
    
    method cluster_alignments( HashRef $alignments_to_cluster) {

        my %cluster;
        foreach my $read_id (keys %{$alignments_to_cluster}){
        
                # INDEXING BY BREAK POINT (removing PCR duplicates)
                
                # Building key
                
                my $bait = $alignments_to_cluster->{$read_id}->{bait};
                
                my $bait_strand = '+';
                
                $bait_strand = '-' if $bait->strand == -1;
                
                # Get read start and end
                my ($bait_query_end, $bait_query_start);
                
                # For the read strand matters
                if ($bait_strand  eq '+'){
                    $bait_query_end= $bait->query->end;
                    $bait_query_start = $bait->query->start;
                }
                else{
                    $bait_query_end = ( 
                        length($bait->query->seq->seq) - $bait->query->end 
                    );

                    $bait_query_start = ( 
                        length($bait->query->seq->seq) - $bait->query->start
                    );

                }

                my $key = $bait->seq_id.'_'.$bait->end.'_'.$bait_strand;
                next unless $alignments_to_cluster->{$read_id}->{targets};

                my %targets = %{$alignments_to_cluster->{$read_id}->{targets}};

                #Index targets by chromosome
                
                # Sorting by read start
                foreach my $query_start ( sort { $a <=> $b } keys %targets ) {
                    
                    # Usualy Should have just one splice here 
                    foreach my $target ( @{ $targets{$query_start} } ) {

                        my $chr    = $target->seq_id;
                        my $strand = '+';
                        $strand = '-' if $target->strand == -1;


                        my ($target_query_end, $target_query_start);

                        if ( $strand eq '+' ) {
                            $target_query_end   = $target->query->end;
                            $target_query_start = $target->query->start;
                        }
                        else {
                            $target_query_end = (
                                length( $target->query->seq->seq ) -
                                  $target->query->end );

                            $bait_query_start = (
                                length( $target->query->seq->seq ) -
                                  $target->query->start );

                        }

                        # Keep diff between bait and target
                        # Necessary to know if is blunt, insertion or deletion
                        my $diff_read;

                        if ( $strand eq $bait_strand ) {
                            
                            if ( $bait_strand eq '+'){
                                $diff_read = $target_query_start - $bait_query_end;
                            }
                            else{
                            
                                $diff_read = $bait_query_start - $target_query_end; 
                            }

                            $key .=
                            '|'.$target->seq_id.'_'.$target->start.'_'.$strand;

                        }
                        else {
                            if ( $bait_strand eq '+'){
                                $diff_read =  $target_query_end -
                                $bait_query_end;
                            }
                            else{
                            
                                $diff_read = $bait_query_start - $target_query_start;
                            }


                            $key .= '|'.$target->seq_id.'_'.$target->end.'_'.$strand;
                        }

                        # Add diff to key
                        $key .= '_'.$diff_read;
                    }
                }
                push @{$cluster{$key}},$alignments_to_cluster->{$read_id};
          }
          return \%cluster;
    }

=head2 show_clusters_alignment

 Title   : show_clusters_alignment
 Usage   : show_clusters_alignment()
 Function: 
 Returns : 
 Args    : clusters ref 

=cut 

    method show_clusters_alignment( HashRef $cluster) {

        open( my $out, '>', $self->output_path.'/'.$self->alignment_output_file );
        

        foreach my $break ( keys %{$cluster} ) {
            my @reads = @{$cluster->{$break}};

            say $out 'BREAK: '.$break."\treads:\t" .scalar @reads;
            say $out
            '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++';
            say $out '';
            foreach my $read (@reads) {

                my $bait = $read->{bait};
                say $out ">"
                  . $bait->query->display_name . " ("
                  . length( $bait->target->seq->seq ) . "pb)";
                say $out join "\n",
                  $self->split_string( $bait->target->seq->seq );
                say $out "";

                say $out " BAIT ("
                  . $bait->seq_id . ":"
                  . $bait->start . "-"
                  . $bait->end . " "
                  . $bait->strand . ") ("
                  . $bait->query->start . " "
                  . $bait->query->end . "):\n";

                say $out join "\n", $self->pretty_alignment($bait);

                say $out "";


                foreach my $qstart ( sort {$a <=> $b} keys %{ $read->{targets} } ) {


                    foreach my $f ( @{ $read->{targets}->{$qstart} } ) {
                   #     say $out ">" 
                          #. $f->query->display_name . " ("
                          #. length( $f->target->seq->seq ) . "pb)";
                        #say $out join "\n",
                          #$self->split_string( $f->target->seq->seq );
                        #say $out "";

                        

                        say $out " PARTNER ("
                          . $f->seq_id . ":"
                          . $f->start . "-"
                          . $f->end . " "
                          . $f->strand . ") ("
                          . $f->query->start. " "
                          . $f->query->end
                          . "):\n";


                        say $out join "\n", $self->pretty_alignment($f);

                        say $out "";
                    }
                }
                        say $out "";
                        say $out "----------------------------------------------------------------------------";
 

            }

        }

        close( $out );

    }
    
=head2 classify

 Title   : classify
 Usage   : classify()
 Function: 
 Returns : A hash of rearrangements with classification
 Args    : Hashref of clustered reads by break point

=cut 

    method classify( HashRef $alignment_cluster) {
        use Graph::Convert;
        import Target::Classification;
       
        my $g = Graph->new();
        
        #Get break position;
        my ($bait_real_chr,$bait_real_start,$bait_real_end);
        ($bait_real_chr,$bait_real_start,$bait_real_end) = ($1,$2,$3) if $self->bait_position =~ /(\S+):(\d+)-(\d+)/;

        my %classification;

        foreach my $break (keys %{$alignment_cluster}){
            
            my @splices = split /\|/,$break;

            #next if (/chr15/ ~~ @splices[1..$#splices]);
            
            
            # Getting bait position
            my (
                $alignment_bait_chr,
                $alignment_bait_end, $alignment_bait_strand
            );
            (
                $alignment_bait_chr,
                $alignment_bait_end, $alignment_bait_strand
              )
              = ( $1, $2, $3 )
              if $splices[0] =~ /(\S+)_(\d+)_(\S+)/;

            # Calculate Bait deletion size
            my $deletion_size = $bait_real_end - $alignment_bait_end;
            
            # Skipping if deletion size is negative
            # (maybe real but difficult to explain)
            next if $deletion_size < 0;

            $g->add_vertex("$splices[0]");

            $g->set_vertex_attributes(
                $splices[0], 
                {
                    fill => 'red',
                    'x-resection' => $deletion_size,
                }
            );

            # Skip bait (index 0) and get target information
            for (my $i = 1; $i <= $#splices; $i++) {

            my (
                $alignment_target_chr,     $alignment_target_start,
                $alignment_target_strand, $target_difference
            );

            (
                $alignment_target_chr,     $alignment_target_start,
                $alignment_target_strand, $target_difference
              )
              = ( $1, $2, $3, $4 )
              if $splices[$i] =~ /^(\S+)_(\d+)_(\S+)_(\S+)/;


                # CLASSIFICATION ALGORITHM
                # ---------------------------------------------------------
                # create a hash with empty atributtes

                my $target_class = Target::Classification->new();

                # Rearrangements
                if ($bait_real_chr eq $alignment_target_chr){

                    $target_class->is_rearrangement(1);

                }
                # Traslocations
                # --------------
                else{

                    $target_class->is_translocation(1);
                }

                # * Base on strand of the target related to bait
                #  - inversions
                $target_class->is_inversion(1)
                  if ( $alignment_bait_strand ne $alignment_target_strand );

                # * Based on bait genomic position (deletions are found in the
                # genome, insertion and microhomology in the read):
                #  - Blunt 
                #  - Deletion
                #  - Blunt with Insertion
                #  - Deletion with Insertion
                #  - Micromolology
                
                if ($bait_real_end == $alignment_bait_end){
                
                    $target_class->is_blunt(1);

                }
                else {
                    $target_class->has_deletion(1);
                    $target_class->deletion_size($deletion_size);

                }
                
                if ($target_difference > 0 ){
                    $target_class->has_insertion(1);
                    $target_class->insertion_size($target_difference);

                }
                elsif ($target_difference < 0 ){
                    $target_class->has_microhomology(1);
                    $target_class->microhomology_size(abs($target_difference));
                }
                 


                $g->add_vertex("$splices[$i]");

                $g->set_vertex_attributes(
                    $splices[$i],
                    {
                        fill        => 'blue'
                    }
                ) if $splices[$i] =~  /chr12_/;

                $g->add_edge("$splices[0]","$splices[$i]");

                push(@{$classification{$break}},$target_class);
            }
        }

        my %size;


        my @types = ( 'deletion', 'insertion', 'microhomology' );

        foreach my $break ( keys %classification ) {

            # get only the first one
            my $target = shift @{ $classification{$break} };

            # For all

            foreach my $type (@types) {

                my $has_type  = "has_$type";
                my $type_size = $type . "_size";

                if ( $target->$has_type ) {
                    $size{'all'}{$type}{ $target->$type_size }++;
                }
                else {
                    $size{'all'}{$type}{0}++;
                }

                #For translocation only
                if ( $target->is_translocation ) {

                    if ( $target->$has_type ) {
                        $size{translocations}{$type}{ $target->$type_size }++;
                    }
                    else {
                        $size{translocations}{$type}{0}++;
                    }

                }

                #For rearrangement
                if ( $target->is_rearrangement ) {

                    if ( $target->$has_type ) {
                        $size{rearrangements}{$type}{ $target->$type_size }++;
                    }
                    else {
                        $size{rearrangements}{$type}{0}++;
                    }

                }
            }

        }


        my @keys = ( 'all', 'translocations', 'rearrangements' );
        my $total_reads = scalar(keys %classification);
        foreach my $key (@keys) {
            foreach my $type (@types){

                my @aux = keys %{$size{$key}{$type}};
                my $max = max @aux;
                my $output_file =  $self->output_path."/".$key."_".$type;
                open( my $out, '>', $output_file.".txt" );
                
                say $out "position\tcount\tfreq";

                my $total_reads_key = 0;
                $total_reads_key += $_ for values %{$size{$key}->{$type}};

                for (my $i = 0; $i <= $max; $i++) {

                    # print position | count | freq
                    if ($size{$key}->{$type}->{$i}){
                        say $out
                        $i."\t".$size{$key}->{$type}->{$i}."\t".(($size{$key}->{$type}->{$i}/$total_reads_key) * 100 );
                    }
                    else{
                        say $out "$i\t0\t0";
                    }

                }

                close($out);

                use Statistics::R;

                # Create a communication bridge with R and start R
                my $R = Statistics::R->new();

                # Run simple R commands
                $R->set('file',$output_file.'.txt');
                $R->set('title',ucfirst($type). " in $key");
                $R->set('title',ucfirst($type). " in all events") if $key eq 'all';
                my $xlabel="Distance from I-Sce1 site in bp";
                if ($type eq 'microhomology'){
                    $xlabel = "Microhomology size in pb";
                }
                $R->set('xlabel', $xlabel);
                $R->set('ylabel', 'Frequency');
 
                $R->run(q`x = read.delim(file)`);
                my $output_graphic = "$output_file.pdf";
                $R->run(
                    qq`pdf("$output_graphic" , width=8, height=6,pointsize=1)`
                );
                $R->run(q`barplot(x$freq,names.arg=x$position,xlab=xlabel,ylab=ylabel,main=title,col='black',axis.lty=1,cex.names=,7)`);
                $R->run(q`dev.off()`);

                $R->stop();

            }
            
        }


        my $ge = Graph::Convert->as_graph_easy($g);

      
        # Graphviz:
        my $graphviz = $ge->as_graphviz();
        open (my $out,'>','ge_graph.dot') or die ("Cannot open pipe to dot: $!");
        print $out $graphviz;
        close ($out);

        my @nodes = $g->vertices;
 
        #foreach my $node (@nodes){
            #say
            #$node.":\tin(".$g->in_degree($node).")\tout(".$g->out_degree($node).")";
            #my $color = $g->get_vertex_attribute($node,'fill');
            #say $color if $color;
        # }

    }

=head2 get_reliable_alignments

 Title   : get_reliable_alignments
 Usage   : get_reliable_alignments()
 Function: 
 Returns : Hashref with Complex structure
         {
         sequence_id => {
               bait => align_obj,
               targets => [
                   align_obj,
                   align_obj
               ]
           }
         } 
 
 Args    : 

=cut 

    method get_reliable_alignments() {

        #my $fake = Fake::Bio::DB::Bam->new();

        my $sam = Bio::DB::Sam->new(
            -bam          => $self->input_file,
            -fasta        => $self->fasta_file,
            -autoindex    => 1,
            -split        => 1,
            -expand_flags => 1
        );
        
        my ($chr,$start,$end);
        ($chr,$start,$end) = ($1,$2,$3) if $self->bait_position =~ /(\S+):(\d+)-(\d+)/;

        my @alignments = $sam->get_features_by_location(
            -seq_id => $chr,
            -start  => $start,
            -end    => $end,
            -type   => 'match',
        );

        
        my @names;
        my %bait;


        for my $a (@alignments) {

            my $name =  $a->query->display_name;
            push @names,$name;
            #my $fake_align = $fake->fake_align_obj($a);

            #$bait{$name} = $fake_align;
            push @{$bait{$name}}, $a;

        }
        
        # Count number of reads with the same name that overlap the region
        my %seen;
        $seen{$_}++ foreach (@names);


        my @duplicated_baits_reads = grep { $seen{$_} > 1} keys %seen;
        my @uniq_bait_reads =  grep { $seen{$_} == 1} keys %seen;

        

        #say scalar @duplicated_baits_reads;
        say $_ for @duplicated_baits_reads;
        #say scalar @uniq_bait_reads;
        #say scalar keys %seen;
        
        # Index BAM
        say "Index BAM by name";
        my %reads;

        my @all_alignments = $sam->features;

        foreach my $a (@all_alignments){
            push(@{$reads{$a->query->display_name}}, $a)
        }


        say "Creating reads to cluster";
        

        # $alignments_to_cluster{'sequence_id'} = {
        #       bait => align_obj,
        #       targets => [
        #           align_obj,
        #           align_obj
        #       ]
        #   }
        # 
        my %alignments_to_cluster;
        say "Total of reads to search:". scalar @uniq_bait_reads;
        my $z =0;

        #foreach my $seq_id (@uniq_bait_reads) {
        foreach my $seq_id ( keys %seen ) {
                $z++;
                say "Searching for read: $seq_id ($z)";
                #my @features = $sam->get_features_by_name($seq_id);
                my @features = @{$reads{$seq_id}};
                

                # define the smallest alignment start as bait
                my @aux = sort {$a->start <=> $b->start} @{$bait{$seq_id}};
                my $local_bait = shift @aux;
                $alignments_to_cluster{$seq_id}{bait} = $local_bait;

                foreach my $f (@features) {

                    my $read = $f->query;

                    next if (
                        $read->start == $local_bait->query->start
                        &&
                        $read->end == $local_bait->query->end
                        &&
                        $read->strand eq $local_bait->query->strand,
                    );
                    
                    # indexing by query position
                    my $query_start;

                    if ($f->strand == 1){
                        $query_start = $f->query->start;
                    }
                    else{
                        $query_start = length($f->query->seq->seq) -
                        $f->query->start;
                    }

                    #my $fake_align = $fake->fake_align_obj($f);
                    
                    #push ( @{$alignments_to_cluster{$seq_id}{targets}{$query_start}},
                    #    $fake_align);
                    
                    push ( @{$alignments_to_cluster{$seq_id}{targets}{$query_start}},
                        $f);

                }
        }

        return \%alignments_to_cluster;
 
    }

    # method used to run the command
    method execute ($opt,$args) {
        
        # Given the BAM file, get alignments to cluster.
        # Reliable reads are those which overlap this (hard coded) position:
        # 
        # chr15:61818182-61818333
        #
        # PS: A more general tool should allow the user specify other
        # positions 
        my $reliable_alignments = $self->get_reliable_alignments();

        # print Dumper($reads_to_cluster);
        say "Clustering....";
        my $alignments_cluster = $self->cluster_alignments($reliable_alignments);

        say "Creating Alignment output file..."; 
        $self->show_clusters_alignment($alignments_cluster);

        say "Classifying aligments clusters";
        $self->classify($alignments_cluster);
        
    }

}

class main {
    MyApp->run;
}

