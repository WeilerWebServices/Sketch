//  Created by Pieter Omvlee on 19/09/2011.
//  Copyright (c) 2014 Bohemian Coding. All rights reserved.

#import "GKRect.h"

@implementation GKRect
@dynamic midX, midY, maxX, maxY, origin, size;

+ (instancetype)rectWithRect:(NSRect)aRect {
  return [[self alloc] initWithRect:aRect];
}

- (id)initWithRect:(NSRect)aRect {
  self = [super init];
  if (self)
    _rect = aRect;
  return self;
}

@dynamic x, y, width, height;

- (CGFloat)x { return self.rect.origin.x; }
- (CGFloat)y { return self.rect.origin.y; }
- (CGFloat)width  { return self.rect.size.width; }
- (CGFloat)height { return self.rect.size.height; }

- (void)setX:(CGFloat)x { _rect.origin.x = x; }
- (void)setY:(CGFloat)y { _rect.origin.y = y; }
- (void)setWidth:(CGFloat)width   { _rect.size.width = width; }
- (void)setHeight:(CGFloat)height { _rect.size.height = height; }

- (CGFloat)minX { return NSMinX(self.rect); }
- (CGFloat)midX { return NSMidX(self.rect); }
- (CGFloat)maxX { return NSMaxX(self.rect); }

- (CGFloat)minY { return NSMinY(self.rect); }
- (CGFloat)midY { return NSMidY(self.rect); }
- (CGFloat)maxY { return NSMaxY(self.rect); }

- (void)setMinX:(CGFloat)minX { self.x = minX; }
- (void)setMidX:(CGFloat)midX { self.x = midX - self.width/2; }
- (void)setMaxX:(CGFloat)maxX { self.x = maxX - self.width; }

- (void)setMinY:(CGFloat)minY { self.y = minY; }
- (void)setMidY:(CGFloat)midY { self.y = midY - self.height/2; }
- (void)setMaxY:(CGFloat)maxY { self.y = maxY - self.height; }

- (void)setMid:(NSPoint)mid {
  self.midX = mid.x;
  self.midY = mid.y;
}

- (NSPoint)mid {
  return NSMakePoint(self.midX, self.midY);
}

- (id)copyWithZone:(NSZone *)zone {
  return [[self class] rectWithRect:self.rect];
}

- (BOOL)isEqual:(GKRect *)object {
  if ([self class] == [object class])
    return NSEqualRects(self.rect, object.rect);
  else
    return NO;
}

- (NSString *)description {
  return NSStringFromRect(self.rect);
}

- (NSPoint)origin {
  return NSMakePoint(self.x, self.y);
}

- (void)setOrigin:(NSPoint)origin {
  self.x = origin.x;
  self.y = origin.y;
}

- (NSSize)size {
  return NSMakeSize(self.width, self.height);
}

- (void)setSize:(NSSize)size {
  self.width = size.width;
  self.height = size.height;
}

@end
