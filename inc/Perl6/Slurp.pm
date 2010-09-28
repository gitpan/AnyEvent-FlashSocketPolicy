#line 1
package Perl6::Slurp;
use 5.008;
use Perl6::Export;
use Carp;
use warnings;

our $VERSION = '0.03';

my $mode_pat = qr{
	^ \s* ( (?: < | \+< | \+>>? ) &? ) \s*
}x;

my $mode_plus_layers = qr{
	(?: $mode_pat | ^ \s* -\| \s* )
	( (?: :[^\W\d]\w* \s* )* )
	\s* 
	\z
}x;

sub slurp is export(:DEFAULT) {
	my $list_context = wantarray;
	my $default = $_;
	croak "Useless use of &slurp in a void context"
		unless defined $list_context;

	my @layers;
	for (my $i=0; $i<@_; $i++) {
		my $type = ref $_[$i] or next;
		if ($type eq 'HASH') {
			push @layers, splice @_, $i--, 1
		}
		elsif ($type eq 'ARRAY') {
			my @array = @{splice @_, $i--, 1};
			while (@array) {
				my ($layer, $value) = splice @array, 0, 2;
				croak "Incomplete layer specification for :$layer",
				 	  "\n(did you mean: $layer=>1)\n "
							unless $value;
				push @layers, { $layer=>$value };
			}
		}
	}

	my ($mode, $source, @args) = @_;
	$mode = defined $default ? $default
		  : @ARGV            ? \*ARGV
		  :                    "-"
		unless defined $mode;
	if (ref $mode) {
		$source = $mode;
		$mode   = "<";
	}
	elsif ($mode !~ /$mode_plus_layers/x) {
		$source = $mode;
		$mode = $source =~ s/$mode_pat//x  ?  "$1"
			  : $source =~ s/ \| \s* $//x  ?  "-|"
			  :                               "<"
			  ;
	}

	my $ref = ref $source;
	if ($ref) {
		croak "Can't use $ref as a data source"
				unless $ref eq 'SCALAR' 
					|| $ref eq 'GLOB'
					|| UNIVERSAL::isa($source, 'IO::Handle');
	}

	local $/ = "\n";
	my ($chomp, $chomp_to, $layers) = (0, "", "");

	for (@layers) {
		if (exists $_->{irs}) {
			$/ = $_->{irs};
			delete $_->{irs};
		}
		if (exists $_->{chomp}) {
			$chomp = 1;
			$chomp_to = $_->{chomp}
				if defined $_->{chomp} && $_->{chomp} ne "1";
			delete $_->{chomp};
		}
		$layers .= join " ", map ":$_", keys %$_;
	}

	$mode .= " $layers";

	my $FH;
	if ($ref && $ref ne 'SCALAR') {
		$FH = $source;
	}
	else {
		open $FH, $mode, $source, @args or croak "Can't open '$source': $!";
	}

	my $chomp_into = ref $chomp_to eq 'CODE' ? $chomp_to : sub{ $chomp_to };

	my $data = $FH == \*ARGV ? join("",<>) : do { local $/; <$FH> };

	my $irs = ref($/)		? $/
			: defined($/)	? qr{\Q$/\E}
			:				  qr{(?!)};

	if ($list_context) {
		return () unless defined $data;
		my @lines = split /($irs)/, $data;
		my $reps = @lines/2-1;
		$reps = -1 if $reps<0;
		for my $i (0..$reps) {
			my $sep = splice @lines, $i+1, 1;
			$sep = $chomp_into->($sep) if $chomp;
			$lines[$i] .= $sep if defined $sep;
		}
		return @lines;
	}
	else {
		return "" unless defined $data;
		$data =~ s{($irs)}{$chomp_into->($1)}ge if $chomp;
		return $data;
	}
}

1;
__END__


