package Lang;
use strict;
use warnings;
use List::MoreUtils qw/uniq/;

sub new
{
    my ($pkg, $filename, $repo) = @_;

    my $lang = _read_lang($filename, $repo);

    return bless({ lang => $lang }, $pkg);
}

sub _read_lang
{
    my ($filename, $repo) = @_;
    my $lang = {};
    open(L, $filename) or die $!;

    while (my $line = <L>) {
	my @repo_lang;
	chomp($line);
	my($repo_id, $lang_info) = split(":", $line);
	my @lang_line = split(",", $lang_info);
	for (my $i = 0; $i < @lang_line; $i++) {
	    push(@repo_lang, (split(";", $lang_line[$i]))[0]);
	}
	if (!defined($lang->{$repo_id})) {
	    $lang->{$repo_id} = [];
	}
	push(@{$lang->{$repo_id}}, @repo_lang);
    }
    close(L);

    foreach my $id (@{$repo->repos()}) {
	my @rel_repo;
	my @repo_lang;
	
	push(@rel_repo, @{$repo->base_repos($id)});
	push(@rel_repo, @{$repo->fork_repos($id)});
	
	foreach my $rid (@rel_repo) {
	    if (defined($lang->{$rid})) {
		push(@repo_lang, @{$lang->{$rid}});
	    }
	}
	push(@{$lang->{$id}}, @repo_lang);
    }

    foreach my $id (keys(%$lang)) {
	@{$lang->{$id}} = uniq(@{$lang->{$id}});
    }

    return $lang;
}

sub repo_langs
{
    my ($self, $id) = @_;
    my $langs = [];

    if (defined($self->{lang}->{$id})) {
	@$langs = @{$self->{lang}->{$id}};
    }
    
    return $langs;
}


1;
