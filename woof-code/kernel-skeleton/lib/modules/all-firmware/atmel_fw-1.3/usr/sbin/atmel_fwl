#!/usr/bin/perl

#     Firmware loader for Atmel at76c502 at76c504 and at76c506 wireless cards.
#
#            Copyright 2004 Simon Kelley.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This software is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Atmel wireless lan drivers; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use Socket;
use File::Basename;

use constant ATMELFWL => 0x8be0;
use constant ATMELIDIFC => 0x8be1;
use constant ATMELMAGIC => 0x51807;

(($iface = shift(@ARGV)) && ($file = shift(@ARGV))) ||
    die "Usage: atmel_fwl <interface> <path/to/firmware>";

socket (Socket, PF_INET, SOCK_DGRAM, getprotobyname('udp')) 
    || die "Cannot create socket: $!";

$ifr = pack("Z16 L", $iface, 0x0);
(ioctl(Socket, ATMELIDIFC, $ifr) && 
 (unpack("Z16 L", $ifr))[1] == ATMELMAGIC) || 
    die "$iface is not an Atmel interface";

local ($/);
use bytes;

open (File, "<:raw", $file) || die "Cannot open $file: $!";
$image = <File>;
$len = length $image;
close(File);

$priv = pack("Z32 P S", basename($file), $image, $len);
$ifr = pack("Z16 P", $iface, $priv);

ioctl(Socket, ATMELFWL, $ifr) ||
    die "Firmware load failed: $!";




