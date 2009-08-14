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

    open(UI, ">user.head") or die $!;
    open(RI, ">repo.head") or die $!;
    open(RD, ">repo.dat") or die $!;

    my @repo_ids = sort { $a <=> $b } @{$repo->repos()};
    my @user_ids = sort { $a <=> $b } @{$user->sample_users()};
    my %user_repos;
    print UI join(",", @user_ids), "\n";
    close(UI);
    
    for (my $m = 0; $m < @user_ids; ++$m) {
	my $repos = $user->hash_repos($user_ids[$m]);
	$user_repos{$user_ids[$m]} = $repos;
    }

    # octave matrix
    # [u1r1,u2r1 .. uMr1 ]
    # [u1r2,   ..
    # [..
    # [u1rN         uMrN ]
    for (my $n = 0; $n < @repo_ids; ++$n) {
	my $repo_id = $repo_ids[$n];
	my $line = '';
	my $c = 0;
	printf("repo ..%d\r", $n);
	for (my $m = 0; $m < @user_ids; ++$m) {
	    my $f = defined($user_repos{$user_ids[$m]}->{$repo_id}) ? 1:0;
	    $line .= $f." ";
	    $c += $f;
	}
	if ($c != 0) {
	    if ($n != 0) {
		print RI ",";
	    }
	    print RI "$repo_id";
	    print RD "$line\n";
	}
    }
    print RI "\n";
    close(RD);
    close(RI);
}

    
    
    
