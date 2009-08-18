use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

use constant {
    K => 20
};
$|=1;
our $e = exp(1);

sub sim
{
    my ($a, $h, $user) = @_;
    my $ok = 0;

    foreach my $k (@$a) {
	if (defined($h->{$k})) {
	    $ok += 1;
	}
    }
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    return $ok / ($n1 > $n2 ? $n1:$n2);
}

co_occurrence_recommender:
{
    srand (100);
    print "$0: loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    my $kfrac = 1.0 / K;
    
    open(R, ">results_similar.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->set_users($user);
    $repo->ranking($user);
    
    my $repos = $repo->repos();    
    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	my @result;
	my @result_tmp;
	my $user_repos = $user->repos($uid);

	foreach my $rid (@$user_repos) {
	    my $repos_user = $repo->users($rid);
	    my @sim_repos;
	    my @candidates;

	    if ($repo->freq($rid) > 0.01) {
		next;
	    }

	    foreach my $ruid (@$repos_user) {
		push(@candidates, @{$user->repos($ruid)});
	    }

	    foreach my $other_id (@candidates) {
		my $sim = sim($repos_user, $repo->hash_users($other_id), $user);
		if ($sim != 0.0) {
		    push(@sim_repos, { id => $other_id, sim => $sim });
		}
	    }
	    @sim_repos = sort { $b->{sim} <=> $a->{sim} } @sim_repos;
	    if (@sim_repos > K) {
		@sim_repos = @sim_repos[0 .. 19];
	    }
	    push(@result_tmp, @sim_repos);
	}
	
	@result_tmp = sort { $b->{sim} <=> $a->{sim} } @result_tmp;
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


