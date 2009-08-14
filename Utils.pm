package Utils;

sub padding_result
{
    my @result = @_;

    while (scalar(@result) < 10) {
	push(@result, 0);
    }
    return @result[0 .. 9];
}

1;
