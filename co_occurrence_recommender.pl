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

sub lang_score
{
    my($lang, $user, $other) = @_;
    my $score = 0.0;
    if (!$user || scalar(@$user) == 0) {
	return 0.0;
    }
    if (!$other || scalar(@$other) == 0) {
	return 0.0;
    }
    my ($n1, $n2) = (scalar(@$user), scalar(@$other));

    foreach my $user_lang (@$user) {
	foreach my $other_lang (@$other) {
	    if ($user_lang eq $other_lang) {
               $score += log($e + 1.0 / $lang->freq($user_lang));
	    }
	}
    }
    return $score / ($n1 > $n2 ? $n1:$n2);
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
    
    open(R, ">results_co_occurrence.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->set_users($user);
    $repo->ranking($user);
    $lang->ranking($repo);
    $lang->make_lang_repos($repo);

    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	
	my @result;
	my @result_tmp;
	my $user_repos = $user->repos($uid);
	my $user_langs = $user->langs($uid);
	my @sim_users;
	my %co_repos;
	my @sim_cand;
	my $min_repos = $user->repo_avg() / 4;
	my $max_repos = $user->repo_avg() + $user->repo_sd() * 3;

	foreach my $rid (@$user_repos) {
	    my $users = $repo->users($rid);
	    if ($users) {
		foreach my $id (@$users) {
		    my $p = scalar(@{$user->repos($id)});
		    if ($min_repos < $p && $p < $max_repos) {
			push(@sim_cand, $id);
		    }
		}
	    }
	}
	@sim_cand = Utils::uniq(@sim_cand);
	foreach my $other_id (@sim_cand) {
	    my $sim = sim($user_repos, $user->hash_repos($other_id), $repo) + 0.05 * lang_score($lang, $user_langs, $user->langs($other_id));
	    if ($sim != 0.0) {
		push(@sim_users, { id => $other_id, sim => $sim});
	    }
	}
	@sim_users = sort { $b->{sim} <=> $a->{sim} } @sim_users;

	for (my $i = 0; $i < K && $i < scalar(@sim_users); ++$i) {
	    my $other_repos = $user->repos($sim_users[$i]->{id});
	    my $w = $sim_users[$i]->{sim};#(1.0 - $i / K) ** 2;#
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


