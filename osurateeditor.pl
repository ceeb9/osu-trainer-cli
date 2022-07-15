#!/bin/perl
use strict;
use warnings;
use Term::ANSIColor;
use JSON;
use utf8;
use Try::Tiny;

#put your songs dir here-------------------------------
my $songdir = "/home/ceeb/games/osu-folder/Songs";
#------------------------------------------------------

print("----------", color("cyan"), "osu rate editor", color("reset"), "----------\n");

#check if root
if($> != 0) {
    print(color("red"), "You are not running as root! Root permissions are required to read the current map info. Please try again. ", color("reset"));
    exit;
}

#start background memory server on a child process
print("Starting osu memory reader...\n");
my $pid = fork;
if($pid == 0)
{
    system(`./gosumemory -cgodisable -path $songdir &> /dev/null`);
    exit;
}
print("Done! Getting current map info.");

#try to get the current map info from the now-launched memory server
#print dots to show user it isn't hanging, repeat until error code is 0 (success)
my $mapinfo = "";
my $attempts = 0;
do {
    try {
        $attempts++;
        if($attempts % 40 == 0) {
            print(".");
        }
        $mapinfo = `curl --silent http://localhost:24050/json`;
    }
} until($? == 0);

#decode the json we now have from curl, separate it into values
$mapinfo = decode_json($mapinfo);
my $title = $mapinfo->{"menu"}->{"bm"}->{"metadata"}->{"title"};
my $diff = $mapinfo->{"menu"}->{"bm"}->{"metadata"}->{"difficulty"};


# remove the quotes and newline chars from the returned info
$title =~ tr/"//d;
$diff =~ tr/"//d;
chomp($title, $diff);

#get desired bpm change
print("\nNow editing: ", color("cyan"), $title, color("reset"), " [", color("cyan"), $diff, color("reset"), "]\n");
print("Desired BPM?\n>");
my $bpm = <>;
chomp($bpm);

#calculate the modified ar and od values
#todo

##call osu beatmod to perform the actual rate edit
print("\nStarting map editor utility...\n");
exec("./osu-beatmod -p \"$songdir\" -b \"$title\" -d \"$diff\" -bpm $bpm");