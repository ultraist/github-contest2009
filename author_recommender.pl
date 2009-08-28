use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;
our $e = exp(1);
our $p1 = 1.0 / 4.0;  # similar
our $p0 = 1.0 / 50.0; # not similar
our $min_lrt = -likelihood_ratio_test(0, 1);

sub likelihood_ratio_test
{
    my ($k, $n) = @_;
    return ((log($p1) * $k + log((1.0 - $p1)) * ($n - $k))
	    - (log($p0) * $k + log((1.0 - $p0)) * ($n - $k)));
}

sub sim2
{
    my ($a, $h) = @_;
    my $k = 0;
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    my $n = ($n1 > $n2 ? $n1:$n2);

    if ($n == 0) {
	return $min_lrt + likelihood_ratio_test(0, 1.0); #0
    }
    
    foreach my $id (@$a) {
	if (defined($h->{$id})) {
	    $k += 1;
	}
    }

    return $min_lrt + likelihood_ratio_test($k / $n, 1.0);
}

sub sim
{
    my ($a, $h, $user) = @_;
    my $ok = 0;

    foreach my $k (@$a) {
	if (defined($h->{$k})) {
	    $ok += log($e + 1.0 / $user->freq($k));
	}
    }
    if ($ok == 0) {
	return 0.0;
    }
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    return $ok / ($n1 > $n2 ? $n1:$n2);
}

sub author_score
{
    my ($repo, $user, $user_repos, $id) = @_;
    my $max_sim = 0.0;
    my $users = $repo->users($id);
    my $sum = 0;
    my $n = scalar(@$user_repos);
    $n = $n == 0 ? 1:$n;
    
    foreach my $rid (@$user_repos) {
	my $sim = sim2($users, $repo->hash_users($rid));#sim($users, $repo->hash_users($rid), $user);
	$sum += $sim;
    }
    return $sum / $n;#$max_sim;# + 0.0001 * $repo->freq($id);
}

author_recommender:
{
    print "$0: loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    
    open(R, ">results_author.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->set_users($user);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my @user_repos = @{$user->repos($uid)};
	my @origin_user_repos = @user_repos;
	my %author_freq;
	my $max_count = 0;
	
	foreach my $tid (@user_repos) {
	    ++$author_freq{$repo->author($tid)};
	}
	foreach my $a (keys(%author_freq)) {
	    if ($max_count < $author_freq{$a}) {
		$max_count = $author_freq{$a};
	    }
	}
	if ($max_count > 0) {
	    my $factor = 1.0 / $max_count;
	    foreach my $a (keys(%author_freq)) {
		$author_freq{$a} *= $factor;
	    }
	}
	foreach my $tid (@user_repos) {
	    foreach my $rid (@{$repo->author_repos($tid)}) {
		my $a = $repo->author($rid);
		push(@result_tmp, { id => $rid, score => $author_freq{$a} * author_score($repo, $user, \@origin_user_repos, $rid) });
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


