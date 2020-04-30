//
//  MOBox.h
//  Mocha
//
//  Created by Logan Collins on 5/12/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>


@class Mocha;
@class MOBoxManager;

#if DEBUG
    // When this is set to 1, we add some extra book keeping objects to every box,
    // to assist with debugging.
    #define MOCHA_DEBUG_CRASHES 1
#endif

/*!
 * @class MOBox
 * @abstract A boxed Objective-C object
 */
@interface MOBox : NSObject

- (id)initWithManager:(MOBoxManager *)manager object:(id)object jsObject:(JSObjectRef)jsObject;
- (void)disassociateObject;

/*!
 * @property representedObject
 * @abstract The boxed Objective-C object
 *
 * @result An object
 */
@property (strong, readonly) id representedObject;

/*!
 * @property JSObject
 * @abstract The JSObject representation of the box
 *
 * @result A JSObjectRef value
 */
@property (assign, readonly) JSObjectRef JSObject;

/*!
 * @property manager
 * @abstract The manager for the object
 *
 * @result A MOBoxManager object
 */
@property (weak, readonly) MOBoxManager *manager;

#if MOCHA_DEBUG_CRASHES

/**
  A snapshot of the description of the object that the box is for, at
  the time that it was first created.
 */
@property (readonly, strong) NSString *representedObjectCanaryDesc;

/**
  A global instance counter, helpful for tracking the box through
  various bits of logging output.
 */

@property (readonly, assign) NSUInteger count;
#endif

@end
