//
//  MOBridgeSupportController.h
//  Mocha
//
//  Created by Logan Collins on 5/11/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MOBridgeSupportSymbol;


@interface MOBridgeSupportController : NSObject

+ (MOBridgeSupportController *)sharedController;

/// Used by tests to reset the bridge support controller
/// Shouldn't be used in the real world
- (void)reset;

- (BOOL)isBridgeSupportLoadedForURL:(NSURL *)aURL;
- (BOOL)loadBridgeSupportAtURL:(NSURL *)aURL error:(NSError **)outError;

@property (copy, readonly) NSDictionary *symbols;
- (NSDictionary *)performQueryForSymbolsOfType:(NSArray *)classes;

- (id)performQueryForSymbolName:(NSString *)name;
- (id)performQueryForSymbolName:(NSString *)name ofType:(Class)klass;

@end
