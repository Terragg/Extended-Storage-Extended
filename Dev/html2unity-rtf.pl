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
	$line =~ s#</h[1-6]>#</size>#g;
	if ($line =~ m#<h([1-6])>#)
	{
		my $tag = '<size='.$sizing[$1].'>';
		unless ($emptyPreviousLine || $rulePreviousLine) { $tag = "\n".$tag;}
		$line =~ s#<h[1-6]>#$tag#g;
	}
	if ($line =~ s#<(ul)>##g) { push (@list, $1); increaseIndent(); }
	if ($line =~  s#</ul>##g) {   pop @list;      decreaseIndent(); }
	if ($line =~ s#<(ol)>##g) { push (@list, $1); increaseIndent(); }
	if ($line =~  s#</ol>##g) {   pop @list;      decreaseIndent(); }
	if ($line =~ s#^\s*<li>(.+)</li>#\* $1#g) { $line = renderIndent().$line; }
	$line =~ s#</?p>#\n#g;
	$rulePreviousLine = 0;
	if ($line =~ s#<hr />#$hr#g || ($line =~ s#<hr size="2"/>#$hr2#g))
	{
		$rulePreviousLine = 1;
	}
	my $extraIndent = renderIndent(1);
	$line =~ s#<a [^>]*>#$extraIndent#;
	foreach ('br','html','head', 'body', '!DOCTYPE', 'a')
	{
		$line =~ s#</?$_[^>]*>##g;
	}
	$line =~ s#^[ \t]+$##;
	$emptyPreviousLine = 0;
	unless ($line && $line =~ m/\S/) { $emptyPreviousLine = 1; }
	push @output, $line;
}

$output = join ('', @output);
$output =~ s#\n\n\n+#\n\n#g;
$output =~ s#^\n+##g;
$output =~ s#\n+$##g;

open ($fh, '>', $file.'.rtf') or die "Cannot open file [$file.rtf]: $!";
	print $fh $output;
close $fh;

exit();

sub increaseIndent { return ++$indentLevel; }
sub decreaseIndent { --$indentLevel; if ($indentLevel < 1) { $indentLevel = 0; } return $indentLevel; }
sub renderIndent { my $increment = (shift @_ || 0); return "   " x ($indentLevel+$increment); }

1;
