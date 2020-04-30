// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/03/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
//  For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#import "MOJavaScriptObject.h"
#import "MochaRuntime_Private.h"

@interface MOJSBlock : NSObject<NSCopying>
@property (strong, nonatomic, readonly) MOJavaScriptObject* function;
@property (strong, nonatomic, readonly) NSMethodSignature* signature;

+ (instancetype)blockWithSignature:(NSString*)signature function:(MOJavaScriptObject*)function;
- (instancetype)initWithSignature:(const char*)signature function:(MOJavaScriptObject *)function;
@end
