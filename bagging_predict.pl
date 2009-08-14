use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;

our $RECOMMENDER = {
    { file => "./results_fork.txt", weight => 4.9914 },
    { file => "./results_base.txt", weight => 293.9866 },
    { file => "./results_author.txt", weight => 24.4273 },
    { file => "./results_language.txt", weight => 5.8663 },
    { file => "./results_base_author_.txt", weight => 46.8424 },
    { file => "./results_co_occurrence_.txt", weight => 46.8424 },
};

bagging_predict:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_fork.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);

	foreach my $bid (@$user_repos) {
	    foreach my $rid (@{$repo->fork_repos($bid)}) {
		push(@result_tmp, { id => $rid, rank => $repo->rank($rid) });
	    }
	}
	@result_tmp = sort { $a->{rank} <=> $b->{rank} } @result_tmp;
	foreach my $rid (@result_tmp) {
	    if (!Utils::includes($user_repos, $rid->{id})) {
		push(@result, $rid->{id});
		push(@$user_repos, $rid->{id});
	    }
	}
	print R Result::format($uid, @result);
        ++$i;
    }
    close(R);
}


