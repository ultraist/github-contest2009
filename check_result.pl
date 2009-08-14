use strict;
use warnings;
use Result;

$ARGV[0] or die "usage: $0 result.txt\n";

my $result = new Result($ARGV[0]);
my $all = 0;
my $nonzero = 0;

foreach my $uid (@{$result->users()}) {
    my $repos = $result->repos($uid);
    if (scalar(@$repos) != 10) {
	die "error: uid($uid): invalid repos\n";
    }
    foreach my $v (@$repos) {
	if ($v != 0) {
	    ++$nonzero;
	}
	++$all;
    }
}
print "check ok\n";
printf("%f ($nonzero/$all)\n", $nonzero / $all);
