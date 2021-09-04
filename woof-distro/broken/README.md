# broken - the broken distribution for testing purposes

Various bad things (including spinning until cancelled by 
the github action system) happen when people specify releases badly.

This is a place to put broken distributions that exercise these faults,
so that the fixes for the faults can be tested inside the github action
system.

1)  broken/broken/broken is a distribution with only an empty DISTRO_SPECS,
to get to a loop where merge2out asked repeatedly for an arch

