package Utils;

sub padding_result
{
    my @result = @_;

    while (scalar(@result) < 10) {
	push(@result, 0);
    }
    return @result[0 .. 9];
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
