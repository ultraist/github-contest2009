use strict;
use warnings;
use Utils;
use Result;

$ARGV[0] or die "usage: $0 file";

my $result = new Result($ARGV[0]);
my $n = $ARGV[1];

open(R, ">results.txt") or die $!;
foreach my $uid (sort {$a <=> $b } @{$result->users()}) {
    my $repos = $result->repos($uid);
    if (!defined($n)) {
	print R Result::format($uid, Utils::padding_result(@$repos));
    } else {
	print R $uid, ":", join(",", split(//, 0 x ($n)));
	if ($n != 0) {
	    print R ",";
	}
	print R $repos->[$n];
	print R join(",", split(//, 0 x (10-$n))),"\n";
    }
}
close(R);

