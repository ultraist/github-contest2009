use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;
our $e = exp(1);

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
	my %user_lang_hash;
        
        

	if (defined($langs) && scalar(@$langs) > 0) {
	    my %lang_repos;
	    my @minor_langs;
	    my $c = 0;
          
            foreach my $user_lang (@{$user->langs($uid)}) {
              $user_lang_hash{$user_lang} = 1;
            }
            
	    foreach my $l (@$langs) {
		push(@minor_langs, { lang => $l, freq => $lang->freq($l) });
	    }
	    @minor_langs = sort { $a->{freq} <=> $b->{freq} } @minor_langs;

	    foreach my $r (@{$lang->lang_repos($minor_langs[0]->{lang})}) {
		$lang_repos{$r} = 1;
	    }
	    
	    foreach my $rid (keys(%lang_repos)) {
		my $lang_score = lang_score($lang, \%user_lang_hash, $repo->langs($rid));
		push(@result_tmp, {
		    id => $rid,
		    score => $lang_score + 0.5 *  $repo->freq($rid)
		});
	    }
	    for (my $i = 0; $i < 30; ++$i) {
		my $rank_id = $repo->rank_id($i);
		push(@result_tmp, {
		    id => $rank_id,
		    score => 0 + 0.5 * $repo->freq($rank_id)
		});
	    }
	} else {
	    for (my $i = 0; $i < 30; ++$i) {
		my $rank_id = $repo->rank_id($i);
		
		push(@result_tmp, {
		    id => $rank_id,
		    score => 0.5 * $repo->freq($rank_id)
		});
	    }
	}

	@result_tmp = sort { $b->{score} <=> $a->{score} } @result_tmp;
	my $c = 0;
	foreach my $rid (@result_tmp) {
	    if (!Utils::includes($user_repos, $rid->{id})) {
		push(@result, $rid->{id});
		push(@$user_repos, $rid->{id});
		if (++$c >= 30) {
		    last;
		}
	    }
	}
	print R Result::format($uid, @result);
        ++$i;
    }
    close(R);
}


