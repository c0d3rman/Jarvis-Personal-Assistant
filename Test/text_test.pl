use IO::Select;

my $s = IO::Select->new();
$s->add(\*STDOUT);

print "hello\n";
print STDIN "Sleeping";

sleep 1 and print STDIN "." until ($s->can_read(.5));
chomp($in = <STDOUT>);

print "recieved $in!\n";