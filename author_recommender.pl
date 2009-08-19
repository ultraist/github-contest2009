use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;
our $e = exp(1);
sub sim
{
    my ($a, $h) = @_;
    my $ok = 0;

    foreach my $k (@$a) {
	if (defined($h->{$k})) {
	    $ok += 1;
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

    foreach my $rid (@$user_repos) {
	my $sim = sim($users, $repo->hash_users($rid));
	if ($sim > $max_sim) {
	    $max_sim = $sim;
	}
    }
    return $max_sim + 0.0001 * $repo->freq($id);
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
	printf("$0:                    %.2f%%      \r", 100 * $i / $count);
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
		printf("$0: $tid\r");
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


