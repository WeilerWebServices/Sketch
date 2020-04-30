//
//  main.m
//  mocha
//
//  Created by Logan Collins on 5/12/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <getopt.h>

#import <Mocha/MochaRuntime_Private.h>

#import "MOCInterpreter.h"
#import "NSFileHandle+MochaAdditions.h"


static const char * program_name = "mocha";
static const char * program_version = "1.0";


static const char * short_options = "hv";
static struct option long_options[] = {
    { "help", optional_argument, NULL, 'h' },
    { "version", optional_argument, NULL, 'v' },
    { NULL, 0, NULL, 0 }
};


static void printUsage(FILE *stream) {
    fprintf(stream, "%s %s\n", program_name, program_version);
    fprintf(stream, "Usage: %s [-hv] [file]\n", program_name);
    fprintf(stream,
            "  -h, --help                Show this help information.\n"
            "  -v, --version             Show the program's version number.\n"
            );
}


static void printVersion(void) {
    printf("%s %s\n", program_name, program_version);
}


void executeScript(NSString *script, NSString *path);


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSMutableArray *filePaths = [NSMutableArray array];
        
        int next_option;
        do {
            next_option = getopt_long(argc, (char * const *)argv, short_options, long_options, NULL);
            
            switch (next_option) {
                case -1: {
                    break;
                }
                case 'v': {
                    printVersion();
                    exit(0);
                    break;
                }
                case 'h': {
                    printUsage(stdout);
                    exit(0);
                    break;
                }
                case '?': {
                    printUsage(stderr);
                    exit(1);
                    break;
                }
            }
        }
        while (next_option != -1);
        
        if (optind < argc) {
            while (optind < argc) {
                const char * arg = argv[optind++];
                NSString *string = [NSString stringWithUTF8String:arg];
                [filePaths addObject:string];
            }
        }
        
        NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
        
        if ([filePaths count] > 0) {
            // Execute files
            for (NSString *path in filePaths) {
                NSError *err;
                NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
                
                if (!s) {
                    NSLog(@"Could not read the file at %@", path);
                    NSLog(@"%@", err);
                    exit(1);
                }
                
                executeScript(s, path);
            }
        }
        else if ([stdinHandle mo_isReadable]) {
            // Execute contents of stdin
            NSData *stdinData = [stdinHandle readDataToEndOfFile];
            NSString *string = [[NSString alloc] initWithData:stdinData encoding:NSUTF8StringEncoding];
            executeScript(string, nil);
        }
        else {
            // Interactive mode
            MOCInterpreter *interpreter = [[MOCInterpreter alloc] init];
            [interpreter run];
        }
    }
    return 0;
}


void executeScript(NSString *script, NSString *path) {
    Mocha *runtime = [[Mocha alloc] init];
    
    if ([script length] >= 2 && [[script substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"#!"]) {
        // Ignore bash shebangs
        NSRange lineRange = [script lineRangeForRange:NSMakeRange(0, 2)];
        script = [script substringFromIndex:NSMaxRange(lineRange)];
    }
    
    @try {
        [runtime evalJSString:script scriptPath:path];
    }
    @catch (NSException *e) {
        if ([e userInfo] != nil) {
            printf("%s: %s\n%s\n", [[e name] UTF8String], [[e reason] UTF8String], [[[e userInfo] description] UTF8String]);
        }
        else {
            printf("%s: %s\n", [[e name] UTF8String], [[e reason] UTF8String]);
        }
    }
}

