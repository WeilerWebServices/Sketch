//  Created by Mathieu Dutour on 01/05/2019.
//  

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CODebugControllerDelegate
- (void)output:(NSString*)format args:(va_list)args;
@end

/// The debug controller is used by COScript to print debugging messages.
/// It allows a delegate to take care of handling the message. If there is
/// no delegate, it will use `NSLogv` to print the message.
@interface CODebugController : NSObject

@property (strong) id<CODebugControllerDelegate> delegate;

+ (instancetype)sharedController;
+ (id<CODebugControllerDelegate>)setDelegate:(id<CODebugControllerDelegate>)delegate;
+ (void)output:(NSString*)format, ...;

@end

NS_ASSUME_NONNULL_END
