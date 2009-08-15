use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;

$|=1;

matrix_format:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $i = 0;
    my $nonzero = 0;
    
    open(UI, ">user.head") or die $!;
    open(RI, ">repo.head") or die $!;
    open(RD, ">repo.dat") or die $!;

    my @repo_ids = sort { $a <=> $b } @{$repo->repos()};
    my @user_ids = sort { $a <=> $b } @{$user->sample_users()};
    my %user_repos;
    print UI join(",", @user_ids), "\n";
    print RI join(",", @repo_ids), "\n";
    close(UI);
    
    for (my $m = 0; $m < @user_ids; ++$m) {
	my $repos = $user->hash_repos($user_ids[$m]);
	$user_repos{$user_ids[$m]} = $repos;
    }

    # sparse  matrix
    my $rows = scalar(@repo_ids);
    my $cols = scalar(@user_ids);
    
    for (my $m = 0; $m < @user_ids; ++$m) {
	print "$m.. \r";
	my $vec = $user_repos{$user_ids[$m]};
	my $c = 0;
	my $lines = "";
	my @sparse = ();
	for (my $n = 0; $n < @repo_ids; ++$n) {
	    my $repo_id = $repo_ids[$n];
	    if (defined($vec->{$repo_id})) {
		push(@sparse, $n);
		++$c;
	    }
	}
	$nonzero += $c;
	print RD $c,"\n";
	foreach my $n (@sparse) {
	     $lines .= "$n 1\n";
	}
	print RD $lines;
    }
    print "\n$rows $cols $nonzero\n";

    close(RD);
    close(RI);
}

    
    
    
