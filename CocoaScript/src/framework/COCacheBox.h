//  Created by Mathieu Dutour on 14/02/2019.
//  

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

/*
 This class is used to retain the JSValueRefs that are created when requiring
 a module. It is cleaned up when the COScript instance is cleaned up.
 
 We can't put a JSValueRef in an NSDictionary directly so we need to wrap it in
 this class.
 */
@interface COCacheBox : NSObject
@property (assign, readonly) JSValueRef jsValueRef;

- (instancetype)initWithJSValueRef:(JSValueRef)jsValue inContext:(JSGlobalContextRef)context;
- (void)cleanup;
@end

NS_ASSUME_NONNULL_END
