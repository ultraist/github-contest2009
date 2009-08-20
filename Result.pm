package Result;
use strict;
use warnings;

sub new
{
    my ($pkg, $filename, $max) = @_;
    my $result = _load_result($filename, $max);

    return bless({user => $result, n => scalar(keys(%$result)) }, $pkg);
}

sub _load_result
{
    my ($filename, $max) = @_;
    my $user_repos = {};
    my $c = 0;
    open(T, $filename) or die $!;

    while (my $line = <T>) {
	chomp($line);
	my ($uid, $repo_line) = split(":", $line);
	my @repos;

	if ($repo_line) {
	    @repos = split(",", $repo_line);
	    if (defined($max) && $max < scalar(@repos)) {
		@repos = @repos[0 .. $max - 1];
	    }
	}
	$user_repos->{$uid} = [];
	push(@{$user_repos->{$uid}}, @repos);
    }
    close(T);

    return $user_repos;
}

sub users
{
    my($self) = @_;
    my $users = [];
    @$users = keys(%{$self->{user}});

    return $users;
}

sub repos
{
    my($self, $id) = @_;
    return $self->{user}->{$id};
}

sub format
{
    my ($uid, @repos) = @_;
    return sprintf("%s:%s\n", $uid, join(",", @repos));
}

sub count
{
    my $self = shift;
    return $self->{n};
}
    

1;
