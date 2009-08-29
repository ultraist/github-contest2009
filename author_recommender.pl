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
our $log_p1 = log($p1);
our $log_1_p1 = log(1.0 - $p1);
our $log_p0 = log($p0);
our $log_1_p0 = log(1.0 - $p0);
our $min_lrt = -likelihood_ratio_test(0, 1);
our $scale_lrt = 1.0 / ($min_lrt + likelihood_ratio_test(1, 1));

sub likelihood_ratio_test
{
    my ($k, $n) = @_;
    return (($log_p1 * $k + $log_1_p1 * ($n - $k))
	    - ($log_p0 * $k + $log_1_p0 * ($n - $k)));
}

sub sim2
{
    my ($a, $h) = @_;
    my $k = 0;
    my ($n1, $n2) = (scalar(@$a), scalar(keys(%$h)));
    my $n = ($n1 > $n2 ? $n1:$n2);

    if ($n == 0) {
	return 0;
    }
    
    foreach my $id (@$a) {
	if (defined($h->{$id})) {
	    $k += 1;
	}
    }

    return $scale_lrt * ($min_lrt + likelihood_ratio_test($k / $n, 1.0));
}

sub lang_score
{
    my($lang, $repo, $user) = @_;
    my $score = 0.0;
    if (!$user || scalar(@$user) == 0) {
	return 0.0;
    }
    if (!$repo) {
	return 0.0;
    }
    my ($n1, $n2) = (scalar(@$user), scalar(keys(%$repo)));

    foreach my $user_lang (@$user) {
	if (defined($repo->{$user_lang})) {
	    $score += log($e + 1.0 / $lang->freq($user_lang));
	}
    }
    return $score / ($n1 > $n2 ? $n1:$n2);
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
    my ($repo, $user, $lang, $user_repos, $id) = @_;
    my $max_sim = 0.0;
    my $users = $repo->users($id);
    my $sum = 0;
    my $n = scalar(@$user_repos);
    my $repo_langs = $repo->langs($id);
    my $name = $repo->langs($id);
    my %repo_lang_hash;
    foreach my $repo_lang (@$repo_langs) {
	$repo_lang_hash{$repo_lang} = 1;
    }

    
    $n = $n == 0 ? 1:$n;
    
    foreach my $rid (@$user_repos) {
	my $sim = 1.0 * sim($users, $repo->hash_users($rid), $user) + 0.8 * lang_score($lang, \%repo_lang_hash, $repo->langs($rid));
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
    $lang->ranking($repo);
    $lang->make_lang_repos($repo);

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
		push(@result_tmp, { id => $rid, score => $author_freq{$a} * author_score($repo, $user, $lang, \@origin_user_repos, $rid) });
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


