use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;
use List::MoreUtils qw/uniq/;
$|=1;


our $e = exp(1);
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

    foreach my $rid (@$user_repos) {
	my $sim = sim($users, $repo->hash_users($rid));
	if ($sim > $max_sim) {
	    $max_sim = $sim;
	}
    }
    return $max_sim + 0.01 * $repo->freq($id);
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
	    my @rel_repo;
	    push(@rel_repo, @{$repo->base_repos($bid)});
	    push(@rel_repo, @{$repo->fork_repos($bid)});
	    @rel_repo = uniq(@rel_repo);
	    
	    foreach my $rid (@rel_repo) {
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


