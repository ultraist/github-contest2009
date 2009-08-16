package Repo;
use strict;
use warnings;

sub new
{
    my ($pkg, $filename) = @_;

    my $repo = _load_repo($filename);

    return bless($repo, $pkg);
}

sub set_lang
{
    my ($self, $lang) = @_;
    $self->{lang} = $lang;
}

sub _load_repo
{
    my $filename = shift;

    my $repo = {};
    my $author = {};
    my @conv;
    my $i = 0;
    
    open(R, $filename) or die $!;
    
    while (my $line = <R>) {
	chomp($line);
	my ($repo_id, $footer) = split(":", $line);
	my ($name, $date, $base) = split(",", $footer);
	my ($author_name, $repo_name) = split("/", $name);
	
	$repo->{$repo_id} = { rank => 0, base => $base, author => $author_name, name => $name };
	
	if (!defined($author->{$author_name})) {
	    $author->{$author_name} = [];
	    push(@{$author->{$author_name}}, $repo_id);
	} else {
	    push(@{$author->{$author_name}}, $repo_id);
	}
	
	++$i;
    }
    close(R);
    
    foreach my $id (keys(%$repo)) {
	my $base_id = $repo->{$id}->{base};
	if (defined($base_id)) {
	    if (!defined($repo->{$base_id}->{fork})) {
	      $repo->{$base_id}->{fork} = [];
	      push(@{$repo->{$base_id}->{fork}}, $id);
	  } else {
	      push(@{$repo->{$base_id}->{fork}}, $id);
	  }
	}
    }
    
    return { id => $repo, author => $author, n => $i };
}

sub name
{
    my($self, $id) = @_;
    return $self->{id}->{$id}->{name};
}

sub repos
{
    my $self = shift;
    my $repos = [];
    @$repos = keys(%{$self->{id}});

    return $repos;
}

sub author
{
    my($self, $id) = @_;
    return $self->{id}->{$id}->{author};
}

sub langs
{
    my ($self, $id) = @_;
    if (!$self->{lang}) {
	return [];
    }
    return $self->{lang}->repo_langs($id);
}

sub rank
{
    my($self, $id) = @_;
    return $self->{id}->{$id}->{rank};
}

sub rank_id
{
    my($self, $rank) = @_;
    return $self->{rank}->[$rank]->{id};
}

sub freq
{
    my($self, $id) = @_;
    return $self->{id}->{$id}->{freq};
}

sub author_repos
{
    my ($self, $id) = @_;
    return $self->{author}->{$self->{id}->{$id}->{author}};
}

sub base_repos
{
    my ($self, $id) = @_;
    my $base_id = $id;
    my $base_ids = [];

    while (1) {
	if (defined($self->{id}->{$base_id}->{base})) {
	    $base_id = $self->{id}->{$base_id}->{base};
	    push(@$base_ids, $base_id);
	} else {
	    last;
	}
    }
    
    return $base_ids;
}

sub fork_repos
{
    my ($self, $id) = @_;
    my $fork_ids = [];

    if (defined($self->{id}->{$id}->{fork})) {
	@$fork_ids = @{$self->{id}->{$id}->{fork}};
    }

    return $fork_ids;
}

sub ranking
{
    my ($self, $user) = @_;
    my $max_count  = 0;

    foreach my $uid (@{$user->users()}) {
	my $repos = $user->repos($uid);
	foreach my $rid (@$repos) {
	    $self->{id}->{$rid}->{freq} += 1.0;
	}
    }
    foreach my $rid (keys(%{$self->{id}})) {
	if ($max_count < $self->{id}->{$rid}->{freq}) {
	    $max_count = $self->{id}->{$rid}->{freq};
	}
    }
    my $factor = 1.0 / $max_count;
    foreach my $rid (keys(%{$self->{id}})) {
	$self->{id}->{$rid}->{freq} *= $factor;
    }

    my $rank = [];
    foreach my $rid (keys(%{$self->{id}})) {
	push(@$rank, { id => $rid, score => $self->{id}->{$rid}->{freq}});
    }
    @$rank = sort { $b->{score} <=> $a->{score} } @$rank;
    $self->{rank} = $rank;

    for (my $i = 0; $i < @$rank; ++$i) {
	$self->{id}->{$rank->[$i]->{id}}->{rank} = $i;
    }
}

1;
