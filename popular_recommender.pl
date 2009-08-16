use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;
our $e = exp(1);

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

sub match_lang_score
{
    my($lang, $repo, $user) = @_;
    my $score = 0.0;
    
    if (!$user || scalar(@$user) == 0) {
	return 0.0;
    }
    if (!$repo || scalar(@$repo) == 0) {
	return 0.0;
    }

    foreach my $user_lang (@$user) {
	foreach my $repo_lang (@$repo) {
	    if ($user_lang eq $repo_lang) {
		$score += log($e + 1.0 / $lang->freq($user_lang));
	    }
	}
    }
    return $score;
}

popular_recommender:
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
    $lang->ranking($repo);

    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);

	for (my $i = 0; $i < 300; ++$i) {
	    my $rank_id = $repo->rank_id($i);
	    my $score = match_lang_score($lang, $repo->langs($rank_id), $user->langs($uid));

	    push(@result_tmp, { id => $rank_id, score => $score + 0.1 * $repo->freq($rank_id) });
	}
	@result_tmp = sort { $b->{score} <=> $a->{score} } @result_tmp;
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


