use strict;
use warnings;
use Utils;
use Result;

$ARGV[0] or die "usage: $0 file";

my $result = new Result($ARGV[0]);

open(R, ">results.txt") or die $!;
foreach my $uid (sort {$a <=> $b } @{$result->users()}) {
    my $repos = $result->repos($uid);
    print R Result::format($uid, Utils::padding_result(@$repos));
}
close(R);

