use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

use constant {
    K => 80
};
$|=1;
our $e = exp(1);
our $p1 = 1.0 /  2.0; # similar
our $p0 = 1.0 / 10.0; # not similar

sub sim2
{
    my ($a, $h) = @_;
    my $k = 0;
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    my $n = ($n1 > $n2 ? $n1:$n2);

    if ($n == 0) {
	return 0.0;
    }

    foreach my $id (@$a) {
	if (defined($h->{$id})) {
	    $k += 1;
	}
    }
    if ($k == 0) {
	return 0.0;
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
	    $ok += log($e + 1.0 / $repo->freq($k));
	}
    }
    if ($ok == 0.0) {
	return 0.0;
    }
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    return $ok / ($n1 > $n2 ? $n1:$n2);
}

co_occurrence_recommender:
{
    print "$0: loading ..\r";
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
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	my @nn;
	my @result;
	my @result_tmp;
	my $user_repos = $user->repos($uid);
	my @sim_users;
	my %co_repos;
	
	foreach my $other_id (@{$user->sample_users()}) {
	    my $sim = sim2($user_repos, $user->hash_repos($other_id), $repo);
	    if ($sim != 0.0) {
		push(@sim_users, { id => $other_id, sim => $sim});
	    }
	}
	@sim_users = sort { $b->{sim} <=> $a->{sim} } @sim_users;

	for (my $i = 0; $i < K && $i < scalar(@sim_users); ++$i) {
	    my $other_repos = $user->repos($sim_users[$i]->{id});
	    my $w = $sim_users[$i]->{sim};#(1.0 - $i / K) ** 2;
	    foreach my $rid (@$other_repos) {
		if (!exists($co_repos{$rid})) {
		    $co_repos{$rid} = 0.0;
		}
		$co_repos{$rid} += $w;
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


