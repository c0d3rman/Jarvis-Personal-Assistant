use Audio::Play::MPG123;
use threads;
use threads::shared;
use Switch;
use IO::Select;
use Time::HiRes qw(time);
use File::Find;

#Input setup
my $s = IO::Select->new();
$s->add(\*STDIN);

#Music setup
my $player = new Audio::Play::MPG123;
$player->load("Audio/Aint Nobody Got Time For That.mp3");
#establish tpf
my $t = time;
$player->poll(100);
my $tpf = (time - $t)/100;
$player->stop();

#Output setup
sub talk ($) {
	print "Jarvis: $_[0]\n";
	if ($player->state == 2) {
		$player->pause();
		sleep 1;
		system("say -v Daniel '$_[0]' 2> /dev/null");
		$player->pause();
	} else {
		system("say -v Daniel '$_[0]' 2> /dev/null");
	}
}

my $refresh = 1;

while (1) {
	sleep($refresh);
	if ($s->can_read(.5)) {
		chomp($in = <STDIN>);
		switch ($in) {
			case [qw(hi hello)]  {talk("Hello, sir!");}
			case [qw(p pause)]   {$player->state==2 ? $player->pause() : ($player->state==1 ? talk("Already paused!") : talk("No song loaded!"))}
			case [qw(u unpause)] {$player->state==1 ? $player->pause() : ($player->state==2 ? talk("Already unpaused!") : talk("No song loaded!"))}
			case [qw(t toggle)]  {$player->pause()}
			case [qw(s stop)]    {$player->state!=0 ? $player->stop() : talk("No song loaded!")}
			case [qw(x exit)]    {exit}
			case m/^play |^l /i  {
				$in =~ /^play (.+)/i || $in =~ /^l (.+)/i;
				my ($path, $filename) = ("", $1);
				$player->stop() if ($player->state!=0);
				find(sub {($path, $filename) = ($File::Find::name, $_) if /$filename/i}, "Audio/");
				$filename =~ s/\....$//;
				if ($player->load($path)) {
					$player->pause();
					talk("playing $filename");
					$player->pause();
				} else {
					talk("could not find $filename");
				}
			}
		}
	}
}

#$player->poll(1) until $player->state == 0;


__END__
my @commands :shared;


while (<STDIN>) {
	switch ($_) {
		case "pause" {
			if ($player->paused
		}
	}
}

=doc
#Music player
threads->create(
	sub {
		
	}
)->join();
=cut
$player = new Audio::Play::MPG123;

$player->load("Audio/Dead Giveaway.mp3");
=doc
print "Title: ",$player->title,"\n";
print "Artist: ",$player->artist,"\n";
print "Album: ",$player->album,"\n";
print "Year: ",$player->year,"\n";
print "Comment: ",$player->comment,"\n";
print "Genre: ",$player->genre,"\n";
=cut

$player->poll(1) until $player->state == 0;

#$player->load("http://x.y.z/kult.mp3");