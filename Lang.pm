package Lang;
use strict;
use warnings;
use List::MoreUtils qw/uniq/;

sub new
{
    my ($pkg, $filename, $repo) = @_;

    my $lang = _load_lang($filename, $repo);

    return bless({ lang => $lang }, $pkg);
}

sub _load_lang
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

sub make_lang_repos
{
    my ($self, $repo) = @_;
    my $lang_repos = {};
    
    foreach my $id (@{$repo->repos()}) {
	foreach my $lang (@{$self->repo_langs($id)}) {
	    if (!defined($lang_repos->{$lang})) {
		$lang_repos->{$lang} = [];
	    }
	    push(@{$lang_repos->{$lang}}, $id);
	}
    }
    $self->{lang_repos} = $lang_repos;
}

sub lang_repos
{
    my ($self, $lang) = @_;
    if (!defined($self->{lang_repos})) {
	return undef;
    }
    return $self->{lang_repos}->{$lang};
}

sub ranking
{
    my ($self, $repo) = @_;
    my $freq = {};
    my $max_count = 0;
    
    foreach my $id (@{$repo->repos()}) {
	foreach my $lang (@{$self->repo_langs($id)}) {
	    if (!exists($freq->{$lang})) {
		$freq->{$lang} = { rank => 0, freq => 0.0 };
	    }
	    $freq->{$lang}->{freq} += 1.0;
	}
    }
    foreach my $lang (keys(%$freq)) {
	if ($max_count < $freq->{$lang}->{freq}) {
	    $max_count = $freq->{$lang}->{freq};
	}
    }
    my $factor = 1.0 / $max_count;
    foreach my $lang (keys(%$freq)) {
	$freq->{$lang}->{freq} *= $factor;
    }
    
    my $rank = [];
    foreach my $lang (keys(%$freq)) {
	push(@$rank, {lang => $lang, freq => $freq->{$lang}->{freq}});
    }
    @$rank = sort { $b->{freq} <=> $a->{freq} } @$rank;
    for (my $i = 0; $i < @$rank; ++$i) {
	$rank->[$i]->{rank} = $i;
	$freq->{$rank->[$i]}->{rank} = $i;
    }

    $self->{freq} = $freq;
    $self->{rank} = $rank;
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

sub rank
{
    my ($self, $lang) = @_;
    if (!defined($self->{freq})) {
	return undef;
    }
    return $self->{freq}->{$lang}->{rank};
}

sub freq
{
    my ($self, $lang) = @_;
    if (!defined($self->{freq})) {
	return undef;
    }
    return $self->{freq}->{$lang}->{freq};
}

sub ranks
{
    my ($self) = @_;
    return $self->{rank};
}


1;
