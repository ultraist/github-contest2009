package User;
use strict;
use warnings;
use Utils;

sub new 
{
    my($pkg, $filename, $lang) = @_;
   
    my $user = _load_user($filename, $lang);

    return bless($user, $pkg);
}

sub idf_comp
{
}

sub _load_user
{
    my ($filename, $lang) = @_;
    my $user = {};
    my $repo_hash = {};
    my $i = 0;
    
    open(U, $filename) or die $!;
    
    while (my $line = <U>) {
	chomp($line);
	my ($user_id, $repo_id) = split(":", $line);
	if (!exists($user->{$user_id})) {
	    $user->{$user_id} = {};
	    $user->{$user_id}->{$repo_id} = 1;
	} else {
	    $user->{$user_id}->{$repo_id} = 1;
	}
    }
    close(U);

    #freq
    my $freq = {};
    my $idf = {};
    my $max_count = 0;
    my %repo;
    foreach my $uid (keys(%{$user})) {
	$freq->{$uid} = scalar(keys(%{$user->{$uid}}));
	foreach my $rid (keys(%{$user->{$uid}})) {
	    $repo{$rid} = 1;
	}
    }
    
    # idf
    my $eps = 1e-64;
    my $rd = log($eps + scalar(keys(%repo)));
    my $ilog = 1.0 / log(2.0);
    foreach my $uid (keys(%$user)) {
	$idf->{$uid} = 1 + $ilog * ($rd - log($eps + $freq->{$uid}));
    }

    # normalize freq
    foreach my $uid (keys(%{$user})) {
	if ($max_count < $freq->{$uid}) {
	    $max_count = $freq->{$uid};
	}
    }
    
    my $factor = 1.0 / $max_count;
    foreach my $uid (keys(%{$user})) {    
	$freq->{$uid} = $factor * $freq->{$uid};
    }
  
    my $sample_user = {};
    my $count = scalar(keys(%$user));
    my $avg = 0.0;
    my $var = 0.0;
    my $sd = 0.0;
    my $samples = 0;
    
    foreach my $k (keys(%$user)) {
	my $p = scalar(keys(%{$user->{$k}}));
	$avg += $p / $count;
    }
    foreach my $k (keys(%$user)) {
	my $p = scalar(keys(%{$user->{$k}}));
	$var += ($p - $avg) ** 2 / ($count - 1);
    }
    $sd = sqrt($var);
    foreach my $k (keys(%$user)) {
	my $p = scalar(keys(%{$user->{$k}}));
	if ($avg / 4 < $p && $p < $avg + $sd * 3) {
	    $sample_user->{$k} = $user->{$k};
	}
    }
    $samples =  scalar(keys(%$sample_user));
    
    # lang
    my $user_lang = {};
    foreach my $uid (keys(%$user)) {
	my @skill_lang;
	foreach my $rid (keys(%{$user->{$uid}})) {
	    my $repo_lang = $lang->repo_langs($rid);
	    if (defined($repo_lang)) {
		push(@skill_lang, @{$repo_lang});
	    }
	}
	$user_lang->{$uid} = [];
	push(@{$user_lang->{$uid}}, Utils::uniq(@skill_lang));
    }
    
    return { id => $sample_user, all_id => $user, hash => $repo_hash, freq => $freq, idf => $idf, lang => $user_lang, n => $samples, avg => $avg, sd => $sd };
}

sub idf
{
    my ($self, $id) = @_;
    return $self->{idf}->{$id};
}


sub freq
{
    my ($self, $id) = @_;
    return $self->{freq}->{$id};
}


sub repo_avg
{
    my ($self) = @_;
    return $self->{avg};
}
sub repo_sd
{
    my ($self) = @_;
    return $self->{sd};
}

sub repos
{
    my ($self, $id) = @_;
    my $repos = [];
    if (defined($self->{all_id}->{$id})) {
	@$repos = keys(%{$self->{all_id}->{$id}});
    }
    return $repos;
}

sub hash_repos
{
   my ($self, $id) = @_;
   return $self->{all_id}->{$id};
}

sub langs
{
    my ($self, $id) = @_;
    return $self->{lang}->{$id};
}

sub sample_users
{
    my ($self) = @_;
    my $users = [];
    
    @$users = keys(%{$self->{id}});
    
    return $users;
}

sub users
{
    my ($self) = @_;
    my $users = [];
    
    @$users = keys(%{$self->{all_id}});
    
    return $users;
}

1;
