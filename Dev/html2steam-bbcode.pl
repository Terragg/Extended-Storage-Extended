#!/usr/bin/perl

use strict;

my (
	$emptyPreviousLine, $fh, $file, $hr, $hr2, $indentLevel, $line, $line, $output, $rulePreviousLine,
	@lines, @list, @output, @sizing
);

$file = shift @ARGV;

open ($fh, '<', $file) or die "Cannot open file [$file]: $!";
	@lines = <$fh>;
close $fh;

$hr = '-' x 32;
$hr2 = '=' x 64;
@sizing = (0, 32, 24, 18, 16, 14, 12);
$indentLevel = 0;
@list = ();
foreach $line (@lines)
{
	$line =~ s#^[ \t]+##g;
# 	$line =~ s#</h[1-6]>#</size>#g;
# 	if ($line =~ m#<h([1-6])>#)
# 	{
# 		my $tag = '<size='.$sizing[$1].'>';
# 		unless ($emptyPreviousLine || $rulePreviousLine) { $tag = "\n".$tag;}
# 		$line =~ s#<h[1-6]>#$tag#g;
# 	}
	$line =~ s#<(/?)ul>#[$1list]#g;
	$line =~ s#<(/?)ol>#[$1olist]#g;
	if ($line =~ s#^\s*<li>(.+)</li>#\[*\]$1#g) { $line = renderIndent().$line; }
	$line =~ s#</?p>#\n#g;
	$rulePreviousLine = 0;
	if ($line =~ s#<hr />#$hr#g || ($line =~ s#<hr size="2"/>#$hr2#g))
	{
		$rulePreviousLine = 1;
	}

	my $extraIndent = renderIndent(1);
	if ($line =~ s#<(/?)a([^>]*)>#[$1url$2]#g)
	{
		$line =~ s#(\[url)#$extraIndent$1#g;
		$line =~ s# href="([^"]+)"[^\]]*]#=$1\]#g;
	}
	## Remove
	foreach ('br','html','head', 'body', '!DOCTYPE')
	{
		$line =~ s#</?$_[^>]*>##g;
	}
	## Convert
	foreach (qw(h2 h3 h4 h5 h6))
	{
		$line =~ s#<(/?)$_[^>]*>#\[$1b\]#g;
	}
	foreach (qw(b i u h1))
	{
		$line =~ s#<(/?$_[^>]*)>#\[$1\]#g;
	}
	## Clean up
	$line =~ s#^[ \t]+$##;

	$emptyPreviousLine = 0;
	unless ($line && $line =~ m/\S/) { $emptyPreviousLine = 1; }

	push @output, $line;
}

$output = join ('', @output);
$output =~ s#\n\n\n+#\n\n#g;
$output =~ s#^\n+##g;
$output =~ s#\n+$##g;
$output =~ s#(\[\/b\])\n\n#$1\n#g;
$output =~ s#\n\n(\[o?list\])#\n$1#g;

open ($fh, '>', $file.'.bbcode') or die "Cannot open file [$file.bbcode]: $!";
	print $fh $output;
close $fh;

exit();

sub increaseIndent { return ++$indentLevel; }
sub decreaseIndent { --$indentLevel; if ($indentLevel < 1) { $indentLevel = 0; } return $indentLevel; }
sub renderIndent { my $increment = (shift @_ || 0); return "   " x ($indentLevel+$increment); }

1;
