use Audio::Play::MPG123;

$player = new Audio::Play::MPG123;

$player->load("Audio/Dead Giveaway.mp3");

print "Title: ",$player->title,"\n";
print "Artist: ",$player->artist,"\n";
print "Album: ",$player->album,"\n";
print "Year: ",$player->year,"\n";
print "Comment: ",$player->comment,"\n";
print "Genre: ",$player->genre,"\n";

$player->poll(1) until $player->state == 0;

#$player->load("http://x.y.z/kult.mp3");