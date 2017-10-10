
0bPress <F3> key to go to advanced help07
For boot options, type0d BOOTLABEL07 then a space, then each option. Some options:
0dacpi=off07     Default on for PCs >2001, may give boot/shutdown probs.
0dpfix=ram07     Run totally in RAM ignore saved sessions,
0dpfix=<n>07     number of saved sessions to ignore (multisession-CD),
0dpfix=nox07     commandline only, do not start X (graphical desktop),
0dpfix=xorgwizard07 force xorgwizard-cli for the current session,
0dpfix=copy07    copy .sfs files to RAM (slower boot, faster running),
0dpfix=nocopy07  do not copy .sfs files to RAM (faster boot, slower running),
0dpfix=fsck07    do filesystem check on DISTRO_FILE_PREFIXsave (and host partition)
0dpfix=clean07   file cleanup (simulate version upgrade),
0dplang=<xxxx>07 Locale -- not normally required as asked after bootup.
0dpkeys=<xx>07   Keyboard layout, choices: azerty be-latin1 br-abnt2 br-abnt
    br-latin1-abnt2 br-latin1-us by cf croat cz de de-latin1 dk dvorak dvorak-l
    dvorak-r es et fi fr gr hu101 hu il it jp106 lt mk nl no pl pt-latin1 ro ru
                       se sg sk-qwerty sk-qwertz slovene sv-latin1 uk us wangbe
Examples: 
0dBOOTLABEL acpi=off pkeys=fr07  Ignore ACPI, French keyboard layout.
0dBOOTLABEL pfix=nox,ram07       Run in RAM, do not start X.

0cDESKTOP FAIL: Black-screen/hangs, press reset or hold power-button down 4 secs:
next startup type boot param "puppy pfix=nox" to enable run of Video Wizard07


