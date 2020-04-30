//
//  NSData+SHA1.m
//  ReceiptKit
//
//  Created by Jelle De Laender on 09/12/14.
//  Copyright (c) 2014 Bohemian Coding. All rights reserved.
//

#import "NSData+SHA1.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (SHA1)

- (NSData*)sha1 {
  NSMutableData* sha1 = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
  CC_SHA1([self bytes], (unsigned int) [self length], (unsigned char*)[sha1 mutableBytes]);
  return sha1;
}

- (NSString*)sha1AsString {
    NSData *sha1 = [self sha1];
    if (sha1) {
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    unsigned char *digest = (unsigned char*)[sha1 bytes];
        
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
      [output appendFormat:@"%02x", digest[i]];
    
    return output;
  }
  return @"";
}

@end
