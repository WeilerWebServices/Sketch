//  Created by Robin Speijer on 14/11/2019.
//  Copyright © 2019 Bohemian Coding. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSStream (WeakDelegate)

/// Assign a weak delegate to the receiving stream.
///
/// The implementation of this method is a workaround for some multithreading
/// issues in PSWebSocket. It's hard to replicate those issues, hence this
/// safety net for now.
///
/// This method will create a proxy object and assign it as delegate. The proxy
/// object weakly links the given weak delegate. So whenever the weak delegate
/// gets deallocated, the stream can still safely call the proxy object, without
/// crashing.
///
/// @param weakDelegate This stream's delegate, to be weakly referenced.
- (void)setWeakDelegate:(nullable id<NSStreamDelegate>)weakDelegate;

@end

NS_ASSUME_NONNULL_END
