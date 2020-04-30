//  Created by Pieter Omvlee on 09-09-09.
//  Copyright 2009 Bohemian Coding. All rights reserved.

#import <Cocoa/Cocoa.h>

@interface BCPopoverWindow : NSWindow
+ (id)attachedWindowWithView:(NSView *)aView;
@property (nonatomic) NSRectEdge arrowEdge;
@property (nonatomic) CGFloat arrowPosition;
@end
