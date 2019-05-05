#!perl

use strict;
use warnings;

use Text::CSV_XS ();
use XML::LibXML ();
use File::Find ();
use Cwd ();
use FindBin ();
use Data::Dumper ();
use Text::Autoformat ();

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

my %Data = ();
my @ThingDefNodeXpath = ('/Defs/ThingDef', '/Defs/ThingCategoryDef');

my ($metainfoFile, @directories, $DefLookup, $Things, $output, $fh, @lines, $file);

$DefLookup = {};
$Things = {};
($metainfoFile) = @ARGV;

### Handle help/version bad requests
if (($metainfoFile && ($metainfoFile =~ m/^(-h|--help|-[vV]?|--version)$/)))
{
	print <<EOP;

This script generates documentation from this mods ThingDef files.

It outputs the html fragment to standard out.
EOP
	print "\nUsage:\n\t$0 [-h] > <capture-file> \n\n";
	exit();
}

my $steamDir = '/Users/taylorg/Library/Application Support/Steam/';

@directories =
	(
		Cwd::realpath($steamDir.'steamapps/workshop/content/294100/'),
		Cwd::realpath($steamDir.'steamapps/common/RimWorld/RimWorldMac.app/Mods/Core/'),
		Cwd::realpath($steamDir.'steamapps/common/RimWorld/RimWorldMac.app/Mods/Extended Storage Extended/'),
	);

# print Data::Dumper->Dump([\@directories]);

ExtractDefLabelDataFromCoreAndAllMods (@directories);

ExtractThingDataFromThisMod ($directories[-1]);

ExtractMetaInformationFromThisMod ($FindBin::Bin.'/../Docs/');

# print Data::Dumper->Dump([$Things]);

@lines = ();

foreach my $thingKey (sort keys %{$Things})
{
	my %data = %{$Things->{$thingKey}};
	push (@lines, "<h3>$data{Label}</h3>");
	push (@lines, "<hr />");
	if ($data{blurb}) { push (@lines, "<p>".ucfirst ($data{blurb})."</p>"); }

	foreach my $sectionKey (qw(Prerequisites Experimental Benefits Holds))
	{
		my (@sublines);
		my $section = $data{$sectionKey};
		next unless ($section && ((ref $section eq 'HASH')));
		push (@lines, "<h4>$sectionKey:</h4>");
		if ($section->{blurb}) { push (@lines, "<p>".ucfirst ($section->{blurb})."</p>"); }
		if (($sectionKey eq 'Holds') && $section->{holdsSummary})
		{
			push (@lines, "<p>".$section->{countFinal}.' stacks of '.$section->{holdsSummary}.":</p>");
		}
		@sublines = ();
		foreach my $listKey (qw(itemListEnabled categoryListEnabled))
		{
			next unless (
					$section->{$listKey}
					&& ((ref $section->{$listKey}) eq 'ARRAY')
					&& (scalar @{$section->{$listKey}})
				);
			my @list = ();
			foreach my $item (@{$section->{$listKey}})
			{
				my $value = $DefLookup->{$item};
				if ($value)
				{
					$value = Text::Autoformat::autoformat ($value, { case => 'title' });
					$value =~ s/([SL]mg)/\U$1/g;
					$value =~ s/\s+$//;	$value =~ s/^\s+//;
				}
				$value //= $item;
				if ($listKey =~ m/categor(y|ies)/i)
				{
					$value = "Everything under '$value' category";
				}
				push (@list, "<li>$value</li>");
			}
			if (scalar @list)
			{
				push (@sublines, @list);
			}
			@list = ();
		}
		if (scalar @sublines)
		{
			unshift (@sublines, '<ul>');
			push (@sublines, '</ul>');
			push (@lines, @sublines);
		}
		@sublines = ();
		foreach my $listKey (qw(list))
		{
			next unless (
					$section->{$listKey}
					&& ((ref $section->{$listKey}) eq 'ARRAY')
					&& (scalar @{$section->{$listKey}})
				);
			my @list = ();
			foreach my $item (@{$section->{$listKey}})
			{
				my $value = $DefLookup->{$item};
				if ($value)
				{
					$value = Text::Autoformat::autoformat ($value, { case => 'title' });
					$value =~ s/([SL]mg)/\U$1/g;
					$value =~ s/\s+$//;	$value =~ s/^\s+//;
				}
				$value //= $item;
				push (@list, "<li>$value</li>");
			}
			if (scalar @list)
			{
				unshift (@list, '<ul>');
				push (@list, '</ul>');
				push (@lines, @list);
			}
			@list = ();
		}
		@sublines = ();
		foreach my $listKey (qw(categoryListDisabled itemListDisabled))
		{
			next unless (
					$section->{$listKey}
					&& ((ref $section->{$listKey}) eq 'ARRAY')
					&& (scalar @{$section->{$listKey}})
				);
			my @list = ();
			foreach my $item (@{$section->{$listKey}})
			{
				my $value = $DefLookup->{$item};
				if ($value)
				{
					$value = Text::Autoformat::autoformat ($value, { case => 'title' });
					$value =~ s/([SL]mg)/\U$1/g;
					$value =~ s/\s+$//;	$value =~ s/^\s+//;
				}
				$value //= $item;
				if ($listKey =~ m/categor(y|ies)/i)
				{
					$value = "Anything under '$value' category";
				}
				push (@list, "<li>$value</li>");
			}
			if (scalar @list)
			{
				push (@sublines, @list);
			}
			@list = ();
		}
		if (scalar @sublines)
		{
			unshift (@sublines, '<ul>');
			unshift (@sublines, "<h4>Cannot Hold:</h4>");
			push (@sublines, '</ul>');
			push (@lines, @sublines);
		}
		@sublines = ();
		foreach my $listKey (qw(categoryListDefault itemListDefault))
		{
			next unless (
					$section->{$listKey}
					&& ((ref $section->{$listKey}) eq 'ARRAY')
					&& (scalar @{$section->{$listKey}})
				);
			my @list = ();
			foreach my $item (@{$section->{$listKey}})
			{
				my $value = $DefLookup->{$item};
				if ($value)
				{
					$value = Text::Autoformat::autoformat ($value, { case => 'title' });
					$value =~ s/([SL]mg)/\U$1/g;
					$value =~ s/\s+$//;	$value =~ s/^\s+//;
				}
				$value //= $item;
				if ($listKey =~ m/categor(y|ies)/i)
				{
					$value = "Anything under '$value' category";
				}
				push (@list, "<li>$value</li>");
			}
			if (scalar @list)
			{
				push (@sublines, @list);
			}
			@list = ();
		}
		if (scalar @sublines)
		{
			unshift (@sublines, '<ul>');
			unshift (@sublines, "<h4>Defaults to Storing:</h4>");
			push (@sublines, '</ul>');
			push (@lines, @sublines);
		}
		@sublines = ();
		foreach my $listKey (qw(research))
		{
			next unless (
					$section->{$listKey}
					&& ((ref $section->{$listKey}) eq 'ARRAY')
					&& (scalar @{$section->{$listKey}})
				);
			my @list = ();
			foreach my $item (@{$section->{$listKey}})
			{
				my $value = $DefLookup->{$item};
				if ($value)
				{
					$value = Text::Autoformat::autoformat ($value, { case => 'title' });
					$value =~ s/\s+$//;	$value =~ s/^\s+//;
				}
				$value //= $item;
				push (@list, "<li>$value</li>");
			}
			if (scalar @list)
			{
				unshift (@list, '<ul>');
				push (@list, '</ul>');
				push (@lines, @list);
			}
			@list = ();
		}
		if ($lines[-1] =~ m/<\/h4>/) { pop (@lines); }
	}
	push (@lines, '');
}

$output = join ("\n", @lines);

print $output;

exit();

sub ExtractThingDataFromThisMod
{
	my (@dirs) = @_;

	## Process directories for Def -> label hash
	foreach my $dir (@dirs)
	{
		next unless ($dir && -d $dir);
		File::Find::find(\&ExtractThingDataFromFileForThisMod, $dir);
	}
	return 1;
}
sub ExtractThingDataFromFileForThisMod
{
	my ($file, $path, $filename) = ($File::Find::name, $File::Find::dir, $_);

	return 0 unless ($path =~ m#/?Defs(/|$)#);
	return 0 if ($path =~ m#Languages/.+/DefInjected#); ## Avoid malformed languague files
	return 0 unless ((-f $filename) && (-r $filename)	&& ($filename =~ m#\.xml$#i));

	## File is an xml file that _looks_ like it's in the right spot, extract data
	return _ExtractThingDataFromFile($Things, $filename, $path);
}
sub _ExtractThingDataFromFile
{
	my ($dom, $error);
	my ($dataThings, $file, $path, $columns) = @_;
	eval
	{
		$dom = XML::LibXML->load_xml(location => $file);
	};
	if ($@)
	{
		warn ("!! Issue with $path/$file\n");
		warn ($@);
		return 0;
	}
	foreach my $node ($dom->findnodes($ThingDefNodeXpath[0]))
	{
		my $result = __ParseESEThing($dataThings, $node);
# 		if (defined $result && (not $result)) { warn ("No label in $path/$file\n"); }
	}
	undef $dom;
	return 1;
}
sub __ParseESEThing
{
	my ($defName, %xpaths, %translation, $section, $thisSection, @list, @out);
	my ($dataThings, $node) = @_;

	%xpaths = (
		count => './statBases/ES_StorageFactor',
		categoryListEnabled => './building/fixedStorageSettings/filter/categories/li',
		categoryListDisabled => './building/fixedStorageSettings/filter/disallowedCategories/li',
		itemListEnabled => './building/fixedStorageSettings/filter/thingDefs/li',
		itemListDisabled => './building/fixedStorageSettings/filter/disallowedThingDefs/li',
		itemListDefault => './building/defaultStorageSettings/filter/thingDefs/li',
		Prerequisites => './researchPrerequisites/li',
		Label => './label',
		list =>
			[
				'./building/ignoreStoredThingsBeauty',
				'./building/preventDeteriorationOnTop',
				'./building/preventDeteriorationInside'
			],
		Name => './defName',
	);

	%translation = (
		'./building/ignoreStoredThingsBeauty' => 'Hides Ugliness',
		'./building/preventDeteriorationOnTop' => 'Protects top item from deterioration',
		'./building/preventDeteriorationInside' => 'Protects all contents from deterioration',
	);

	$defName = $node->findvalue($xpaths{Name});
	return 0 unless $defName;

	unless ($dataThings->{$defName}) { $dataThings->{$defName} = {}; }

	###
	###  BASICS
	###
	$dataThings->{$defName}->{Name} = $defName;
	$dataThings->{$defName}->{Label} = $node->findvalue($xpaths{Label});
	$dataThings->{$defName}->{Label} //= $defName;

# warn Data::Dumper->Dump([$dataThings], [__LINE__.'::dataThings']);
	###
	###  HOLDS
	###
	$section = 'Holds';
	unless ($dataThings->{$defName}->{$section}) { $dataThings->{$defName}->{$section} = {}; }
	$thisSection = $dataThings->{$defName}->{$section};
	foreach my $listKey (qw(itemListEnabled categoryListEnabled categoryListDisabled itemListDisabled itemListDefault))
	{
		my @out;
		my @list = (map { $_->to_literal() } ($node->findnodes($xpaths{$listKey})));
		foreach my $item (@list)
		{
			$item =~ s/\s+$//;	$item =~ s/^\s+//;
			if ($item =~ m/\S/) { push (@out, $item); }
		}
		next unless (scalar @out);
		$thisSection->{$listKey} = [@out];
		@out = ();
	}
	foreach (qw(count))
	{
		my $value = $node->findvalue($xpaths{$_});
		next unless ($value);
		$thisSection->{$_} = $value;
	}
	$thisSection->{countFinal} = $thisSection->{count} + 1;

	###
	###  BENEFITS
	###
	$section = 'Benefits';
	unless ($dataThings->{$defName}->{$section}) { $dataThings->{$defName}->{$section} = {}; }
	$thisSection = $dataThings->{$defName}->{$section};

	foreach my $listKey (qw(list))
	{
		my @out = ();
		foreach my $xpath (@{$xpaths{$listKey}})
		{
			my $value = $node->findvalue($xpath);
# warn Data::Dumper->Dump([[$xpath, $value]], [__LINE__.'::'.$dataThings->{$defName}->{Name}]);
			if (lc ($value) eq 'true') { $value = 1; }
			if (lc ($value) eq 'false') { $value = 0; }
			if ($value) {push (@out, $translation{$xpath}); }
		}
		unless (scalar @out) { @out = ('none'); }
		unless ($thisSection->{$listKey} && ((ref $thisSection->{$listKey}) eq 'ARRAY') )
		{
			$thisSection->{$listKey} = [];
		}
		push (@{$thisSection->{$listKey}}, @out);
	}

	###
	###  REQUIRMENTS
	###
	$section = 'Prerequisites';
	unless ($dataThings->{$defName}->{$section}) { $dataThings->{$defName}->{$section} = {}; }
	$thisSection = $dataThings->{$defName}->{$section};

	@out = ();
	@list = (map { $_->to_literal() } ($node->findnodes($xpaths{$section})));
	foreach my $item (@list)
	{
		$item =~ s/\s+$//;	$item =~ s/^\s+//;
		if ($item =~ m/\S/) { push (@out, $item); }
	}
	if (scalar @out)
	{
		$thisSection->{'research'} = [@out];
		@out = ();
	}

	return 1;
}



sub ExtractMetaInformationFromThisMod
{
	my (@dirs) = @_;

	## Process directories for Def -> label hash
	foreach my $dir (@dirs)
	{
		next unless ($dir && -d $dir);
		File::Find::find(\&ExtractMetaInfomationFromThisMod, $dir);
	}
	return 1;
}
sub ExtractMetaInfomationFromThisMod
{
	my ($file, $path, $filename) = ($File::Find::name, $File::Find::dir, $_);

	return 0 unless ((-f $filename) && (-r $filename)	&& ($filename =~ m#meta_information\.xml$#i));

	## File is an xml file that _looks_ like it's in the right spot, extract data
	return _ExtractMetaInfomationFromFile($Things, $filename, $path);
}
sub _ExtractMetaInfomationFromFile
{
	my ($dom, $error);
	my ($dataThings, $file, $path, $columns) = @_;
	eval
	{
		$dom = XML::LibXML->load_xml(location => $file);
	};
	if ($@)
	{
		warn ("!! Issue with $path/$file\n");
		warn ($@);
		return 0;
	}
	foreach my $node ($dom->findnodes($ThingDefNodeXpath[0]))
	{
		my $result = __ParseESEThingMetaData($dataThings, $node);
# 		if (defined $result && (not $result)) { warn ("No label in $path/$file\n"); }
	}
	undef $dom;
	return 1;
}
sub __ParseESEThingMetaData
{
	my ($defName, %xpaths, %translation, $section, $thisSection);
	my ($dataThings, $node) = @_;

	%xpaths = (
		blurb => './ExtendedStorageExtended/blurb',
		Experimental => './ExtendedStorageExtended/isExperimental',
		holdsSummary => './ExtendedStorageExtended/holdsSummary',
		Name => './defName',
	);

	%translation = (
		'./building/ignoreStoredThingsBeauty' => 'Hides Ugliness',
		'./building/preventDeteriorationOnTop' => 'Protects from Deterioration',
	);

	$defName = $node->findvalue($xpaths{Name});
	return 0 unless $defName;

	unless ($dataThings->{$defName}) { $dataThings->{$defName} = {}; }

	###
	###  BASICS
	###
	foreach (qw(blurb))
	{
		my $value = $node->findvalue($xpaths{$_});
		next unless ($value);
		$dataThings->{$defName}->{$_} = $value;
	}

# warn Data::Dumper->Dump([$dataThings], [__LINE__.'::dataThings']);
	###
	###  HOLDS
	###
	$section = 'Holds';
	unless ($dataThings->{$defName}->{$section}) { $dataThings->{$defName}->{$section} = {}; }
	$thisSection = $dataThings->{$defName}->{$section};
	foreach (qw(holdsSummary)) #
	{
		my $value = $node->findvalue($xpaths{$_});
		next unless ($value);
		$thisSection->{$_} = $value;
	}

	###
	###  EXPERIMENTAL
	###
	$section = 'Experimental';
	foreach my $xpath ($xpaths{$section})
	{
		my $value = $node->findvalue($xpath);
		if (lc ($value) eq 'true') { $value = 1; }
		if (lc ($value) eq 'false') { $value = 0; }
		if ($value)
		{
			unless ($dataThings->{$defName}->{$section}) { $dataThings->{$defName}->{$section} = {}; }
			$thisSection = $dataThings->{$defName}->{$section};
			$thisSection->{blurb} = 'use at own risk';
		}
	}


	return 1;
}


sub ExtractDefLabelDataFromCoreAndAllMods
{
	my (@dirs) = @_;

	## Process directories for Def -> label hash
	foreach my $dir (@dirs)
	{
		next unless ($dir && -d $dir);
		File::Find::find(\&BuildDefLabelListFromXmlFiles, $dir);
	}
	return 1;
}


sub BuildDefLabelListFromXmlFiles
{
	my ($file, $path, $filename) = ($File::Find::name, $File::Find::dir, $_);

	return 0 unless ($path =~ m#/?Defs(/|$)#);
	return 0 if ($path =~ m#Languages/.+/DefInjected#); ## Avoid malformed languague files
	return 0 unless ((-f $filename) && (-r $filename)	&& ($filename =~ m#\.xml$#i));

	## File is an xml file that _looks_ like it's in the right spot, extract data
	return _ExtractDefLabelDataFromFile($DefLookup, $filename, $path, [qw(defName label)]);
}


sub _ExtractDefLabelDataFromFile
{
	my ($dom, $error);
	my ($dataPairs, $file, $path, $columns) = @_;
	eval
	{
		$dom = XML::LibXML->load_xml(location => $file);
	};
	if ($@)
	{
		warn ("!! Issue with $path/$file\n");
		warn ($@);
		return 0;
	}
	foreach my $xpath (@ThingDefNodeXpath)
	{
		foreach my $node ($dom->findnodes($xpath))
		{
			my $result = __CopyValuePairs($dataPairs, $node, $columns);
	# 		if (defined $result && (not $result)) { warn ("No label in $path/$file\n"); }
		}
	}
	undef $dom;
	return 1;
}


sub __CopyValuePairs
{
	my ($dataPairs, $node, $columns) = @_;
	my @out = ();

	my $key = ''; my %data = ();
	foreach my $column (@{$columns})
	{
		my $value = $node->findvalue('./'.$column);
		$value =~ s/\s+$//;	$value =~ s/^\s+//;
		if ($column eq $columns->[0])
		{
			$key = $value;
			return undef unless ($key =~ m/\S/);
		}
		$data{$column} = $value;
	}
	if ($key)
	{
		my $value = $data{$columns->[1]};
		unless ($value && ($value =~ m/\S/)) { return 0; }
		$dataPairs->{$key} = $value;
	}
	return 1;
}

1;
