//
//  NSData+SHA1.h
//  ReceiptKit
//
//  Created by Jelle De Laender on 09/12/14.
//  Copyright (c) 2014 Bohemian Coding. All rights reserved.
//

@import Foundation;

@interface NSData (SHA1)
- (NSData*)sha1;
- (NSString*)sha1AsString;
@end
