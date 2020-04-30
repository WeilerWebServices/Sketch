ECLogging provides a flexible logging system for iOS and MacOS X software to use.

This is a meme that I've implemented repeatedly in a number of projects over the last 15 or so years, stretching right back to my first big C++ library. I also did an open source C++ implementation in about 2000 I think, although I can't for the life of me work out where it is now!

Essentially, it's a smarter replacement for "printf" or "NSLog" style debug output.

The problem with simply using something like NSLog is that you either end up with reams of debug output, in which case you can't see the wood for the trees, or you end up with messy source code where you're endlessly commenting logging statements in/out. This is especially bad if you work on a big project and/or with lots of developers.

What all my various implementations of a logging system share is the ability to define named channels, and log handlers. These named channels can be organised functionally, rather than by "level". You don't just have to have "warning", "error", or "really bad error". You can have a channel like "stuff related to application notifications", or even "stuff relating to fixing bug #321".

You can direct logging output to a particular channel. All channels are off by default, so you can add detailed logging support to any file or module without spamming the log. If I make a channel, you won't see it in your log unless you choose to turn it on. When you need to, you can turn a particular channel or group of channels on. For release versions, you can compile away all logging completely, for top performance. Or you can choose to leave some log channels in the release build.

The output of log channels is directed through one or more log handlers. What log handlers give you is the ability to globally direct log output into alternative destinations. The console is one option, but you can also write a handler to log to the disk, or a remote machine, or a custom ui, or wherever.

## Logging Documentation

If you don't like reading documentation, jump into the [30 Second User Guide](<30-second-user-guide>), which should get you started quickly. 

Or look at the [Sample Projects](https://github.com/elegantchaos/ECLoggingExamples).

If you do read documentation:

- [Initialising ECLogging](<Initialisation>)
- [Log Channels](<ECLogChannel>)
- [Log Handlers](<ECLogHandler>)
- [User Interface Support](<UserInterface>)
- [Configuring ECLogging](<Configuration>)
- [Miscellaneous Features](<Miscellaneous>)
- [Using ECLogging In Your Project](<Installation>)

## Other Documentation

As well as the logging functionality, ECLogging also contains some common files used by all the other Elegant Chaos libraries.

These were formerly part of the ECConfig and ECUnitTests frameworks, but for the sake of simplicity they're now rolled in to this framework.

For more information, see the associated documentation pages:

- Unit Testing Utilities: <ECTestCase>, <ECParameterisedTestCase>
- [Standard xcconfig Files](<StandardConfigFiles>)
- [Standard Macros and Definitions](<StandardMacros>)
- [Standard pch Files](<StandardPrefixFiles>)
- [Standard scripts](<Scripts>)


## Standard Project Layout

Some of the scripts, config files and prefixes work on the assumption that client projects have a standard organisation.

Generally this shouldn't be an issue, and if you don't encounter any problems, don't worry about it.

If you're trying to make use of the standard scripts or config files and are having issues, this may be relevant.

The [Finding The Standard Config Files](<ImportNote>) note has more information about why this can be a problem, particularly when you are using ECLogging in your project along with another EC framework.

Arranging your own project to use our standard organisation isn't essential, but if you use a different one you may have to modify some examples accordingly.

If you encounter problems with this, or have suggestions for improvements, please file an issue.

## Future

There's lot of stuff that I plan to add to ECLogging, but it generally gets done on an ad-hoc basis as and when I need it.

Take a look at the [Issues Page](http://github.com/elegantchaos/ECLogging/issues) to see what's planned, and what's not working.
