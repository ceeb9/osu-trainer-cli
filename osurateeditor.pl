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

# check if root
if($> != 0) {
    print(color("red"), "You are not running as root! Root permissions are required to read the current map info. Please try again. ", color("reset"));
    exit;
}

# start background memory server on a child process
print("Starting osu memory reader...\n");
my $pid = fork;
if($pid == 0)
{
    system("./gosumemory -cgodisable -path $songdir > /dev/null 2>&1"); #throws away stdout and stderr of the bg memory server
    exit;
}

print("Done! Getting current map info.");

# try to get the current map info from the now-launched memory server
# print dots to show user it isn't hanging, repeat until error code is 0 (success)
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

# do it again so that we ensure we actually get a value after the server has started
sleep(0.2);
$mapinfo = `curl --silent http://localhost:24050/json`;

# decode the json we now have from curl, separate it into values
$mapinfo = decode_json($mapinfo);

# use the folder as the title, as this is what the search function actually uses
# it contains the map id, so there is no possible ambiguity
my $title = $mapinfo->{"menu"}->{"bm"}->{"path"}->{"folder"};
my $diff = $mapinfo->{"menu"}->{"bm"}->{"metadata"}->{"difficulty"};

# delete question mark characters 
# search function doesn't like them
$title =~ tr/?//d;
$diff =~ tr/?//d;

# remove newline chars
chomp($title, $diff);

# get desired bpm change
print("\nNow editing: ", color("cyan"), $title, color("reset"), " [", color("cyan"), $diff, color("reset"), "]\n");
print("Desired BPM?\n>");
my $bpm = <>;
chomp($bpm);

# calculate the modified ar and od values
# todo

# call osu beatmod to perform the actual rate edit
print("\nStarting map editor utility...\n");
system("./osu-beatmod -p \"$songdir\" -b \"$title\" -d \"$diff\" -bpm $bpm");

# kill the memory reader now that it is no longer needed
system("sudo pkill gosumemory");