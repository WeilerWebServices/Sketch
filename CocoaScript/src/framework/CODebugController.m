//  Created by Mathieu Dutour on 01/05/2019.
//  

#import "CODebugController.h"

@implementation CODebugController
+ (instancetype)sharedController {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (id<CODebugControllerDelegate>)setDelegate:(id<CODebugControllerDelegate>)delegate {
    CODebugController *sharedController = [CODebugController sharedController];
    id oldDelegate = sharedController.delegate;
    sharedController.delegate = delegate;
    return oldDelegate;
}

+ (void)output:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    CODebugController *sharedController = [CODebugController sharedController];
    if (sharedController.delegate == nil) {
        NSLogv(format, args);
    } else {
        [sharedController.delegate output:format args:args];
    }
    va_end(args);
}
@end
