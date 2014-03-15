use Audio::Play::MPG123;
use threads;
use threads::shared;
use Switch;
use IO::Select;
use Time::HiRes qw(time);
use File::Find;
use Term::ANSIScreen qw(:screen :cursor);

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
#cls;
#locate 1, 1;
sub talk ($) {
	$stuff = shift;
	$stuff =~ s/'/\\'/;
	print "Jarvis: $stuff\n";
	#$stuff =~ s/'/\\'/;
	if ($player->state == 2) {
		$player->pause();
		sleep 1;
		system("say -v Daniel '$stuff' 2> /dev/null");
		$player->pause();
	} else {
		system("say -v Daniel '$stuff' 2> /dev/null");
	}
	#cls;
	#locate 1, 1;
}

my $refresh = 1;

while (1) {
	$player->poll(0);
	sleep($refresh);
	if ($s->can_read(.5)) {
		chomp($in = <STDIN>);
		switch (lc $in) {
			case [qw(hi hello)]  {talk("Hello, sir!");}
			case [qw(p pause)]   {$player->state==2 ? ($player->pause() and talk("Pausing song")) : ($player->state==1 ? talk("Already paused!") : talk("No song loaded!"))}
			case [qw(u unpause)] {$player->state==1 ? ($player->pause() and talk("Unpausing song")) : ($player->state==2 ? talk("Already unpaused!") : talk("No song loaded!"))}
			case [qw(t toggle)]  {$player->state==2 ? talk("Pausing song") : talk ("Unpausing song"); $player->pause()}
			case [qw(s stop)]    {$player->state!=0 ? $player->stop() : talk("No song loaded!")}
			case [qw(x exit)]    {exit}
			case m/^say /i  {
				$in =~ /^say (.+)/i;
				talk($1);
			}
			case m/^open |^o /i  {
				$in =~ /^open (.+)/i || $in =~ /^o (.+)/i;
				my ($path, $filename, $rootfound) = ("", $1, 0);
				find(sub {$rootfound ? $File::Find::prune = 1 : $rootfound = 1;($path, $filename) = ($File::Find::name, $_) if /$filename/i}, "/Applications/");
				$filename =~ s/\....$//;
				if ($path) {
					`open '$path'`;
					talk("Opening $filename");
				} else {
					talk("Could not find '$filename'");
				}
			}
			case m/^play |^l /i  {
				$in =~ /^play (.+)/i || $in =~ /^l (.+)/i;
				my ($path, $filename) = ("", $1);
				$player->stop() if ($player->state!=0);
				find(sub {($path, $filename) = ($File::Find::name, $_) if /$filename/i}, "Audio/");
				$filename =~ s/\....$//;
				if ($player->load($path)) {
					talk("playing $filename");
				} else {
					talk("could not find $filename");
				}
			}
			case m/^(?:jump|skip) to  |^j /i  {
				$in =~ /^(?:jump|skip) to (.+)/i || $in =~ /^j (.+)/i;
				if ($player->state!=0) {
					talk("Jumping to $1");
					$player->jump($1/$tpf);
				} else {
					talk("No song loaded!");
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