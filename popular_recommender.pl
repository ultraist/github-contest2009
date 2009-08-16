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

sub lang_score
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

sub repo_score
{
    my ($repo, $id) = @_;
    my $forks = $repo->fork_repos($id);
    my $score = $repo->freq($id);
    
    foreach my $fid (@$forks) {
	$score += $repo->freq($fid);
    }

    return $score;
}

popular_recommender:
{
    print "$0: loading ..\r";
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
    $lang->make_lang_repos($repo);
    
    my $no1_forks = scalar(@{$repo->fork_repos($repo->rank_id(0))});
    my $fork_factor = 1.0 / $no1_forks;

    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my $user_repos = $user->repos($uid);
	my $langs = $user->langs($uid);

	if (defined($langs) && scalar(@$langs) > 0) {
	    my %lang_repos;
	    my @minor_langs;
	    my $c = 0;
	    foreach my $l (@$langs) {
		push(@minor_langs, { lang => $l, freq => $lang->freq($l) });
	    }
	    @minor_langs = sort { $a->{freq} <=> $b->{freq} } @minor_langs;

	    foreach my $r (@{$lang->lang_repos($minor_langs[0]->{lang})}) {
		$lang_repos{$r} = 1;
	    }
	    
	    foreach my $rid (keys(%lang_repos)) {
		my $lang_score = lang_score($lang, $repo->langs($rid), $user->langs($uid));

		push(@result_tmp, {
		    id => $rid,
		    score => $lang_score + 0.1 * $repo->freq($rid)
		});
	    }
	    for (my $i = 0; $i < 20; ++$i) {
		my $rank_id = $repo->rank_id($i);
		push(@result_tmp, {
		    id => $rank_id,
		    score => 0.1 * $repo->freq($rank_id)
		});
	    }
	} else {
	    for (my $i = 0; $i < 20; ++$i) {
		my $rank_id = $repo->rank_id($i);
		
		push(@result_tmp, {
		    id => $rank_id,
		    score => $repo->freq($rank_id)
		});
	    }
	}

	@result_tmp = sort { $b->{score} <=> $a->{score} } @result_tmp;
	my $c = 0;
	foreach my $rid (@result_tmp) {
	    if (!Utils::includes($user_repos, $rid->{id})) {
		push(@result, $rid->{id});
		push(@$user_repos, $rid->{id});
		if (++$c >= 20) {
		    last;
		}
	    }
	}
	print R Result::format($uid, @result);
        ++$i;
    }
    close(R);
}


