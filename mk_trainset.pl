use strict;
use warnings;
use Repo;
use User;
use Lang;
use Result;
use Utils;
use constant {
    DEL_N => 5000
};
$|=1;

{
    print "$0: loading ..\r";
    my $repo = new Repo("./download/repos.txt");
    my $lang = new Lang("./download/lang.txt", $repo);
    my $user = new User("./download/contest_data.txt", $lang);
    my $test = new Result("./download/contest_test.txt", $lang);
    my $count = $test->count();
    my $i = 0;
    my $users = $user->users();
    my %uids;
    open(D, ">download/train_data.txt") or die $!;
    open(T, ">download/train_test.txt") or die $!;
    
    $repo->set_lang($lang);
    $repo->ranking($user);

    foreach my $uid (@{$test->users()}) {
	delete $user->{$uid};
    }
    for (my $i = 0; $i < DEL_N; ++$i) {
	my $uid = $users->[rand(scalar(@$users))];
	my $repos = $user->repos($uid);
	if (scalar(@$repos) < 5) {
	    redo;
	}
	if (defined($uids{$uid})) {
	    redo;
	}
	$uids{$uid} = 1;
	for (my $j = 0; $j < 3; ++$j) {
	    my $rid = $repos->[rand(scalar(@$repos))];
	    delete $user->{all_id}->{$uid}->{$rid};
	}
	print T $uid,"\n";
    }
    foreach my $uid (@$users) {
	foreach my $rid (@{$user->repos($uid)}) {
	    print D "$uid:$rid\n";
 	}
    }
    close(D);
    close(T);
}
