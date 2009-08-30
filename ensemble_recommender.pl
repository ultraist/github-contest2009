use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;
use constant {
    DEF_K => 30
};
$|=1;


our @RECOMMENDER = (
		    {
			file => "./results_forkbase.txt",
			weight => 2.0,
			K => DEF_K,
			score => sub { 1.0 / (1.0 + $_[0]); }
		    },
		    {
			file => "./results_co_occurrence.txt",
			weight => 1.5,
			K => DEF_K,
			score => sub { 1.0 / (1.0 + $_[0]); }
		    },
		    {
			file => "./results_author.txt",
			weight => 0.6,
			K => DEF_K + 10,
			score => sub { 1.0 / (1.5 + $_[0]) ** 1.2; }
		    },
		    {
			file => "./results_name.txt",
			weight => 0.3,
			K => DEF_K,
			score => sub { 1.0 / (1.5 + $_[0]); }
		    },
		    {
			file => "./results_popular.txt",
			weight => 0.1,
			K => 10,
			score => sub { 1.0 / (1.0 + $_[0]); }
		    }
);

sub rank_score
{
    my $rank = shift;
    return (1.0 / (1.5 + $rank));
}

sub load_recommender
{
    my $recommender = [];

    foreach my $rec (@RECOMMENDER) {
	print "loading.. $rec->{file}\r";
	my $result = new Result($rec->{file}, $rec->{K});
	my $weight = $rec->{weight};
	push(@$recommender, { result => $result, weight => $rec->{weight}, K => $rec->{K}, score => $rec->{score} });
    }

    return $recommender;
}

ensemble_recommender:
{
    print "$0: loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    my $recommender = load_recommender();
    
    open(R, ">results_ensemble.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    print "ok..\n";
    
    foreach my $uid (@{$test->users()}) {
	printf("$0: %.2f%%      \r", 100 * $i / $count);
	my @result_tmp;
	my @result;
	my %reco_repo;
	my $user_repos = $user->repos($uid);

	foreach my $reco (@$recommender) {
	    my $repos = $reco->{result}->repos($uid);
	    if (!defined($repos)) {
		next;
	    }
	    for (my $i = 0; $i < $reco->{K} && $i < @$repos; ++$i) {
		if (!exists($reco_repo{$repos->[$i]})) {
		    $reco_repo{$repos->[$i]} = 0.0;
		}
		$reco_repo{$repos->[$i]} += &{$reco->{score}}($i) * $reco->{weight};
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


