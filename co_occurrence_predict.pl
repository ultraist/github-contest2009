use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

use constant {
    K => 100
};
$|=1;

sub sim
{
    my ($a, $h) = @_;
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    my $ok = 0;

    foreach my $k (@$a) {
	if (defined($h->{$k})) {
	    ++$ok;
	}
    }
    
    return $ok / ($n1 > $n2 ? $n1:$n2);
}

co_occurrence_predict:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    my $kfrac = 1.0 / K;
    
    open(R, ">results_co_occurrence.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @nn;
	my @result;
	my @result_tmp;
	my $user_repos = $user->repos($uid);
	my @sim_users;
	my %co_repos;
	
	foreach my $other_id (@{$user->sample_users()}) {
	    my $sim = sim($user_repos, $user->hash_repos($other_id));
	    if ($sim != 0.0) {
		push(@sim_users, { id => $other_id, sim => $sim });
	    }
	}
	@sim_users = sort { $b->{sim} <=> $a->{sim} } @sim_users;

	for (my $i = 0; $i < K && $i < scalar(@sim_users); ++$i) {
	    my $other_repos = $user->repos($sim_users[$i]->{id});
	    foreach my $rid (@$other_repos) {
		my $w = $sim_users[$i]->{sim};#(1.0 - $i / K) ** 2;
		if (!exists($co_repos{$rid})) {
		    $co_repos{$rid} = 0.0;
		}
		$co_repos{$rid} += $w + $w * $kfrac * $repo->rate($rid);
	    }
	}
	foreach my $rid (keys(%co_repos)) {
	    push(@result_tmp, { id => $rid, w => $co_repos{$rid} });
	}
	@result_tmp = sort { $b->{w} <=> $a->{w} } @result_tmp;
	
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


