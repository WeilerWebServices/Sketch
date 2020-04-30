//
//  COSInterval.m
//  Cocoa Script
//
//  Created by August Mueller on 11/21/13.
//
//

#import "COSInterval.h"
#import "COSFiber.h"

@implementation COSInterval

+ (id)scheduleWithInterval:(NSTimeInterval)i cocoaScript:(COScript*)cos jsFunction:(MOJavaScriptObject *)jsFunction repeat:(BOOL)repeat {
    
    COSInterval *interval = [COSInterval createWithCocoaScript: cos];
    
    interval->_jsfunc = jsFunction;
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:i target:interval selector:@selector(timerHit:) userInfo:nil repeats:repeat];
    
    interval->_onshot = !repeat;
    
    interval->_timer = t;
    
    return interval;
    
}

- (void)cleanup {
    [self cancel];
}

- (void)cancel {
    [_timer invalidate];
    _timer = nil;
    
    _jsfunc = nil;
    
    [super cleanup];
}

- (void)timerHit:(NSTimer*)timer {
    
    [self.coscript callJSFunction:[_jsfunc JSObject] withArgumentsInArray:@[self]];
    
    if (_onshot) {
        [self cancel];
    }
    
}

@end
