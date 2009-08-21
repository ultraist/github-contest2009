use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;
use constant {
    DEL_N => 5000
};
$|=1;

{
    print "$0: loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/contest_data.txt", $lang);
    my $test_user = new User("./download/train_data.txt", $lang);
    my $test = new Result("./download/train_test.txt", $lang);
    my $results = new Result("results.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    my $success = 0.0;
    my $match = 0.0;
    my @count;
    $repo->set_lang($lang);
    $repo->ranking($user);
    

    foreach my $uid (@{$test->users()}) {
	my $user_repos = $user->repos($uid);
	my $test_repos = $results->repos($uid);
	if (!defined($test_repos)) {
	    next;
	}
	for (my $i = 0; $i < @$test_repos; ++$i) {
	    my $ok = Utils::intersection_count($user_repos, [$test_repos->[$i]]);
	    $count[$i] += $ok;
	    $success += $ok;
	}
    }
    printf("success: %f(%d/%d)\n", $success / ($test->count() ), $success, $test->count() );
    for (my $i = 0; $i < 50; ++$i) {
	printf("%d %d\n", $i, $count[$i] ? $count[$i]:0);
    }
}
