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

sub intersections
{
    

}

1;
