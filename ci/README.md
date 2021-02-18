This is a series of basic, automated tests that boot a PUPMODE 6 x86_64 image inside an emulator.

Various scenarios are simulated through injection of input events. Then, the screen contents are polled for changes and compared to a "known good" screenshot.

Regions on the screen that change between executions of the test suite, like the clock, are masked prior to this comparison.