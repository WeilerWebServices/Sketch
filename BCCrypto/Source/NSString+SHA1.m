//
//  NSString+SHA1.m
//  ReceiptKit
//
//  Created by Jelle De Laender on 09/12/14.
//  Copyright (c) 2014 Bohemian Coding. All rights reserved.
//

#import "NSString+SHA1.h"
#import "NSData+SHA1.h"

@implementation NSString (SHA1)
-(NSString*)sha1 {
  return [[self dataUsingEncoding: NSUTF8StringEncoding] sha1AsString];
}
@end
