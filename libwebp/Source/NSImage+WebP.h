//
//  Created by Gavin on 05/09/2016.
//  Copyright © 2016 Bohemian Coding. All rights reserved.
//

extern NSString * _Nonnull const NSImageUTTypeWebP;

@interface NSImage (WebP)

/**
 Returns a new NSImage if the contents of \c data can be interpreted as webp or nil otherwise
 */
+ (nullable NSImage*)imageWithWebPData:(nonnull NSData*)data;

/**
 Returns a new NSImage if the contents of the file at \c url can be interpreted as webp
 or nil otherwise
 */
+ (nullable NSImage*)imageWithWebPURL:(nonnull NSURL*)url;

@end
