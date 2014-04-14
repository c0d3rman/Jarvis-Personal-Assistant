use Audio::Play::MPG123;
use Switch;
use IO::Select;
use File::Find;
use LWP::UserAgent;
use URI::Encode "uri_encode";
use JSON;
use Try::Tiny;

#Web setup
my $ua = LWP::UserAgent->new();

#Input setup
my $s = IO::Select->new();
$s->add(\*STDIN);

=doc
#Voice input setup
print "Recording background... ";
`sox -d /tmp/bg.wav trim 0 2`;
print "done ";
$tmp = `sox /tmp/bg.wav -n stat 2>&1`;
$tmp =~ s/[ \t]//g;
my ($bgnoise) = $tmp =~ /Meanamplitude:(.+)/;
print "($bgnoise dB)\n";
print "Test recording (talk)... ";
my $command = "sox -d -b 24 /tmp/out.wav silence 1 0.3 $bgnoise"."d 1 0.3 $bgnoise"."d";
#`command`;
print "$command\n";
print "done\n\n";
=cut

#Music setup
my $player = new Audio::Play::MPG123;

#Output setup
sub talk ($) {
	$stuff = shift;
	print "Jarvis: $stuff\n";
	$stuff = "\Q$stuff";
=doc
	if ($player->state == 2) {
		$player->pause();
		sleep 1;
		system(qq|say -v Daniel "$stuff" 2> /dev/null|);
		$player->pause();
	} else {
		system(qq|say -v Daniel "$stuff" 2> /dev/null|);
	}
=cut
}

my $refresh = 1;

MAIN: while (1) {
	$player->poll(0);
	sleep($refresh);
	if ($s->can_read(.5)) {
		chomp($in = <STDIN>);
		my $contents;
		if ($in eq '=' || $in eq '-') {
			#my $x = $ua->post('https://api.wit.ai/speech',
			#	Authorization => 'Bearer QZU367LL45MEL3LEXOJK23KSGQ5EV2SL',
			#	Content-Type => 'audio/wav',
			#	Content => [init => ["/tmp/out.wav"]]
			#)->content();
			if ($in eq '=') {
				if ($player->state == 2) {
					$player->pause();
					sleep 1;
					print "You: ";
					`sox -d /tmp/out.wav vad silence 0 1 0.3 20% 2> /dev/null`;
					$player->pause();
				} else {
					print "You: ";
					`sox -d /tmp/out.wav vad silence 0 1 0.3 20% 2> /dev/null`;
				}
				print "...";
				$contents = `curl -XPOST 'https://api.wit.ai/speech' -i -L -H "Authorization: Bearer QZU367LL45MEL3LEXOJK23KSGQ5EV2SL" -H "Content-Type: audio/wav" --data-binary "@/tmp/out.wav" 2> /dev/null`;
				$contents =~ s/^.*?{/{/s;
			
				try {$contents = decode_json $contents} catch {print"\n";talk("I didn't understand that.");next MAIN};
			
				print $contents->{'msg_body'}."\n";
			} else {
				if ($player->state == 2) {
					$player->pause();
					sleep 1;
					print "You: ";
					`sox -d /tmp/out.flac vad silence 0 1 0.3 20% 2> /dev/null`;
					$player->pause();
				} else {
					print "You: ";
					`sox -d /tmp/out.flac vad silence 0 1 0.3 20% 2> /dev/null`;
				}
				print "...";
				$contents = `curl -XPOST --data-binary @/tmp/out.flac --header 'Content-Type: audio/x-flac; rate=44100;' 'https://www.google.com/speech-api/v1/recognize?client=chromium&lang=en-US&maxresults=10' 2> /dev/null`;
				try {
					$contents = decode_json $contents;
					die "No comprendo" if ($contents->{'status'});
				} catch {
					print "\n";
					talk("I didn't understand that.");
					next MAIN;
				};
				print $contents->{'hypotheses'}[0]{'utterance'}."\n";
				$contents = $ua->get(uri_encode("https://api.wit.ai/message?q=".$contents->{'hypotheses'}[0]{'utterance'}), Authorization => 'Bearer QZU367LL45MEL3LEXOJK23KSGQ5EV2SL')->content();
				try {$contents = decode_json $contents} catch {talk("I didn't understand that.");next MAIN};
			}
		} else {
			$contents = $ua->get(uri_encode("https://api.wit.ai/message?q=$in"), Authorization => 'Bearer QZU367LL45MEL3LEXOJK23KSGQ5EV2SL')->content();
			try {$contents = decode_json $contents} catch {talk("I didn't understand that.");next MAIN};
		}
		
		if ($contents->{'outcome'}{'confidence'} < 0.5) {
			talk(qq|I didn't understand "|.$contents->{'msg_body'}.qq|".|);
			talk("I was ".int($contents->{'outcome'}{'confidence'} * 100)."% sure your intent was ".$contents->{'outcome'}{'intent'}.".");
			next MAIN;
		}
		
		switch ($contents->{'outcome'}{'intent'}) {
			case 'greet'    {talk("Hello, sir!")}
			case 'pause'     {$player->state==2 ? ($player->pause() and talk("Pausing song")) : ($player->state==1 ? talk("Already paused!") : talk("No song loaded!"))}
			case 'unpause'   {$player->state==1 ? ($player->pause() and talk("Unpausing song")) : ($player->state==2 ? talk("Already unpaused!") : talk("No song loaded!"))}
			case 'leave'     {talk("Goodbye sir."); exit}
			case 'speak'     {talk($contents->{'outcome'}{'entities'}{'message_body'}{'body'});}
			case 'calculate' {}
			case 'open'  {
				my ($path, $filename, $rootfound) = ("", $contents->{'outcome'}{'entities'}{'message_body'}{'body'}, 0);
				find(sub {$rootfound ? $File::Find::prune = 1 : $rootfound = 1;($path, $filename) = ($File::Find::name, $_) if /^(?!\.).*$filename/i}, "/Applications/");
				
				if ($path) {
					$filename =~ s/\....$//;
					`open '$path'`;
					talk("Opening $filename");
				} else {
					talk("Could not find '$filename'");
				}
			}
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