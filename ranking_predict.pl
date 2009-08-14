use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;

ranking_predict:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_ranking.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);

	for (my $i = 0; $i < 100; ++$i) {
	    my $rank_id = $repo->rank_id($i);
	    push(@result_tmp, { id => $rank_id, rank => $i });
	}
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


