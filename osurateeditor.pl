#!/bin/perl
use strict;
use warnings;
use Term::ANSIColor;
use JSON;
use utf8;
use Try::Tiny;
use POSIX qw/floor/;

#put your songs directory here-------------------------------
my $songdir = "/home/ceeb/.local/share/osu-wine/osu!/Songs";
#------------------------------------------------------------

# check if root
if ( $> != 0 ) {
    print(color("red"), "You are not running as root! Root permissions are required to read the current map info. Please try again. ", color("reset"));
    exit;
}

print("----------", color("cyan"), "osu rate editor", color("reset"), "----------\n");

# start background memory server on a child process
print("Starting osu memory reader...\n");
my $pid = fork;
if ( $pid == 0 ) {
    system("sudo ./gosumemory -path $songdir > /dev/null 2>&1");
    exit;
}
print("Done! Getting current map info.");

# try to get the current map info from the now-launched memory server
my $mapinfo  = "";
my $attempts = 0;
do {
    try {
        $attempts++;
        if ( $attempts % 75 == 0 ) {
            print(".");
        }
        $mapinfo = `curl --silent http://localhost:24050/json`;
    }
} until (length($mapinfo) > 0 && decode_json($mapinfo)->{"menu"}->{"bm"}->{"stats"}->{"BPM"}->{"max"} != 0); 
                                #^^^^^^^^^^^ ensures that stats have been populated before starting to use values
$mapinfo = decode_json($mapinfo);

# use the name of the folder instead of the title of the map, since it contains the map id
my $title = $mapinfo->{"menu"}->{"bm"}->{"path"}->{"folder"};
my $diff  = $mapinfo->{"menu"}->{"bm"}->{"metadata"}->{"difficulty"};
my $maxbpm = $mapinfo->{"menu"}->{"bm"}->{"stats"}->{"BPM"}->{"max"};
my $ar = $mapinfo->{"menu"}->{"bm"}->{"stats"}->{"AR"};

# haven't implemented od scaling or user defined changing of stats yet
#my $cs = $mapinfo->{"menu"}->{"bm"}->{"stats"}->{"CS"};
#my $od = $mapinfo->{"menu"}->{"bm"}->{"stats"}->{"OD"};
#my $hp = $mapinfo->{"menu"}->{"bm"}->{"stats"}->{"HP"};

# sanitize title and diff names
$title =~ tr/?//d;
$diff  =~ tr/?//d;
chomp( $title, $diff );

# get the new bpm
print("\nNow editing: ", color("cyan"), $title=~s/^[0-9]*[\s]//r, color("reset"), " [", color("cyan"), $diff, color("reset"), "]\n"); 
                                                #^^^^^^^^^^^^^^^ this prints the title without the beatmap id but without changing the title variable
print("Note that speed scaling is based on the maximum BPM of a song.\n
       A 150-170BPM song will not change speed if you enter 170.
     \nDesired BPM?\n> ");
my $valid = 0;
my $bpm = "";
while($valid == 0) {
    $bpm = <>;
    chomp($bpm);
    if($bpm !~ /^[0-9]+(?:\.*[0-9]+)*$/) { # regex to check for a valid positive real number
        print("Please enter a valid BPM.\n> ")
    } 
    else {
        $valid = 1;
    }
}

# scale or don't scale approach rate
print("Scale approach rate? (y/n)\n> ");
$valid = 0;
while($valid == 0) {
    my $choice = <>;
    chomp($choice);
    
    if($choice eq "y") {
        my $rate = $bpm/$maxbpm; # keep in mind that the rate is based on the change from the max bpm
        $ar = floor((((2/9)*$rate*(13-$ar))+$ar)*10)/10; # magic scaling factor for approach rate
        print( "New AR is ", $ar, ". ");
        $valid = 1;
    }
    elsif($choice eq "n"){$valid = 1;}
    else {
        print("Please enter a valid choice. (y/n)\n> ");
    }
}

# call osu beatmod to perform the actual rate edit
print("\nStarting map editor utility...\n");
system("./osu-beatmod -p \"$songdir\" -b \"$title\" -d \"$diff\" -bpm $bpm -ar $ar");
system("sudo pkill gosumemory");