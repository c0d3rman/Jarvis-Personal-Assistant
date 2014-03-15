use Audio::Play::MPG123;
use Switch;
use IO::Select;
use File::Find;
use LWP::UserAgent;
use URI::Encode "uri_encode";
use JSON;

#Web setup
my $ua = LWP::UserAgent->new();

#Input setup
my $s = IO::Select->new();
$s->add(\*STDIN);

#Music setup
my $player = new Audio::Play::MPG123;
#$player->load("Audio/Aint Nobody Got Time For That.mp3");

#Output setup
sub talk ($) {
	$stuff = shift;
	print "Jarvis: $stuff\n";
	$stuff = "\Q$stuff";
	if ($player->state == 2) {
		$player->pause();
		sleep 1;
		system(qq|say -v Daniel "$stuff" 2> /dev/null|);
		$player->pause();
	} else {
		system(qq|say -v Daniel "$stuff" 2> /dev/null|);
	}
}

my $refresh = 1;

while (1) {
	$player->poll(0);
	sleep($refresh);
	if ($s->can_read(.5)) {
		chomp($in = <STDIN>);
		my $contents = $ua->get(uri_encode("https://api.wit.ai/message?q=$in"), Authorization => 'Bearer QZU367LL45MEL3LEXOJK23KSGQ5EV2SL')->content();
		$contents = decode_json $contents;
		#print Dumper($contents);
		#print "Intent: ".$contents->{'outcome'}{'intent'}."\n";
		if ($contents->{'outcome'}{'confidence'} < 0.5) {
			talk("I didn't understand that.");
			talk("I was ".int($contents->{'outcome'}{'confidence'} * 100)."% sure your intent was ".$contents->{'outcome'}{'intent'}.".");
			next;
		}
		
		switch ($contents->{'outcome'}{'intent'}) {
			case 'greet'   {talk("Hello, sir!");}
			case 'pause'   {$player->state==2 ? ($player->pause() and talk("Pausing song")) : ($player->state==1 ? talk("Already paused!") : talk("No song loaded!"))}
			case 'unpause' {$player->state==1 ? ($player->pause() and talk("Unpausing song")) : ($player->state==2 ? talk("Already unpaused!") : talk("No song loaded!"))}
			case 'leave'   {exit}
			case 'speak'   {
				talk($contents->{'outcome'}{'entities'}{'message_body'}{'body'});
			}
=doc
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
=cut
			case 'play'  {
				my ($path, $filename) = ("", $contents->{'outcome'}{'entities'}{'song_name'}{'body'});
				$player->stop() if ($player->state!=0);
				find(sub {($path, $filename) = ($File::Find::name, $_) if /$filename/i}, "Audio/");
				$filename =~ s/\....$//;
				if ($player->load($path)) {
					talk("playing $filename");
				} else {
					talk("could not find $filename");
				}
			}
		}
	}
}