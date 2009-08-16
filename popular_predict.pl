use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;

sub match_lang
{
    my($repo, $user) = @_;

    if (!$user || scalar(@$user) == 0) {
	return 1;
    }
    if (!$repo || scalar(@$repo) == 0) {
	return undef;
    }
    return Utils::intersection_count($repo, $user) > 0 ? 1:undef;
}

popular_predict:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_popular.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);

	for (my $i = 0; $i < 100; ++$i) {
	    my $rank_id = $repo->rank_id($i);
	    if (match_lang($repo->langs($rank_id), $user->langs($uid))) {
		push(@result_tmp, { id => $rank_id, rank => $i});
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

