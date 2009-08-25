use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;
use constant {
    SIM_NAME_MAX => 5000
};
$|=1;

sub split_name
{
    my $name = shift;
    my @n;
    my @ret;
    
    push(@n, split(/_+/, $name));
    push(@n, split(/\-+/, $name));
    
    @n = Utils::uniq(@n);
    
    foreach my $nn (@n) {
	$nn =~ tr/A-Z/a-z/;
	if (length($nn) > 3) {
	    $nn =~ s/ies$/ty/;
	    $nn =~ s/es$//;
	    $nn =~ s/ed$//;
	    $nn =~ s/s$//;
	}
	push(@ret, $nn);
    }
    
    return @ret;
}

sub sim_name_repos
{
    my ($idx, $name) = @_;
    my @n = split_name($name);
    my @sim;
    
    foreach my $nn (@n) {
	if (defined($idx->{$nn})) {
	    push(@sim, keys(%{$idx->{$nn}}));
	}
    }
    return Utils::uniq(@sim);
}

sub make_name_index
{
    my $repo = shift;
    my $idx = {};
    
    foreach my $rid (@{$repo->repos()}) {
	my $name = $repo->name($rid);
	my @n = split_name($name);
	foreach my $nn (@n) {
	    $idx->{$nn}->{$rid} = 1;
	}
    }
    return $idx;
}

sub sim
{
    my ($a, $h) = @_;
    my $ok = 0;

    foreach my $k (@$a) {
	if (defined($h->{$k})) {
	    $ok += 1;
	}
    }
    if ($ok == 0) {
	return 0.0;
    }
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    return $ok / ($n1 > $n2 ? $n1:$n2);
}

sub repo_score
{
    my ($repo, $user, $user_repos, $id) = @_;
    my $max_sim = 0.0;
    my $users = $repo->users($id);
    my $sum = 0;
    
    return $repo->freq($id);

    foreach my $rid (@$user_repos) {
	my $sim = sim($users, $repo->hash_users($rid));
	if ($sim > $max_sim) {
	    $max_sim = $sim;
	}
    }
    return $max_sim + 0.0001 * $repo->freq($id);
}

name_recommender:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_name.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    my $idx = make_name_index($repo);

    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f\r", 100 * $i / $count);
	my @result;
	my @result_tmp;
	my @sim_repos;
	my $user_repos = $user->repos($uid);
	my $hash_repos = $user->hash_repos($uid);
	
	foreach my $rid (@$user_repos) {
	    my @sim = sim_name_repos($idx, $repo->name($rid));
	    @sim = Utils::remove_list(\@sim, $user_repos);
	    push(@sim_repos, @sim);
	    @sim_repos = Utils::uniq(@sim_repos);
	    if (scalar(@sim_repos) > SIM_NAME_MAX) {
		last;
	    }
	}
	foreach my $rid (@sim_repos) {
	    push(@result_tmp, { id => $rid, score => repo_score($repo, $user, $user_repos, $rid) });
	}
	@result_tmp = sort { $b->{score} <=> $a->{score} } @result_tmp;
	foreach my $rid (@result_tmp) {
	    if (!defined($hash_repos->{$rid->{id}})) {
		push(@result, $rid->{id});
		$hash_repos->{$rid->{id}} = 1;
	    }
	}
	print R Result::format($uid, @result);
        ++$i;
    }
    close(R);
}


