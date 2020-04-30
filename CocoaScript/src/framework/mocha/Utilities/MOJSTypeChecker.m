//  Created by Mathieu Dutour on 13/07/2018.
//  

#import "MOJSTypeChecker.h"

bool MOJSValueIsError(JSContextRef ctx, JSValueRef value) {
    if (JSValueIsObject(ctx, value))
    {
        JSStringRef errorString = JSStringCreateWithUTF8CString("Error");
        JSObjectRef errorConstructor = JSValueToObject(ctx, JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), errorString, NULL), NULL);
        JSStringRelease(errorString);
        
        return JSValueIsInstanceOfConstructor(ctx, value, errorConstructor, NULL);
    }
    return false;
}
