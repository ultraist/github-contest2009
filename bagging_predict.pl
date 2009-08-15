use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;

# recommender
#
# fork_predict           3.11  / 0.62306 =   4.9914
# base_predict          23.76  / 0.08082 = 293.9866
# author_predict        16.37  / 0.67015 =  24.4273
# language_predict       5.576 / 0.95050 =   5.8663
# ranking_predict        5.847 / 1.00000 =   5.8470
# base_author_precit    21.80  / 0.46539 =  46.8424
# co_occurrence_predict 19.11  / 0.77637 = 24.61455

our @RECOMMENDER = (
		    { file => "./results_base.txt",          weight => 1.0 * 1.0 },
		    { file => "./results_base_author.txt",   weight => 1.0 * 0.2 },
		    { file => "./results_co_occurrence.txt", weight => 1.0 * 1.25 },
		    { file => "./results_author.txt",        weight => 1.0 * 0.5 },
		    { file => "./results_language.txt",      weight => 0.05 },
		    { file => "./results_ranking.txt",       weight => 0.1 }
#		    { file => "./results_fork.txt",          weight => 1.0 }
);

sub rank_score
{
    my $rank = shift;
#    return 1.0 / (1.0 + exp(0.5 * ($rank - 10)));
    return (1.0 / (1.0 + $rank));
}


sub load_recommender
{
    my $recommender = [];

    foreach my $rec (@RECOMMENDER) {
	print "loading.. $rec->{file}\r";
	my $result = new Result($rec->{file});
	my $weight = $rec->{weight};
	push(@$recommender, { result => $result, weight => $rec->{weight} });
    }

    return $recommender;
}

bagging_predict:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    my $recommender = load_recommender();
    
    open(R, ">results_bagging.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    print "ok..\n";
    
    foreach my $uid (@{$test->users()}) {
	printf("recommend %.2f\r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my %reco_repo;
	my $user_repos = $user->repos($uid);

	foreach my $reco (@$recommender) {
	    my $repos = $reco->{result}->repos($uid);

	    for (my $i = 0; $i < @$repos; ++$i) {
		if (!exists($reco_repo{$repos->[$i]})) {
		    $reco_repo{$repos->[$i]} = 0.0;
		}
		$reco_repo{$repos->[$i]} += rank_score($i) * $reco->{weight};
	    }
	}
	foreach my $rid (keys(%reco_repo)) {
	    push(@result_tmp, { id => $rid, score => $reco_repo{$rid} });
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


