//  Created by Mathieu Dutour on 14/02/2019.
//  

#import "COCacheBox.h"

@implementation COCacheBox {
    JSGlobalContextRef _context;
}

- (instancetype)initWithJSValueRef:(JSValueRef)jsValue inContext:(JSGlobalContextRef)context {
    self = [super init];
    if (self) {
        _jsValueRef = jsValue;
        _context = context;
        JSGlobalContextRetain(context);
        JSValueProtect(context, jsValue);
    }
    
    return self;
}

- (void)cleanup {
    if (_jsValueRef != NULL) {
        JSValueUnprotect(_context, _jsValueRef);
    }
    if (_context != NULL) {
        JSGlobalContextRelease(_context);
    }
}
@end
