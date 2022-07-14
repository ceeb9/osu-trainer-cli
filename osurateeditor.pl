#!/bin/perl
use strict;
use warnings;
use Term::ANSIColor;
use JSON;
use utf8;

#put your songs dir here
my $songdir = "/home/ceeb/games/osu-folder/Songs";

print("----------", color("cyan"), "osu rate editor", color("reset"), "----------\n");

#check if root
if($> != 0) {
    print(color("red"), "You are not running as root! Root permissions are required to read the current map info. Please try again. ", color("reset"));
    exit;
}

print("Starting osu memory reader...\n");
system("./gosumemory -cgodisable &> /dev/null");


#get current map info from the now started memory reader
print("Done! Getting current map info...\n\n");
my $mapinfo = decode_json(`curl --silent http://localhost:24050/json`);
my $title = $mapinfo->{"menu"}->{"bm"}->{"metadata"}->{"title"};
my $diff = $mapinfo->{"menu"}->{"bm"}->{"metadata"}->{"difficulty"};
#my @stats = `curl --silent http://localhost:24050/json | jq .menu.bm.metadata.difficulty`;
chomp($title, $diff);

# remove the quotes from the returned info
$title =~ tr/"//d;
$diff =~ tr/"//d;

#get desired change
print("Now editing: ", color("cyan"), $title, color("reset"), " [", color("cyan"), $diff, color("reset"), "]\n");
print("Desired BPM?\n>");
my $bpm = <>;
chomp($bpm);

#calculate the modified ar and od values
#todo

##call osu beatmod to perform the actual rate edit
print("\nStarting map editor utility...\n");
exec("./osu-beatmod -p \"$songdir\" -b \"$title\" -d \"$diff\" -bpm $bpm");

