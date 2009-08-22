use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;
$|=1;

our $e = exp(1);
our $p1 = 1.0 /  4.0; # similar
our $p0 = 1.0 / 50.0; # not similar

sub sim2
{
    my ($a, $h) = @_;
    my $k = 0;
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    my $n = ($n1 > $n2 ? $n1:$n2);
    if ($n == 0) {
	return -100.0;
    }

    foreach my $id (@$a) {
	if (defined($h->{$id})) {
	    $k += 1;
	}
    }

    return ((log($p1) * $k + log((1.0 - $p1)) * ($n - $k))
	  - (log($p0) * $k + log((1.0 - $p0)) * ($n - $k)));
}

sub sim
{
    my ($a, $h, $repo) = @_;
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

sub forkbase_score
{
    my ($repo, $user_repos, $id) = @_;
    my $max_sim = 0.0;
    my $users = $repo->users($id);

    if ($users) {
	foreach my $rid (@$user_repos) {
	    my $sim = sim2($users, $repo->hash_users($rid));
	    if ($sim > $max_sim) {
		$max_sim = $sim;
	    }
	}
    }
    return $max_sim;# + 0.0001 * $repo->freq($id);
}


forkbase_recommender:
{
    print "$0: loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_forkbase.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	my @user_repos = @{$user->repos($uid)};
	my @origin_user_repos = @user_repos;

	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);

	foreach my $bid (@user_repos) {
	    foreach my $rid (@{$repo->base_repos($bid)}) {
		push(@result_tmp, { id => $rid, score => forkbase_score($repo, \@origin_user_repos, $rid) });
	    }
	}
	@result_tmp = sort { $b->{score} <=> $a->{score} } @result_tmp;
	foreach my $rid (@result_tmp) {
	    if (!Utils::includes(\@user_repos, $rid->{id})) {
		push(@result, $rid->{id});
		push(@user_repos, $rid->{id});
	    }
	}
	print R Result::format($uid, @result);
        ++$i;
    }
    close(R);
}


