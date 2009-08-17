use strict;
use warnings;
use PDL;
use PDL::IO::FastRaw;
use Repo;
use User;
use Lang;
use Result;
use Utils;

use constant {
    K => 30
};

$|=1;

sub load_Ut
{
    my $ut = [];
    my $line;
    
    open(UT, "repo-Ut") or die $!;
    $line = <UT>;
    chomp($line);
    my ($row, $col) = split(" ", $line);
    $row = K;
    print "$row, $col\n";
    print "alloc\n";
    my $i = 0;
    while ($line = <UT>) {
	chomp($line);
	my @cols = split(/ +/, $line);
	push(@$ut, \@cols);
	if (++$i >= $row) {
	    last;
	}
    }
    return $ut;
}

sub repo_vector
{
    my ($hash_repos, $repo_ids) = @_;
    my $N = scalar(@$repo_ids);
    my $vec = [];
    
    for (my $n = 0; $n < $N; ++$n) {
	push(@$vec, (defined($hash_repos->{$repo_ids->[$n]}) ? [1.0]:[0.0]));
    }
    return $vec;
}

lsa:
{
    print "loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/data.txt", $lang);
    my $test = new Result("./download/test.txt", $lang);
    my $count = $test->count();
    my $i = 0;

    print "go..\n";
    my @repo_ids = sort { $a <=> $b } @{$repo->repos()};
    
    open(R, ">svd_repo.txt") or die $!;
    #my $ut = pdl load_Ut();
    #writefraw($ut, "ut.dat");
    my $ut = readfraw("ut.dat");

    my $c = 0;
    foreach my $uid (@{$user->users()}) {
	print "$c\r"; ++$c;
	my $vec = pdl repo_vector($user->hash_repos($uid), \@repo_ids);
	my $decomp = $ut x $vec;
	my $line = "$uid:";

	for (my $i = 0; $i < K; ++$i) {
	    if ($i != 0) {
		$line .= ",";
	    }
	    $line .= at($decomp, 0, $i);
	}
	print R $line,"\n";
    }
    close(R);
}
