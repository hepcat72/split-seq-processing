#!/usr/bin/env perl -w

#Command line interface defined in BEGIN block

use strict;
use warnings;
use CommandLineInterface;
#use CommandLineInterface qw(:default editHeaderOption);

#Globals for col/row names
my $badchr_pattern    = '[^A-Za-z0-9\.]';
my $replace_chr       = '.';
my $bad_start_pat     = '^[^A-Za-z]';
my $goodstart_prepend = 'X';

my($excel,$gtf_file_id,$gene_file_id,$cell_file_id,$mtx_file_id,$outf_id,
   $suffix);

my $data = {};
while(nextFileCombo())
  {
    my $mtx_file  = getInfile($mtx_file_id);
    my $cell_file = getInfile($cell_file_id);
    my $gene_file = getInfile($gene_file_id);
    my $gtf_file  = getInfile($gtf_file_id);
    my $outfile   = getOutfile($outf_id);

    if(defined($cell_file) &&
       (!exists($data->{$cell_file}) || !defined($data->{$cell_file})))
      {$data->{$cell_file} = parseCellMetadata($cell_file)}
    if(defined($gtf_file) &&
       (!exists($data->{$gtf_file}) || !defined($data->{$gtf_file})))
      {$data->{$gtf_file} = parseGTF($gtf_file)}
    if(defined($gtf_file) &&
       (!exists($data->{$gtf_file}) || !defined($data->{$gtf_file})))
      {$data->{$gtf_file} = parseGTF($gtf_file)}
    if(defined($gene_file) &&
       (!exists($data->{$gene_file}) || !defined($data->{$gene_file})))
      {$data->{$gene_file} =
	 parseGeneMetadata($gene_file,
			   defined($gtf_file) ? $data->{$gtf_file} : undef)}

    my($matrix,$ncols) = parseMTX($mtx_file);

    openOut(*OUT,$outfile) || next;
    printDenseTSV($matrix,
		  $ncols,
		  (defined($cell_file) && exists($data->{$cell_file}) ?
		   $data->{$cell_file} : {}),
		  (defined($gene_file) && exists($data->{$gene_file}) ?
		   $data->{$gene_file} : {}));
    closeOut(*OUT);
  }

sub parseCellMetadata
  {
    my $cell_file = $_[0];
    my $uniq_name = {};

    openIn(*CELLS,$cell_file) || return(undef);
    my $cn = 0;
    my($cellbcs);
    while(getLine(*CELLS))
      {
	chomp;
	my @cd = split(/,|\t/,$_,-1);
	next if($cn == 0 && ($cd[0] eq 'cell_barcode' || $cd[1] eq 'species'));
	$cn++;
	$cellbcs->{$cn} = makeName($cd[0],$uniq_name);
      }
    closeIn(*CELLS);

    return($cellbcs);
  }

sub parseGeneMetadata
  {
    my $gene_file = $_[0];
    my $gchrs     = defined($_[1]) ? $_[1] : {};
    my $rown      = 0;
    my $uniq_name = {};
    my($genes);

    openIn(*GENES,$gene_file) || return(undef);
    while(getLine(*GENES))
      {
	chomp;
	my($id,$acc,$name,$spc) = split(/,|\t/,$_,-1);
	next if($rown == 0 && ($acc eq 'gene_id' || $name eq 'gene_name'));
	$rown++;

	my $rowname =
	  makeName((exists($gchrs->{$acc}) ? $gchrs->{$acc} : $spc) .
		   "$replace_chr$acc$replace_chr$name",
		   $uniq_name);

	$genes->{$rown} = $rowname;
      }
    closeIn(*GENES);

    return($genes);
  }

sub makeName
  {
    my $name = $_[0];
    my $uniq = $_[1];

    #Replace illegal characters
    $name =~ s/$badchr_pattern/$replace_chr/g;

    #Check the starting character
    if($name =~ /$bad_start_pat/)
      {$name = $goodstart_prepend . $name}

    #Make sure the row name unique
    my $u = '';
    my $n = 1;
    while(exists($uniq->{"$name$u"}))
      {$u = '.' . $n++}
    $name .= $u;

    return($name);
  }

sub parseGTF
  {
    my $gtf_file = $_[0];
    my($gchrs);
    my $l = 0;

    openIn(*GTF,$gtf_file) || return(undef);
    while(getLine(*GTF))
      {
	$l++;
	#Parse out the chromosome and gene ID
	if(/^(\S+)\t.*?gene_id[\s"]+([^"]+)/)
	  {
	    my $chr = $1;
	    my $acc = $2;
	    $chr =~ s/$badchr_pattern/$replace_chr/g;
	    $gchrs->{$acc} = $chr;
	  }
	elsif($_ !~ /^Chromosome\t.*Attributes/i && $_ !~ /^\s*$/)
	  {warning("Unable to parse line [$l] in GTF file: [$gtf_file].",
		   {DETAIL => $_})}
      }
    closeIn(*GTF);

    return($gchrs);
  }

sub parseMTX
  {
    my $mtx_file = $_[0];
    my $table    = [];
    my $ncols    = 0;
    my($mtx);

    openIn(*MTX,$mtx_file) || return(undef);
    while(getLine(*MTX))
      {
	next if(/\%/ || /^\s*$/);
	chomp;
	my($cellidx,$geneidx,$count) = split(/\s+/,$_);
	if(!$ncols)
	  {
	    $ncols = $cellidx;
	    next;
	  }
	$mtx->[$geneidx-1]->[$cellidx-1] = $count;
      }
    closeIn(*MTX);

    return($mtx,$ncols);
  }

sub printDenseTSV
  {
    my $mtx            = $_[0];
    my $ncols          = $_[1];
    my $cellbcs        = defined($_[2]) ? $_[2] : {};
    my $genes          = defined($_[3]) ? $_[3] : {};
    my $genes_supplied = scalar(keys(%$genes));

    #Print the header
    print(($excel ? "\t" : ''),
	  join("\t",map {exists($cellbcs->{$_}) ? $cellbcs->{$_} : $_}
	       (1..$ncols)),"\n");

    my $i = 1;
    foreach my $row (map {defined($_) ? $_ : [map {0} (1..$ncols)]} @$mtx)
      {
	if($genes_supplied && !exists($genes->{$i}))
	  {error("Gene index in mtx file not found in the associated ",
		 "genes.csv file: [$i].")}

	printrow($row,$ncols,(exists($genes->{$i}) ? $genes->{$i} : $i));
	$i++;

	verboseOverMe({LEVEL => 2},"Printing line $i");
      }

    sub printrow
      {
	my $ary  = $_[0];
	my $size = $_[1];
	my $gn   = $_[2];
	print("$gn\t",
	      join("\t",map {defined($ary->[$_]) ? exp2int($ary->[$_]) : "0"}
		   (0..($size-1))),"\n");
      }

    sub exp2int
      {
	my $str = $_[0];
	if($str =~ /^(.*)e\+(\d+)$/i)
	  {my $n = $1 * 10 ** $2;$n}else{$str}
      }
  }


BEGIN
  {
    setScriptInfo(VERSION => '1.0',
		  CREATED => '4/28/2020',
		  AUTHOR  => 'Robert William Leach',
		  CONTACT => 'rleach@princeton.edu',
		  COMPANY => 'Princeton University',
		  LICENSE => 'Copyright 2020',
		  HELP    => ('Convert SPLiT-Seq sparse matrix outputs ' .
			      '(filtered or unfiltered) to a tab-delimited ' .
			      'file where rows are genes and columns are ' .
			      'cells and the contents are counts.'));

    setDefaults(HEADER     => 0,
		ERRLIMIT   => 3,
		DEFRUNMODE => 'run');

    #editHeaderOption(DEFAULT => 0);

    $mtx_file_id =
      addInfileOption(FLAG        => 'i|mtx',
		      REQUIRED    => 1,
		      PRIMARY     => 1,
		      FLAGLESS    => 1,
		      SHORT_DESC  => 'Sparse Market Matrix format input file.',
		      LONG_DESC   => ('Sparse Market Matrix format input ' .
				      'file as output by split-seq.  ' .
				      'Typically found in samplename_DGE_' .
				      'filtered and ' .
				      'samplename_DGE_unfiltered and named ' .
				      '"DGE.mtx".'),
		      FORMAT_DESC => << 'END_FMT'
3 space-delimited column file where the columns are:
  1. Row numbers
  2. Column numbers
  3. Counts
Blank lines and any line with a '%' are ignored.  A header line defining the matrix dimensions is required (number of rows, columns, and counts total).  Only real number counts are supported (as output by split-seq).  Comment lines commented with '%' are allowed.  Example:
  %%MatrixMarket matrix coordinate real general
  %
  7 38526 194539
  1 1 8.000000000000000e+00
  1 3 2.200000000000000e+01
  1 4 6.000000000000000e+00
  1 5 2.300000000000000e+01
END_FMT
		     );

    $cell_file_id =
      addInfileOption(FLAG        => 'c|cell-csv',
		      REQUIRED    => 0,
		      PRIMARY     => 0,
		      FLAGLESS    => 0,
		      SHORT_DESC  => 'Cell metadata csv input file.',
		      LONG_DESC   => ('Comma-delimited cell metadata csv ' .
				      'input file as output by split-seq.  ' .
				      'Typically found in samplename_DGE_' .
				      'filtered and ' .
				      'samplename_DGE_unfiltered and named ' .
				      '"cell_metadata.csv".'),
		      PAIR_WITH   => $mtx_file_id,
		      PAIR_RELAT  => 'ONETOONE',
		      FORMAT_DESC => << 'END_FMT'
Comma-delimited file where the columns are:
  1. cell_barcode
  2. species
  3. rnd1_well
  4. rnd2_well
  5. rnd3_well
  6. umi_count
  7. umi_count_50dup
  8. gene_count
No blank lines or comments are allowed.  A header line is optional (auto-detected based on the expected column names shown above and in the example below).  Only the first column is used.  All other columns are optional.  Example:
  cell_barcode,species,rnd1_well,rnd2_well,rnd3_well,umi_count,umi_count_50dup,gene_count
  AAACATCGAAACATCG_0,multiplet,0,1,1,849749.0,1018408.2608119779,26096
  AAACATCGAAACATCG_1,multiplet,1,1,1,749535.0,898303.658807137,24950
  AAACATCGAACGTGAT_0,multiplet,0,0,1,740576.0,887566.4651080394,25381
  AACGTGATAAACATCG_0,multiplet,0,1,0,2442304.0,2927055.599964386,31084
END_FMT
		     );

    $gene_file_id =
      addInfileOption(FLAG        => 'g|genes-csv',
		      REQUIRED    => 0,
		      PRIMARY     => 0,
		      FLAGLESS    => 0,
		      SHORT_DESC  => 'Gene metadata csv input file.',
		      LONG_DESC   => ('Comma-delimited gene metadata csv ' .
				      'input file as output by split-seq.  ' .
				      'Typically found in ' .
				      'samplename_DGE_filtered and ' .
				      'samplename_DGE_unfiltered and named ' .
				      '"genes.csv".'),
		      PAIR_WITH   => $mtx_file_id,
		      PAIR_RELAT  => 'ONETOONE',
		      FORMAT_DESC => << 'END_FMT'
Comma-delimited file where the columns are:
  1. (Un-named & unused index, unrelated to the mtx's row number (which corresponds only to line number, minus 1 for the optional header line).)
  2. gene_id
  3. gene_name
  4. genome
No blank lines or comments are allowed.  A header line is optional (auto-detected based on the expected column names shown above and in the example below).  Example:
  ,gene_id,gene_name,genome
  0,ENSG00000000003,TSPAN6,hg38
  1,ENSG00000000005,TNMD,hg38
  2,ENSG00000000419,DPM1,hg38
  3,ENSG00000000457,SCYL3,hg38
  4,ENSG00000000460,C1orf112,hg38
END_FMT
		     );

    $gtf_file_id =
      addInfileOption(FLAG        => 'a|gtf-annotations',
		      REQUIRED    => 0,
		      PRIMARY     => 0,
		      FLAGLESS    => 0,
		      SHORT_DESC  => 'Gene annotation gtf input file.',
		      LONG_DESC   => ('Tab-delimited gene annotation gtf ' .
				      'input file as output by `split-seq ' .
				      'mkref`.  Found in the reference ' .
				      'directory created and used by ' .
				      'splitseq and typically named ' .
				      'genes.gtf.'),
		      PAIR_WITH   => $gene_file_id,
		      PAIR_RELAT  => 'ONETOONEORMANY',
		      FORMAT_DESC => << 'END_FMT'
Tab-delimited file.  Only the first and last/9th columns are used (Chromosome and Attributes).  Specifically, the chromosome (which also contains the species name) is optionally included in the row names of the output file, as identified by the gene_id found in the attributes column.
A header line is optional (auto-detected based on the expected column names shown above and in the example below).  Example:
  Chromosome	Source	Feature	Start	End	Score	Strand	Frame	Attributes
  hg38_1	havana	gene	11869	14409	.	+	.	"gene_id ""ENSG00000223972""; gene_version ""5""; gene_name ""DDX11L1""; gene_source ""havana""; gene_biotype ""
transcribed_unprocessed_pseudogene"";"
  hg38_1	havana	gene	14404	29570	.	-	.	"gene_id ""ENSG00000227232""; gene_version ""5""; gene_name ""WASH7P""; gene_source ""havana""; gene_biotype ""u
nprocessed_pseudogene"";"
  hg38_1	mirbase	gene	17369	17436	.	-	.	"gene_id ""ENSG00000278267""; gene_version ""1""; gene_name ""MIR6859-1""; gene_source ""mirbase""; gene_biotype
 ""miRNA"";"
END_FMT
		     );

    $excel = 0;
    addOption(FLAG       => 'e|excel',
	      VARREF     => \$excel,
	      TYPE       => 'bool',
	      SHORT_DESC => 'Excel tab-delimited import mode.',
	      LONG_DESC  => ('Excel tab-delimited import mode.  All this ' .
			     'does is it indents the column names with a ' .
			     'tab so that after import of the tab-delimited ' .
			     'file into excel, the column names are aligned ' .
			     'with the corresponding data, leaving an empty ' .
			     'cell at the top left.'));

    $outf_id =
      addOutfileTagteamOption(FLAG_SUFF   => 's|outfile-suffix',
			      FLAG_FILE   => 'o|outfile',
			      PAIR_WITH   => $mtx_file_id,
			      PAIR_RELAT  => 'ONETOONE',
			      VARREF_SUFF => \$suffix,
			      ADVANCED_SUFF => 1,
			      REQUIRED    => 1,
			      PRIMARY     => 1,
			      FORMAT_DESC => ('Tab delimited file where ' .
					      'rows are genes, columns are ' .
					      'cells, and contents are ' .
					      'counts.'),
			      SMRY_SUFF   => 'Outfile suffix appended to mtx.',
			      SMRY_FILE   => 'Output file.');
  }
