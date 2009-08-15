package User;
use strict;
use warnings;
use List::MoreUtils qw/uniq/;

sub new 
{
    my($pkg, $filename, $lang) = @_;
   
    my $user = _load_user($filename, $lang);

    return bless($user, $pkg);
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
	if ($avg / 4 < $p ) {#&& $p < $avg + $sd * 2) {
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
	push(@{$user_lang->{$uid}}, uniq(@skill_lang));
    }
    
    return { id => $sample_user, all_id => $user, hash => $repo_hash, lang => $user_lang, n => $samples};
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
