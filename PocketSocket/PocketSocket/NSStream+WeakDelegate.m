//  Created by Robin Speijer on 14/11/2019.
//  Copyright © 2019 Bohemian Coding. All rights reserved.

#import "NSStream+WeakDelegate.h"
#import <objc/runtime.h>

static const void * PSStreamDelegateKey = &PSStreamDelegateKey;

/// A proxy object to assign to NSStream's delegate. It needs to be retained
/// by the stream itself, so we have a safe instance to keep a weak delegate ref.
@interface PSStreamDelegate : NSObject <NSStreamDelegate>
@property (weak) id<NSStreamDelegate> weakDelegate;
@end

@implementation PSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
  __strong id<NSStreamDelegate> delegate = self.weakDelegate;
  if ([delegate respondsToSelector:@selector(stream:handleEvent:)]) {
    [delegate stream:aStream handleEvent:eventCode];
  }
}
@end

@implementation NSStream (WeakDelegate)

- (void)setWeakDelegate:(id<NSStreamDelegate>)weakDelegate {
  if (weakDelegate) {
    PSStreamDelegate *retainedDelegate = [[PSStreamDelegate alloc] init];
    retainedDelegate.weakDelegate = weakDelegate;
    objc_setAssociatedObject(self, PSStreamDelegateKey, retainedDelegate, OBJC_ASSOCIATION_RETAIN);
    self.delegate = retainedDelegate;
  } else {
    objc_setAssociatedObject(self, PSStreamDelegateKey, nil, OBJC_ASSOCIATION_RETAIN);
    self.delegate = nil;
  }
}

@end




