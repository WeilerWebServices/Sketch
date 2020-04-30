//
//  SHA1Tests.m
//  BCCrypto
//
//  Created by Johnnie Walker on 12/01/2015.
//  Copyright (c) 2015 Bohemian Coding. All rights reserved.
//

@import Cocoa;

#import <BCCrypto/BCCrypto.h>
#import <ECUnitTests/ECUnitTests.h>

@interface SHA1Tests : ECTestCase

@end

@implementation SHA1Tests

- (void)testSHA1 {
    // FIPS PUB 180-2, A.1 - "One-Block Message"
    ECTestAssertIsEqual(@"a9993e364706816aba3e25717850c26c9cd0d89d", [@"abc" sha1]);

    // FIPS PUB 180-2, A.2 - "Multi-Block Message"
    ECTestAssertIsEqual(@"84983e441c3bd26ebaae4aa1f95129e5e54670f1", [@"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" sha1]);
    
    // RFC 3174: Section 7.3, "TEST4" (multiple of 512 bits)
    NSMutableString *input = [NSMutableString new];
    for (NSUInteger i=0; i<80; i++) {
        [input appendString:@"01234567"];
    }
    ECTestAssertIsEqual(@"dea356a2cddd90c7a7ecedc5ebb563934f460452", [input sha1]);
}

@end
