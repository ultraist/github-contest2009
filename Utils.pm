package Utils;
use strict;
use warnings;

sub C
{
    my ($n, $r) = @_;
    return fact($n)/(fact($r) * fact($n - $r));
}

sub fact
{
    my $n = shift;
    my $f = 1;
    for (my $i = 1; $i <= $n; ++$i) {
	$f *= $i;
    }
    return $f;
}

sub remove_list
{
    my ($a, $remove_list) = @_;
    my @ret;
    my %h;

    foreach my $r (@$remove_list) {
	$h{$r} = 1;
    }
    
    for my $v (@$a) {
	if (!defined($h{$v})) {
	    push(@ret, $v);
	}
    }
    return @ret;
}


sub uniq
{
    my @a = @_;
    my @unique;
    my %h = ();
    
    for my $v (@a) {
	if (!defined($h{$v})) {
	    push(@unique, $v);
	    $h{$v} = 1;
	}
    }
    return @unique;
}

sub padding_result
{
    my @result = @_;

    while (scalar(@result) < 20) {
	push(@result, 0);
    }
    return @result[0 .. 19];
}

sub includes
{
    my ($array, $value) = @_;
    
    foreach my $v (@$array) {
	if ($v == $value) {
	    return 1;
	}
    }
    return undef;
}

sub intersection_count
{
    my ($a1, $a2) = @_;
    my $ok = 0;
    
    foreach my $v1 (@$a1) {
	foreach my $v2 (@$a2) {
	    if ($v1 == $v2) {
		++$ok;
	    }
	}
    }
    return $ok;
}

1;
