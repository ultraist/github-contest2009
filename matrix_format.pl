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

    open(RI, ">user.head") or die $!;
    open(UI, ">repo.head") or die $!;
    open(RD, ">repo.dat") or die $!;

    my @repo_ids = sort { $a <=> $b } @{$repo->repos()};
    my @user_ids = sort { $a <=> $b } @{$user->sample_users()};

    print RI join(",", @repo_ids), "\n";
    print UI join(",", @user_ids), "\n";
    close(RI);
    close(UI);

    # octave matrix
    # [u1r1,u2r1 .. uMr1 ]
    # [u1r2,   ..
    # [..
    # [u1rN         uMrN ]
    for (my $n = 0; $n < @repo_ids; ++$n) {
	for (my $m = 0; $m < @user_ids; ++$m) {
	    my $user_repo = $user->hash_repos($user_ids[$m]);
	    print RD (defined($user_repos->{$repo_ids[$n]}) ? 1:0), " ";
	}
	print "\n"
    }
    close(RD);
}

    
    
    
