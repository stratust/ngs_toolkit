#!/usr/bin/env perl

use Moose;
use MooseX::Declare;
use 5.10.0;

# Store the log_path
our $log_path;
our $logfile_path;

sub logfile {
    return $logfile_path;
}

# Log Role
role MyApp::Log {
    use Log::Log4perl qw(:easy);
    with 'MooseX::Log::Log4perl::Easy';
 
    use Cwd 'abs_path';
    use File::Basename;
    use File::Path;

    # Configuring log 
    BEGIN {
        my $logconf_file    = 'log4perl.conf';
        my $log_conf_path   = '';
        my $full_path       = abs_path($0);
        my $script_path     = dirname($full_path);
        my $current_path    = &Cwd::cwd();
        my $script_filename = basename($full_path);
        my $script_name     = $script_filename;

        # Removing extension
        $script_name =~ s/\.\S+$//;
        
        $log_path = &Cwd::cwd().'/logs/';
        unless (-e $log_path){
            mkpath($log_path);
        }
        $logfile_path = $log_path . $script_name . '.log';
        my $logtracefile_path = $log_path . $script_name . '_trace.log';


        # Verifify conf path
        if ( -d $current_path . '/conf' ) {
            $log_conf_path = $current_path.'/conf/';
        }
        elsif ( -d $current_path . '/../conf' ) {
            $log_conf_path = $current_path. '/../conf/';
        }

        # Name of the custom file: "script_name"_log4perl.conf
        my $personal_logconf_file = $script_name . '_log4perl.conf';

        if ( -e $current_path . $personal_logconf_file ) {
            $logconf_file = $personal_logconf_file;
        }

        $log_conf_path .= $logconf_file
          if ( -e $log_conf_path . $logconf_file );
       
        if ($log_conf_path){
            Log::Log4perl->init($log_conf_path);
        }
        else {
            Log::Log4perl->init(
                \qq{

                log4perl.rootLogger = TRACE, LOGFILE, Screen, AppTrace

                # Filter to match level ERROR
                log4perl.filter.MatchError = Log::Log4perl::Filter::LevelMatch
                log4perl.filter.MatchError.LevelToMatch  = ERROR
                log4perl.filter.MatchError.AcceptOnMatch = true
 
                # Filter to match level DEBUG
                log4perl.filter.MatchDebug = Log::Log4perl::Filter::LevelMatch
                log4perl.filter.MatchDebug.LevelToMatch  = DEBUG
                log4perl.filter.MatchDebug.AcceptOnMatch = true
 
                # Filter to match level WARN
                log4perl.filter.MatchWarn  = Log::Log4perl::Filter::LevelMatch
                log4perl.filter.MatchWarn.LevelToMatch  = WARN
                log4perl.filter.MatchWarn.AcceptOnMatch = true
 
                # Filter to match level INFO
                log4perl.filter.MatchInfo  = Log::Log4perl::Filter::LevelMatch
                log4perl.filter.MatchInfo.LevelToMatch  = INFO
                log4perl.filter.MatchInfo.AcceptOnMatch = true
 
                # Filter to match level TRACE
                log4perl.filter.MatchTrace  = Log::Log4perl::Filter::LevelMatch
                log4perl.filter.MatchTrace.LevelToMatch  = TRACE
                log4perl.filter.MatchTrace.AcceptOnMatch = true
 
                # Filter to match level TRACE
                log4perl.filter.NoTrace  = Log::Log4perl::Filter::LevelMatch
                log4perl.filter.NoTrace.LevelToMatch  = TRACE
                log4perl.filter.NoTrace.AcceptOnMatch = false


                log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
                log4perl.appender.LOGFILE.filename= $logfile_path
                log4perl.appender.LOGFILE.mode=append
                log4perl.appender.LOGFILE.layout=Log::Log4perl::Layout::PatternLayout
                log4perl.appender.LOGFILE.layout.ConversionPattern=%d %p> %F{1}:%L %M%n%m%n%n
                log4perl.appender.LOGFILE.Filter = NoTrace

                # Error appender
                log4perl.appender.AppError = Log::Log4perl::Appender::File
                log4perl.appender.AppError.filename = $logfile_path
                log4perl.appender.AppError.layout   = SimpleLayout
                log4perl.appender.AppError.Filter   = MatchError
 
                # Warning appender
                log4perl.appender.AppWarn = Log::Log4perl::Appender::File
                log4perl.appender.AppWarn.filename = $logfile_path
                log4perl.appender.AppWarn.layout   = SimpleLayout
                log4perl.appender.AppWarn.Filter   = MatchWarn

                # Debug  appender
                log4perl.appender.AppDebug = Log::Log4perl::Appender::File
                log4perl.appender.AppDebug.filename = $logfile_path
                log4perl.appender.AppDebug.layout   = SimpleLayout
                log4perl.appender.AppDebug.Filter   = MatchDebug

                # Trace  appender
                log4perl.appender.AppTrace = Log::Log4perl::Appender::File
                log4perl.appender.AppTrace.filename = $logtracefile_path
                log4perl.appender.AppTrace.layout   = SimpleLayout
                log4perl.appender.AppTrace.Filter   = MatchTrace

                # Screen Appender (Info only)
                log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
                log4perl.appender.Screen.stderr = 0
                log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
                log4perl.appender.Screen.layout.ConversionPattern = %d %m %n
                log4perl.appender.Screen.Filter = MatchInfo


            });
        }
    }
}

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

    has 'bait_is_blunt' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['bait_deletion_size'],
    );

    has 'target_is_blunt' => (
        is            => 'rw',
        isa           => 'Bool',
        dependency => None['target_deletion_size','is_translocation'],
    );


    has 'bait_deletion_size' => (
        is            => 'rw',
        isa           => 'Int',
        dependency => None['is_blunt'],
        predicate => 'has_bait_deletion',
    );

    # target deletion will be accepted only for rearrangements
    has 'target_deletion_size' => (
        is            => 'rw',
        isa           => 'Int',
        dependency => None['target_is_blunt','is_translocation'],
        predicate => 'has_target_deletion',
    );

    has 'insertion_size' => (
        is            => 'rw',
        isa           => 'Int',
        predicate => 'has_insertion'
    );

    has 'microhomology_size' => (
        is            => 'rw',
        isa           => 'Int',
        predicate => 'has_microhomology'
    );
    
}

# This is just a Main Cmd:App - don't touch
class MyApp extends MooseX::App::Cmd {

}

class MyApp::Command {
    # A Moose role for setting attributes from a simple configfile
    # It uses Config:Any so it can handle many formats (YAML, Apace, JSON, XML, etc..)
    with 'MooseX::SimpleConfig';
    with 'MyApp::Log';

    use List::MoreUtils;

    # Control the '--configfile' option
    has '+configfile' => (
        traits      => ['Getopt'],
        cmd_aliases => 'c',
        isa         => 'Str',
        is          => 'rw',
        required    => 0,
        documentation => 'Configuration file (accept the following formats: YAML, CONF, XML, JSON, etc)',
    );

}

class MyApp::Command::Classify {
    extends 'MooseX::App::Cmd::Command', 'MyApp::Command';
    use MooseX::FileAttribute;
    use Carp;
    use Bio::DB::Sam;
    use Data::Dumper;
    use List::Util qw(max min sum);
    use Text::Padding;

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
        default       => 'chr15:61818182-61818339',
        documentation => 'Bait position (from primer to break). Default: chr15:61818182-61818339',
    );

    has 'enzime_restriction_size' => (
        is            => 'rw',
        isa           => 'Int',
        traits        => ['Getopt'],
        cmd_aliases   => 'b',
        required      => 0,
        default       => '4',
        documentation => 'How much restriction enzime will cleave from bait
        site. Default: 4',
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

     has 'fragment_size' => (
         is            => 'rw',
         isa           => 'Int',
         traits        => ['Getopt'],
         cmd_aliases   => 's',
         required      => 1,
         default       => 36,
         documentation => 'Mininum fragment size to be analyzed (for bait and target). Default: 36',
     );
     
      has 'min_mapq' => (
         is            => 'rw',
         isa           => 'Int',
         traits        => ['Getopt'],
         cmd_aliases   => 'q',
         required      => 1,
         default       => 30,
         documentation => 'Mininum SAM MAPQ each fragment should have to be analyzed (for bait and target). Default: 30',
     );
    
      our $reads_to_clustering;
    
   
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
    
    method clustering_alignments( HashRef $alignments_to_cluster) {

        my ($chr,$start,$end);
        ($chr,$start,$end) = ($1,$2,$3) if $self->bait_position =~ /(\S+):(\d+)-(\d+)/;

        my %cluster;
        foreach my $read_id ( keys %{$alignments_to_cluster} ) {

            # INDEXING BY BREAK POINT (removing PCR duplicates)

            # Building key
            
            # If is bait only, key was already built
            if ($alignments_to_cluster->{$read_id}->{key}){
                my $this_key = $alignments_to_cluster->{$read_id}->{key};
                push @{ $cluster{$this_key} },
                  $alignments_to_cluster->{$read_id};

                next;
            }

            # Bio::DB::Sam alignment object
            my $bait = $alignments_to_cluster->{$read_id}->{bait};

            my $bait_strand = '+';

            $bait_strand = '-' if $bait->strand == -1;

            # Get read start and end
            my ( $bait_query_end, $bait_query_start );

            # For reads strand matters
            if ( $bait_strand eq '+' ) {
                $bait_query_end   = $bait->query->end;
                $bait_query_start = $bait->query->start;
            }
            else {
                $bait_query_end =
                  ( length( $bait->query->seq->seq ) - $bait->query->end );

                $bait_query_start =
                  ( length( $bait->query->seq->seq ) - $bait->query->start );

            }

            #Correcting pseudoblunt targens in split-reads:
            # verify if bait pass througth breakpoint
            my $corrected_bait_end = $bait->end;
            if ( $bait->end > ( $end - 1 ) ) {
                $corrected_bait_end = $end;
            }


            my $key = $bait->seq_id . '_' . $corrected_bait_end . '_' . $bait_strand;

            # Skip reads that don't have targets
            #next unless $alignments_to_cluster->{$read_id}->{targets};

            my %targets;
            if ( $alignments_to_cluster->{$read_id}->{targets} ) {
                %targets = %{ $alignments_to_cluster->{$read_id}->{targets} };

                # Sorting by read start
                foreach my $query_start ( sort { $a <=> $b } keys %targets ) {

                    # Usually Should have just one splice here
                    foreach my $target ( @{ $targets{$query_start} } ) {

                        my $chr    = $target->seq_id;
                        my $strand = '+';
                        $strand = '-' if $target->strand == -1;

                        my ( $target_query_end, $target_query_start );

                        if ( $strand eq '+' ) {
                            $target_query_end   = $target->query->end;
                            $target_query_start = $target->query->start;
                        }
                        else {
                            $target_query_end = (
                                length( $target->query->seq->seq ) -
                                  $target->query->end );

                            #$bait_query_start = (
                            #    length( $target->query->seq->seq ) -
                            #      $target->query->start );

                        }

                        # Keep diff between bait and target
                        # Information necessary to know if is blunt, insertion or deletion
                        my $diff_read;

                        if ( $strand eq $bait_strand ) {

                            if ( $bait_strand eq '+' ) {
                                $diff_read =
                                  $target_query_start - $bait_query_end;
                            }
                            else {

                                $diff_read =
                                  $target_query_end - $bait_query_start;
                            }

                            $key .= '|'
                              . $target->seq_id . '_'
                              . $target->start . '_'
                              . $strand;

                        }
                        else {
                            if ( $bait_strand eq '+' ) {
                                $diff_read =
                                  $target_query_end - $bait_query_end;
                            }
                            else {

                                $diff_read =
                                  $bait_query_start - $target_query_start;
                            }

                            $key .= '|'
                              . $target->seq_id . '_'
                              . $target->end . '_'
                              . $strand;
                        }

                        # Add diff to key
                        $key .= '_' . $diff_read;
                    }
                }
            }
            push @{ $cluster{$key} }, $alignments_to_cluster->{$read_id};
        }

        my @summary;
        my $total_clusters = scalar keys %cluster;

        push @summary, "\t- Total number of clusters: "
          . $total_clusters . "("
          . ($total_clusters / $reads_to_clustering * 100)."%)";

        my @clusters_size;
        foreach my $k (keys %cluster){
            push @clusters_size, scalar @{$cluster{$k}};
        }

        my ($min_cluster_size, $max_cluster_size,$avg_cluster_size) =
        (min(@clusters_size), max(@clusters_size),(sum(@clusters_size)/scalar(@clusters_size)));
        
        push @summary, "\t- Mininum number of reads in a cluster: "
          . $min_cluster_size;

        push @summary, "\t- Maximum number of reads in a cluster: "
          . $max_cluster_size;

        push @summary, "\t- Average number of reads in a cluster: "
          . $avg_cluster_size;
        
        push @summary, "\t- Sum of read in clusters: "
          . sum(@clusters_size);


        $self->log_debug(join "\n",@summary);

        return \%cluster;
    }

=head2 show_clusters_alignment

 Title   : show_clusters_alignment
 Usage   : show_clusters_alignment()
 Function: 
 Returns : 
 Args    : clusters ref 

=cut 

    method show_clusters_alignment( HashRef $cluster, HashRef $classification) {

        open( my $out, '>', $self->output_path.'/'.$self->alignment_output_file );
        
        my $meta = Target::Classification->meta;
 
        foreach my $break ( keys %{$cluster} ) {
            my @reads = @{$cluster->{$break}};

            say $out 'BREAK: ' . $break . "\treads:\t" . scalar @reads;
            say $out
            '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++';
            if ($classification) {
                #say Dumper $classification->{$break} unless $classification->{$break}->[0];
                
                    for my $attr ( $meta->get_all_attributes ) {
                        my $name = $attr->name;
                        say $out $name . ":" . $classification->{$break}->[0]->$name
                          if $classification->{$break}->[0]->$name;
                    }

            }
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
        import Target::Classification;
       
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

            # Skip bait (index 0) and get target information
            for (my $i = 1; $i <= $#splices; $i++) {

            my (
                $alignment_target_chr,     $alignment_target_start,
                $alignment_target_strand, $target_difference, $del_before,
                $del_after, $bait_only
            );

            if ($splices[$i] =~ /^(\S+)_(\d+)_([+-])_(-{0,1}\d+)$/){

            (
                $alignment_target_chr,     $alignment_target_start,
                $alignment_target_strand, $target_difference
              )
              = ( $1, $2, $3, $4 );
            }
            elsif ($splices[$i] =~ /^(\S+)_(\d+)_([+-])_(-{0,1}\d+)_(-{0,1}\d+)$/){
             (
                $alignment_target_chr,     $alignment_target_start,
                $alignment_target_strand, $del_before, $del_after
              )
              = ( $1, $2, $3, $4, $5 );
              $bait_only = 1;
              $target_difference = 0;
           
            }
            else {
                die "error ".$break;
            }

                # CLASSIFICATION ALGORITHM
                # ---------------------------------------------------------
                # create a hash with empty atributtes

                my $target_class = Target::Classification->new();

                # * Base on strand of the target related to bait
                #  - inversions
                $target_class->is_inversion(1)
                  if ( $alignment_bait_strand ne $alignment_target_strand );

                # Rearrangements
                if ($bait_real_chr eq $alignment_target_chr){

                    $target_class->is_rearrangement(1);

                    # Looking for deletions of the parter if:
                    #  - Is a rearrangement
                    #  - Split only in two reads
                    
                    if (scalar @splices == 2 ){

                        # calculate target_real_Start
                        my $target_real_start = $bait_real_end + $self->enzime_restriction_size;
                        my $target_deletion = $alignment_target_start - $target_real_start;

                        if ($bait_only){
                            $target_class->target_deletion_size($del_after);
                        }
                        elsif ( (!$target_class->is_inversion) && (
                                $target_deletion > 0 )){
                            $target_class->target_deletion_size($target_deletion);
                        }
                    }

                }
                # Traslocations
                # --------------
                else{

                    $target_class->is_translocation(1);
                }

                # * Based on bait genomic position (deletions are found in the
                # genome, insertion and microhomology in the read):
                #  - Blunt 
                #  - Deletion
                #  - Blunt with Insertion
                #  - Deletion with Insertion
                #  - Micromolology
                
                if ($bait_real_end == $alignment_bait_end){
                
                    $target_class->bait_is_blunt(1);

                }
                else {
                    $target_class->bait_deletion_size($deletion_size);

                }
               
                if ($target_difference > 0 ){
                    $target_class->insertion_size($target_difference);

                }
                elsif ($target_difference < 0 ){
                    $target_class->microhomology_size(abs($target_difference));
                }
                
                 

                push(@{$classification{$break}},$target_class);
            }
        }
        
        $self->log_info("Creating Alignment output file..."); 
        $self->show_clusters_alignment($alignment_cluster, \%classification);


        my %size;

        #$self->log_trace(Dumper(%classification));

        my @types = ( 'bait_deletion', 'target_deletion', 'insertion', 'microhomology' );

        foreach my $break ( keys %classification ) {

            # get only the first one
            my $target = shift @{ $classification{$break} };

            # For all

            foreach my $type (@types) {

                my $has_type  = "has_$type";
                my $type_size = $type . "_size";


                if ( $target->$has_type ) {
    
                    next if $target->$type_size > 10000;

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
                next unless $max;
                my $output_file =  $self->output_path."/".$key."_".$type;
                open( my $out, '>', $output_file.".txt" );
                
                say $out "position\tcount\tfreq";

                my $total_reads_key = 0;
                $total_reads_key += $_ for values %{$size{$key}->{$type}};

                for (my $i = 1; $i <= $max; $i++) {
                    
                    # print position | count | freq
                    if ($size{$key}->{$type}->{$i}){
                        say $out $i . "\t"
                          . $size{$key}->{$type}->{$i} . "\t"
                          . (
                            ( $size{$key}->{$type}->{$i} / $total_reads ) *
                              100 );
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
                $R->set('ylabel', 'Frequency (event/total events)');
 
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
        
        my %bait;

        # Count number of reads with the same name that overlap the region
        my %seen;

        for my $aln (@alignments) {

            my $name =  $aln->query->display_name;
            
            $seen{$name}++;

            # Keep all segments that align in a bait position
            # More than one fragment from the same read can align in this
            # position. Example: A read split in 3 fragments and 2 of them 
            # are in the bait position
            push @{$bait{$name}}, $aln;

        }
        
        my @uniq_bait_reads =  grep { $seen{$_} == 1} keys %seen;
        my @duplicated_bait_reads =  grep { $seen{$_} > 1} keys %seen;
        
        # Index BAM by name using a hash
        # PS: It loads all sequences into system memory. Should be used only
        # with 454 sequences or small datasets
        
        my %reads;

        my @all_alignments = $sam->features;

        my %total_splits_mapped;
        foreach my $aln (@all_alignments){
            push(@{$reads{$aln->query->display_name}}, $aln);
            # total mapped
            $total_splits_mapped{$aln->query->display_name}++ if $aln->qual > 0;
        }
       
        my $total_reads_mapped = scalar (keys %total_splits_mapped);
        
        # $alignments_to_cluster{'sequence_id'} = {
        #       bait => align_obj,
        #       targets => query_start =>  [
        #                                   align_obj,
        #                                   align_obj
        #                                  ]
        #   }
        # 
        my %alignments_to_cluster;
        
        # uncomment this line if you want to allow bait align more than one
        # time in the region
        #foreach my $seq_id ( keys %seen ) {

        # Just allow one alignment in the bait region (reads cannot split in
        # that region)
        #

        my $uniq_bait_without_target       = 0;
        my $uniq_bait_with_target          = 0;
        my $uniq_bait_with_target_accepted = 0;
        my $uniq_bait_before_break         = 0;
        my $bait_blunt_cut                 = 0;
        my $bait_pseudoblunt_cut           = 0;
        my $bait_no_cut                    = 0;
        my $bait_cut_with_deletions        = 0;
        my $bait_pseudocut_with_deletions  = 0;

        foreach my $seq_id (@uniq_bait_reads) {

            # Keep invalid reads;
            my $invalid_reads = 0;

            # Filter bait size
            $invalid_reads++
              if ( $bait{$seq_id}->[0]->query->length < $self->fragment_size
                || $bait{$seq_id}->[0]->qual < $self->min_mapq );

            #say "Searching for read: $seq_id ($z)";

            my @features = @{ $reads{$seq_id} };

            # allow reads that split in only 3 pieces
            $invalid_reads++ if ( scalar @features == 0 );

            # Check if bait split goes up to the break point and if it has
            # deletion in the enzime restriction site
            if ( scalar @features == 1 ) {

                $uniq_bait_without_target++;

                # access object in other variable;
                my $this_bait = $features[0];


                # Strand doesnt matter for the reference (only)
                if ( $this_bait->end <= ($end - 1) + $self->enzime_restriction_size) {
                    $uniq_bait_before_break++;
                    $invalid_reads++;
                    # $self->log_trace($this_bait->query->length); 
                }
                # Search for reas with deletion in the breakpoint
                else {
                    # Get cigar
                    my  $cigar_ref = $this_bait->cigar_array;
                    my @deletions;
                    my $ref_start = $this_bait->start;

                    # get start and end of each deletion
                    foreach my $entry (@{$cigar_ref}) {

                        next if $entry->[0] =~ /[SNI]/;

                        if ($entry->[0] ne 'D'){

                            $ref_start += $entry->[1];

                        }
                        else {

                            push @deletions, {start => $ref_start, end =>
                                ($ref_start + $entry->[1])};
                            $ref_start += $entry->[1];
                        }
                    }
 
                    # Check if deletion is within Isce-I site
                    my $enzime_cut = 0;

                    foreach my $del (@deletions){

                        # preparing key for cis translocations
                        #
                        my $this_strand = '+';
                        $this_strand = '-' if $this_bait->strand == -1;

                        my $del_size = $del->{end} - $del->{start} -  $self->enzime_restriction_size;
                        my $del_before_break = ($end) - $del->{start};
                        my $del_after_break =  $del->{end} - ( $end  + $self->enzime_restriction_size );

                        my $key =
                            $chr . '_'
                          . $del->{start} . '_'
                          . $this_strand . '|'
                          . $chr . '_'
                          . $del->{end} . '_'
                          . $this_strand. '_'
                          . $del_before_break.'_'
                          . $del_after_break;

                        if (   $del->{start} == ( $end )
                            && $del->{end} ==
                            ( $end  + $self->enzime_restriction_size ) )
                        {
                            $enzime_cut = 1;
                           $alignments_to_cluster{$seq_id}{key} = $key;
                            #$self->log_trace($key);

                        }
                        elsif (   $del->{start} <= ( $end )
                            && $del->{end} >=
                            ( $end  + $self->enzime_restriction_size ) )
                        {
                            $enzime_cut = 2;
                            $alignments_to_cluster{$seq_id}{key} = $key;
                            #$self->log_trace($key);

                        }
                        elsif (   $del->{start} > ( $end )
                            && $del->{end} <=
                            ( $end  + $self->enzime_restriction_size ) 
                            ||
                             $del->{start} >= ( $end )
                            && $del->{end} <
                            ( $end  + $self->enzime_restriction_size ) 

                        )
                          {
                            $enzime_cut = 3; #pseudo blunt
                            # Pseudoblunt should be use the same key of normal
                            # blunt
                            
                            my $this_key = $chr.'_'.$end
                                .'_'.$this_strand.'|'.$chr.'_'.( $end +
                                $self->enzime_restriction_size ).'_'.$this_strand.'_0_0';

                            $alignments_to_cluster{$seq_id}{key} = $this_key;
                            $self->log_trace($this_key);

                        }
                        # Check if we have a pseudo cut
                        elsif ( $del->{start} > ( $end  )
                                &&
                                $del->{start} <  ( $end  +  $self->enzime_restriction_size )
                            )
                            {
                            
                            $enzime_cut = 4; #pseudo cut with deletion
                            
                            # Pseudocut should be use the same key of normal
                            # cut for one of the sides
                            my $this_start = ($end );
 
                            $del_size = $del->{end} - $this_start -  $self->enzime_restriction_size;
                            $del_before_break = ($end ) - $this_start;
                            $del_after_break = $del->{end} -  ( $end + $self->enzime_restriction_size );

                            $key =
                                $chr . '_'
                              . $this_start . '_'
                              . $this_strand . '|'
                              . $chr . '_'
                              .     $del->{end} . '_'
                              . $this_strand . '_'
                              . $del_before_break . '_'
                              . $del_after_break;

                            $alignments_to_cluster{$seq_id}{key} = $key;
                            #$self->log_trace($this_key);

                        }
                        elsif ( $del->{end} > ( $end  )
                                &&
                                $del->{end} <  ( $end  +  $self->enzime_restriction_size )
                            )
                            {
                            $enzime_cut = 4; #pseudo cut with deletion

                            # Pseudocut should be use the same key of normal
                            # cut for one of the sides
                            my $this_end = ( $end + $self->enzime_restriction_size );
 
                            my $del_size = $this_end - $del->{start} -  $self->enzime_restriction_size;
                            my $del_before_break = ($end ) - $del->{start};
                            my $del_after_break = $this_end - ( $end  + $self->enzime_restriction_size );

                            my $key =
                                $chr . '_'
                              . $del->{start} . '_'
                              . $this_strand . '|'
                              . $chr . '_'
                              . $this_end . '_'
                              . $this_strand . '_'
                              . $del_before_break . '_'
                              . $del_after_break;

                            $alignments_to_cluster{$seq_id}{key} = $key;
                            #$self->log_trace($this_key);

                        }

                    }
                                        
                    if ($enzime_cut == 1 ){
                        $bait_blunt_cut++;
                    }
                    elsif ($enzime_cut == 2 ){
                        $bait_cut_with_deletions++;
                    }
                    elsif ($enzime_cut == 3 ){
                        
                        $bait_pseudoblunt_cut++;
                    }
                    elsif ($enzime_cut == 4 ){
                        
                        $bait_pseudocut_with_deletions++;
                   }
                   else{
                        $bait_no_cut++;
                        $invalid_reads++;                        
                    }
                    
                }

            }


=cut
                # define the smallest alignment start as bait
                #my @aux = sort {$a->start <=> $b->start} @{$bait{$seq_id}};
                #my $local_bait = shift @aux;
                #$alignments_to_cluster{$seq_id}{bait} = $local_bait;
=cut

            my $local_bait = $bait{$seq_id}->[0];
            $alignments_to_cluster{$seq_id}{bait} = $bait{$seq_id}->[0];

            
            foreach my $f (@features) {
                my $read = $f->query;

                # verify if is bait sequence
                if (
                       $read->start == $local_bait->query->start
                    && $read->end == $local_bait->query->end
                    && $read->strand eq $local_bait->query->strand,
                  )
                {
                    # verify if bait pass througth breakpoint
                    if ( $f->end >
                        ( $end - 1 ) + $self->enzime_restriction_size  && scalar
                    @features > 1)
                    {
                        $invalid_reads++;
                        $bait_no_cut++;
                    }
                    next;
                }

                # filter target length
                $invalid_reads++
                  if ( $read->length < $self->fragment_size
                    || $f->qual < $self->min_mapq );

                # indexing by query position
                my $query_start;

                if ( $f->strand == 1 ) {
                    $query_start = $f->query->start;
                }
                else {
                    $query_start =
                      length( $f->query->seq->seq ) - $f->query->start;
                }

                push
                  @{ $alignments_to_cluster{$seq_id}{targets}{$query_start} },
                  $f;
    

            }

           # Delete invalid entries from hash
            delete $alignments_to_cluster{$seq_id} if $invalid_reads > 0;
                
            $uniq_bait_with_target_accepted++  if $invalid_reads == 0 &&
            scalar @features > 1;
            $uniq_bait_with_target++ if scalar @features > 1;
 
        }

        # Generate DEBUG summary
        my @summary;

        my $total_reads = scalar keys %reads;
        push @summary, "\t- Total of reads: " . $total_reads;
        push @summary, "\t- Total of mapped reads: " . $total_reads_mapped;
        my $total_reads_split = scalar @all_alignments;
        push @summary, "\t- Total of read-splits: " . $total_reads_split;
        my $uniq_baits = scalar @uniq_bait_reads;
        push @summary,
            "\t- Total of reads with unique bait: "
          . $uniq_baits . " ("
          . ( $uniq_baits / $total_reads * 100 ) . "%)";
        push @summary,
            "\t- Total of reads with duplicated baits: "
          . scalar @duplicated_bait_reads . " ("
          . ( scalar @duplicated_bait_reads / $total_reads * 100 ) . "%)";

        push @summary,
            "\t- Total of reads with unique bait and with targets: "
          . $uniq_bait_with_target . " ("
          . ( $uniq_bait_with_target / $total_reads * 100 ) . "%)";

        push @summary,
            "\t\t - Total of reads with unique bait and with targets accepted (based on quality): "
          . $uniq_bait_with_target_accepted . " ("
          . ( $uniq_bait_with_target_accepted / $total_reads * 100 ) . "%)";

        push @summary,
            "\t- Total of reads with unique bait and no targets: "
          . $uniq_bait_without_target . " ("
          . ( $uniq_bait_without_target / $total_reads * 100 ) . "%)";

        my $total_bait_after_break_no_target =
          $bait_cut_with_deletions + $bait_blunt_cut + $bait_no_cut;

        push @summary,
            "\t\t - Bait doesn't cross breakpoint': "
          . $uniq_bait_before_break . " ("
          . ( $uniq_bait_before_break / $uniq_bait_without_target * 100 )
          . "%)";

        push @summary,
            "\t\t - Bait with no cut (intact restriction site): "
          . $bait_no_cut . " ("
          . ( $bait_no_cut / $uniq_bait_without_target * 100 ) . "%)";

        push @summary,
            "\t\t - Bait with blunt cut (accepted): "
          . $bait_blunt_cut . " ("
          . ( $bait_blunt_cut / $uniq_bait_without_target * 100 ) . "%)";

        push @summary,
            "\t\t - Bait with pseudo-blunt cut (accepted): "
          . $bait_pseudoblunt_cut . " ("
          . ( $bait_pseudoblunt_cut / $uniq_bait_without_target * 100 ) . "%)";

        push @summary,
            "\t\t - Bait cut with deletions (accepted): "
          . $bait_cut_with_deletions . " ("
          . ( $bait_cut_with_deletions / $uniq_bait_without_target * 100 )
          . "%)";

        push @summary,
            "\t\t - Bait psedocut with deletions (accepted): "
          . $bait_pseudocut_with_deletions . " ("
          . ( $bait_pseudocut_with_deletions / $uniq_bait_without_target * 100 )
          . "%)";


        push @summary,
          "\t- Mininum read-size (bait and target): " . $self->fragment_size;
        push @summary, "\t- Mininum MAPQ (bait and target): " . $self->min_mapq;

        $reads_to_clustering = scalar keys %alignments_to_cluster;

        push @summary,
            "\t- Total of reads sent to clustering: "
          . $reads_to_clustering . " ("
          . ( $reads_to_clustering / $total_reads * 100 ) . "%)";

        $self->log_debug( join "\n", @summary );

        return \%alignments_to_cluster;
    }

    # method used to run the command
    method execute ($opt,$args) {

        # Given the BAM file, get alignments to cluster.
        # Reliable reads are those which overlap this (hard coded) position by
        # default:
        # 
        # chr15:61818182-61818333
        $self->log_info("Getting reliable alignments...");
        my $reliable_alignments = $self->get_reliable_alignments();

        # print Dumper($reads_to_cluster);
        $self->log_info("Clustering...");
        my $alignments_cluster = $self->clustering_alignments($reliable_alignments);

        #$self->log_info("Creating Alignment output file..."); 
        #$self->show_clusters_alignment($alignments_cluster);

        $self->log_info("Classifying aligments clusters");
        $self->classify($alignments_cluster);
        
    }

}

class main {
    MyApp->run;
}
