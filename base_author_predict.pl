use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;

base_author_predict:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_base_author.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);

	foreach my $bid (@$user_repos) {
	    foreach my $rid (@{$repo->base_repos($bid)}) {
		foreach my $aid (@{$repo->author_repos($rid)}) {
		    push(@result_tmp, { id => $aid, rank => $repo->rank($aid) });
		}
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


