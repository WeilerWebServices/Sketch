//
//  JSTalk.m
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "COScript.h"
#import "COSListener.h"
#import "COSPreprocessor.h"
#import "COScript+Fiber.h"
#import "COScript+Interval.h"
#import "COCacheBox.h"

#import <ScriptingBridge/ScriptingBridge.h>
#import "MochaRuntime.h"
#import "MOMethod.h"
#import "MOUndefined.h"
#import "MOBridgeSupportController.h"

#import <stdarg.h>

extern int *_NSGetArgc(void);
extern char ***_NSGetArgv(void);

static BOOL JSTalkShouldLoadJSTPlugins = YES;
static NSMutableArray *JSTalkPluginList;
static NSMutableDictionary<NSString*, NSString*>* coreModuleScriptCache; // we are keeping the core modules' script in memory as they are required very often

static id<COFlowDelegate> COFlowDelegate = nil;

@interface Mocha (Private)
- (JSValueRef)setObject:(id)object withName:(NSString *)name;
- (JSValueRef)setJSValue:(JSValueRef)jsValue withName:(NSString *)name;
- (BOOL)removeObjectWithName:(NSString *)name;
- (JSValueRef)callJSFunction:(JSObjectRef)jsFunction withArgumentsInArray:(NSArray *)arguments;
- (id)objectForJSValue:(JSValueRef)value;
@end

@interface COScript (Private)

@end

@implementation COScript {
    NSMutableDictionary<NSString*, COCacheBox*>* moduleCache;
}

+ (id)setFlowDelegate:(id<COFlowDelegate>)flowDelegate {
    id oldDelegate = COFlowDelegate;
    COFlowDelegate = flowDelegate;
    return oldDelegate;
}

+ (void)listen {
    [COSListener listen];
}

+ (void)setShouldLoadExtras:(BOOL)b {
    JSTalkShouldLoadJSTPlugins = b;
}

+ (void)setShouldLoadJSTPlugins:(BOOL)b {
    JSTalkShouldLoadJSTPlugins = b;
}


- (id)init {
    return [self initWithCoreModules:@{} andName:nil];
}

- (instancetype)initWithCoreModules:(NSDictionary*)coreModules andName:(NSString*)name {
    self = [super init];
    if ((self != nil)) {
        _mochaRuntime = [[Mocha alloc] initWithName:name ? name : @"Untitled"];
        
        self.coreModuleMap = coreModules;
        if (!coreModuleScriptCache) {
            coreModuleScriptCache = [NSMutableDictionary dictionary];
        }
        moduleCache = [NSMutableDictionary dictionary];
        
        [self setEnv:[NSMutableDictionary dictionary]];
        [self setShouldPreprocess:YES];
        
        [self addExtrasToRuntime];
    }
    
    return self;
}

+ (void)resetCache {
    coreModuleScriptCache = [NSMutableDictionary dictionary];
    [[MOBridgeSupportController sharedController] reset];
}

- (void)dealloc {
//    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cleanup {
    // clean up fibers to shut everything down nicely
    [self cleanupFibers];
    
    // clean up the global object that we injected in the runtime
    [self deleteObjectWithName:@"jstalk"];
    [self deleteObjectWithName:@"coscript"];
    [self deleteObjectWithName:@"print"];
    [self deleteObjectWithName:@"log"];
    [self deleteObjectWithName:@"require"];
    if ([self.coreModuleMap objectForKey:@"console"]) {
        [self deleteObjectWithName:@"console"];
    }
    if ([self.coreModuleMap objectForKey:@"buffer"]) {
        [self deleteObjectWithName:@"Buffer"];
    }
    if ([self.coreModuleMap objectForKey:@"timers"]) {
        [self deleteObjectWithName:@"setTimeout"];
        [self deleteObjectWithName:@"clearTimeout"];
        [self deleteObjectWithName:@"setInterval"];
        [self deleteObjectWithName:@"clearInterval"];
        [self deleteObjectWithName:@"setImmediate"];
        [self deleteObjectWithName:@"clearImmediate"];
    }
    
    [moduleCache enumerateKeysAndObjectsUsingBlock:^(NSString *key, COCacheBox *cacheBox, BOOL *stop) {
        [cacheBox cleanup];
    }];
    
    // clean up mocha
    [_mochaRuntime shutdown];
    _mochaRuntime = nil;
}

- (void)fiberWasCleared {
    if (COFlowDelegate != nil) {
        if (![self shouldKeepRunning]) {
            [COFlowDelegate didClearEventStack:self];
        }
    }
}

- (void)garbageCollect {
    
//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    [_mochaRuntime garbageCollect];
    
//    debug(@"gc took %f seconds", [NSDate timeIntervalSinceReferenceDate] - start); (void)start;
}

- (BOOL)shouldKeepRunning {
    if (_shouldKeepAround) {
        return YES;
    }
    if (_activeFibers != nil) {
        return [_activeFibers count] > 0;
    }
    return NO;
}


- (JSGlobalContextRef)context {
    return [_mochaRuntime context];
}

- (void)addExtrasToRuntime {
    
    [self pushObject:self withName:@"jstalk"];
    [self pushObject:self withName:@"coscript"];
    
    [_mochaRuntime evalString:@"var nil=null;\n"];
    [_mochaRuntime setValue:[MOMethod methodWithTarget:self selector:@selector(print:)] forKey:@"print"];
    [_mochaRuntime setValue:[MOMethod methodWithTarget:self selector:@selector(print:)] forKey:@"log"];
    [_mochaRuntime setValue:[MOMethod methodWithTarget:self selector:@selector(require:)] forKey:@"require"];
    
    [_mochaRuntime loadFrameworkWithName:@"AppKit"];
    [_mochaRuntime loadFrameworkWithName:@"Foundation"];

    BOOL previousShouldPreprocess = self.shouldPreprocess;
    self.shouldPreprocess = NO;
    
    // if there is a console module, use it to polyfill the console global
    if ([self.coreModuleMap objectForKey:@"console"]) {
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('console')(); })()"] withName:@"console"];
    }
    
    // if there is a buffer module, use it to polyfill the Buffer global
    if ([self.coreModuleMap objectForKey:@"buffer"]) {
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('buffer').Buffer; })()"] withName:@"Buffer"];
    }
    
    // if there is a timers module, use it to polyfill the setTimeout globals
    if ([self.coreModuleMap objectForKey:@"timers"]) {
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('timers').setTimeout; })()"] withName:@"setTimeout"];
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('timers').clearTimeout; })()"] withName:@"clearTimeout"];
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('timers').setInterval; })()"] withName:@"setInterval"];
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('timers').clearInterval; })()"] withName:@"clearInterval"];
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('timers').setImmediate; })()"] withName:@"setImmediate"];
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('timers').clearImmediate; })()"] withName:@"clearImmediate"];
    }
    
    // if there is a process module, use it to polyfill the process global
    if ([self.coreModuleMap objectForKey:@"process"]) {
        [self pushJSValue:[self executeStringAndReturnJSValue:@"(function() { return require('process'); })()"] withName:@"process"];
    }
    
    self.shouldPreprocess = previousShouldPreprocess;
}

+ (void)loadExtraAtPath:(NSString*)fullPath {
    
    Class pluginClass;
    
    @try {
        
        NSBundle *pluginBundle = [NSBundle bundleWithPath:fullPath];
        if (!pluginBundle) {
            return;
        }
        
        NSString *principalClassName = [[pluginBundle infoDictionary] objectForKey:@"NSPrincipalClass"];
        
        if (principalClassName && NSClassFromString(principalClassName)) {
            NSLog(@"The class %@ is already loaded, skipping the load of %@", principalClassName, fullPath);
            return;
        }
        
        [principalClassName class]; // force loading of it.
        
        NSError *err = nil;
        [pluginBundle loadAndReturnError:&err];
        
        if (err) {
            NSLog(@"Error loading plugin at %@", fullPath);
            NSLog(@"%@", err);
        }
        else if ((pluginClass = [pluginBundle principalClass])) {
            
            // do we want to actually do anything with em' at this point?
            
            NSString *bridgeSupportName = [[pluginBundle infoDictionary] objectForKey:@"BridgeSuportFileName"];
            
            if (bridgeSupportName) {
                NSString *bridgeSupportPath = [pluginBundle pathForResource:bridgeSupportName ofType:nil];
                
                NSError *outErr = nil;
                if (![[MOBridgeSupportController sharedController] loadBridgeSupportAtURL:[NSURL fileURLWithPath:bridgeSupportPath] error:&outErr]) {
                    NSLog(@"Could not load bridge support file at %@", bridgeSupportPath);
                }
            }
        }
        else {
            //debug(@"Could not load the principal class of %@", fullPath);
            //debug(@"infoDictionary: %@", [pluginBundle infoDictionary]);
        }
        
    }
    @catch (NSException * e) {
        NSLog(@"EXCEPTION: %@: %@", [e name], e);
    }
    
}

+ (void)resetPlugins {
    JSTalkPluginList = nil;
}

+ (void)loadPlugins {
    
    // install plugins that were passed via the command line
    int i = 0;
    char **argv = *_NSGetArgv();
    for (i = 0; argv[i] != NULL; ++i) {
        
        NSString *a = [NSString stringWithUTF8String:argv[i]];
        
        if ([@"-jstplugin" isEqualToString:a] || [@"-cosplugin" isEqualToString:a]) {
            i++;
            NSLog(@"Loading plugin at: [%@]", [NSString stringWithUTF8String:argv[i]]);
            [self loadExtraAtPath:[NSString stringWithUTF8String:argv[i]]];
        }
    }
    
    JSTalkPluginList = [NSMutableArray array];
    
    NSString *appSupport = @"Library/Application Support/JSTalk/Plug-ins";
    NSString *appPath    = [[NSBundle mainBundle] builtInPlugInsPath];
    NSString *sysPath    = [@"/" stringByAppendingPathComponent:appSupport];
    NSString *userPath   = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
    
    
    // only make the JSTalk dir if we're JSTalkEditor.
    // or don't ever make it, since you'll get rejected from the App Store. *sigh*
    /*
    if (![[NSFileManager defaultManager] fileExistsAtPath:userPath]) {
        
        NSString *mainBundleId = [[NSBundle mainBundle] bundleIdentifier];
        
        if ([@"org.jstalk.JSTalkEditor" isEqualToString:mainBundleId]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:userPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    */
    
    for (NSString *folder in [NSArray arrayWithObjects:appPath, sysPath, userPath, nil]) {
        
        for (NSString *bundle in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil]) {
            
            if (!([bundle hasSuffix:@".jstplugin"] || [bundle hasSuffix:@".cosplugin"])) {
                continue;
            }
            
            [self loadExtraAtPath:[folder stringByAppendingPathComponent:bundle]];
        }
    }
    
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"org.jstalk.JSTalkEditor"]) {
        
        NSURL *jst = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"org.jstalk.JSTalkEditor"];
        
        if (jst) {
            
            NSURL *folder = [[jst URLByAppendingPathComponent:@"Contents"] URLByAppendingPathComponent:@"PlugIns"];
            
            for (NSString *bundle in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[folder path] error:nil]) {
                
                if (!([bundle hasSuffix:@".jstplugin"])) {
                    continue;
                }
                
                [self loadExtraAtPath:[[folder path] stringByAppendingPathComponent:bundle]];
            }
        }
    }
}

+ (void)loadBridgeSupportFileAtURL:(NSURL*)url {
    NSError *outErr = nil;
    if (![[MOBridgeSupportController sharedController] loadBridgeSupportAtURL:url error:&outErr]) {
        NSLog(@"Could not load bridge support file at %@", url);
    }
}

NSString *currentCOScriptThreadIdentifier = @"org.jstalk.currentCOScriptHack";

// FIXME: Change currentCOScript and friends to use a stack in the thread dictionary, instead of just overwriting what might already be there."

+ (NSMutableArray*)currentCOSThreadStack {
    
    NSMutableArray *ar = [[[NSThread currentThread] threadDictionary] objectForKey:currentCOScriptThreadIdentifier];
    
    if (!ar) {
        ar = [NSMutableArray array];
        [[[NSThread currentThread] threadDictionary] setObject:ar forKey:currentCOScriptThreadIdentifier];
    }
    
    return ar;
}

+ (COScript*)currentCOScript {
    
    return [[self currentCOSThreadStack] lastObject];
}

- (void)pushAsCurrentCOScript {
    [[[self class] currentCOSThreadStack] addObject:self];
}

- (void)popAsCurrentCOScript {
    
    if ([[[self class] currentCOSThreadStack] count]) {
        [[[self class] currentCOSThreadStack] removeLastObject];
    }
    else {
        NSLog(@"popAsCurrentCOScript - currentCOSThreadStack is empty");
    }
}

- (void)pushObject:(id)obj withName:(NSString*)name  {
    [_mochaRuntime setObject:obj withName:name];
}

- (void)pushJSValue:(JSValueRef)obj withName:(NSString*)name  {
    [_mochaRuntime setJSValue:obj withName:name];
}

- (void)deleteObjectWithName:(NSString*)name {
    [_mochaRuntime removeObjectWithName:name];
}

# pragma mark - require

/// This aims to implement the require resolution algorithm from NodeJS.
/// Given a `module` string required by a given script at the `currentURL`
/// using `require('./path/to/module')`, this method returns a URL
/// corresponding to the `module`.
/// `module` could also be the name of a core module that we shipped with the app
/// (for example `util`), in which case, it will return the URL to that one
/// and set `isRequiringCore` to YES.
- (NSURL*)resolveModule:(NSString*)module currentURL:(NSURL*)currentURL isRequiringCoreModule: (BOOL*)isRequiringCore {
    if (![module hasPrefix: @"."] && ![module hasPrefix: @"/"] && ![module hasPrefix: @"~"]) {
        *isRequiringCore = YES;
        return self.coreModuleMap[module];
    }
    
    *isRequiringCore = NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isRelative = [module hasPrefix: @"."];
    NSString *modulePath = [module stringByStandardizingPath];
    NSURL *moduleURL = isRelative ? [NSURL URLWithString:modulePath relativeToURL:currentURL] : [NSURL fileURLWithPath:modulePath];
    
    if (moduleURL == nil) {
        return nil;
    }
    
    BOOL isDir;
    
    if ([fileManager fileExistsAtPath:moduleURL.path isDirectory:&isDir]) {
        if (!isDir) {
            // if the module is a proper path to a file, just use it
            return moduleURL;
        }
        // if it's a path to a directory, let's try to find a package.json
        NSURL *packageJSONURL = [moduleURL URLByAppendingPathComponent:@"package.json"];
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:packageJSONURL.path];
        if (jsonData != nil) {
            id packageJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
            if (packageJSON != nil) {
                // we have a package.json, so let's find the `main` key
                NSString *main = [packageJSON objectForKey:@"main"];
                if (main) {
                    // main is always a relative path, so let's transform it to one
                    if ([module hasPrefix: @"/"]) {
                        main = [@"." stringByAppendingString:main];
                    } else if (![module hasPrefix: @"."]) {
                        main = [@"./" stringByAppendingString:main];
                    }
                    return [self resolveModule:[moduleURL URLByAppendingPathComponent:main].path currentURL:currentURL isRequiringCoreModule:isRequiringCore];
                }
            }
        }
        
        // default to index.js otherwise
        NSURL *indexURL = [moduleURL URLByAppendingPathComponent:@"index.js"];
        if ([fileManager fileExistsAtPath:indexURL.path isDirectory:&isDir] && !isDir) {
            return indexURL;
        }
        
        // couldn't find anything :(
        return nil;
    }
    
    // try by adding the js extension which can be ommited
    NSURL *jsURL = [moduleURL URLByAppendingPathExtension:@"js"];
    if ([fileManager fileExistsAtPath:jsURL.path isDirectory:&isDir] && !isDir) {
        return jsURL;
    }
    
    // unlucky :(
    return nil;
}

- (JSValueRef)require:(NSString *)module {
    // store the current script URL so that we can put it back after requiring the module
    NSURL *currentURL = [_env objectForKey:@"scriptURL"];
    
    // we never want to preprocess the modules - it shouldn't use Cocoascript syntax.
    BOOL savedPreprocess = self.shouldPreprocess;
    self.shouldPreprocess = NO;
    
    JSValueRef result = NULL;
    
    BOOL isRequiringCore;
    NSURL *moduleURL = [self resolveModule:module currentURL:currentURL isRequiringCoreModule:&isRequiringCore];
    
    if (moduleURL == nil) {
        @throw [NSException
                exceptionWithName:NSInvalidArgumentException
                reason:isRequiringCore
                    ? [NSString stringWithFormat:@"%@ is not a core package", module]
                    : [NSString stringWithFormat:@"Cannot find module %@ from package %@", module, currentURL.path]
                userInfo:nil];
    }
    
    if (moduleCache[moduleURL.path]) {
        return moduleCache[moduleURL.path].jsValueRef;
    }
    
    if (isRequiringCore) {
        // we set `isRequiringCore` in the environment so that if a core module is requiring other files,
        // we know that it's still a core module and should be cached as such
        [_env setObject:@"true" forKey:@"isRequiringCore"];
    }
    
    result = [self executeModuleAtURL:moduleURL];
    
    if (isRequiringCore) {
        [_env setObject:@"false" forKey:@"isRequiringCore"];
    }
    
    // go back to previous settings
    self.shouldPreprocess = savedPreprocess;
    if (currentURL) {
        [_env setObject:currentURL forKey:@"scriptURL"];
    }
    
    // cache the module so it keeps it state if required again
    COCacheBox *cacheBox = [[COCacheBox alloc] initWithJSValueRef:result inContext:_mochaRuntime.context];
    [moduleCache setObject:cacheBox forKey:moduleURL.path];
    
    return result;
}

- (JSValueRef)executeModuleAtURL:(NSURL*)scriptURL {
    JSValueRef result = NULL;
    if (scriptURL) {
        NSError *error;
        NSString *script;
        if (coreModuleScriptCache[scriptURL.path]) {
            script = coreModuleScriptCache[scriptURL.path];
        } else {
            script = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:&error];
            if (script && [[_env objectForKey:@"isRequiringCore"] isEqualToString:@"true"]) {
                // cache the core module's so that we don't need to read it from disk again
                [coreModuleScriptCache setObject:script forKey:scriptURL.path];
            }
        }
        if (script) {
            NSString *module = [scriptURL.pathExtension isEqual:@"json"]
            ? [NSString stringWithFormat:@"(function() { return %@ })()", script]
            : [NSString stringWithFormat:@"(function() { var module = { exports : {} }; var exports = module.exports; %@ ; return module.exports; })()", script];
            result = [self executeStringAndReturnJSValue:module baseURL:scriptURL];
        } else if (error) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Cannot find module %@", scriptURL.path] userInfo:nil];
        }
    }
    return result;
}

# pragma mark - execute string

- (id)executeString:(NSString*)str {
    return [self executeString:str baseURL:nil];
}

- (JSValueRef)executeStringAndReturnJSValue:(NSString*)str {
    return [self executeStringAndReturnJSValue:str baseURL:nil];
}

- (JSValueRef)executeStringAndReturnJSValue:(NSString*)str baseURL:(NSURL*)base {
    if (!JSTalkPluginList && JSTalkShouldLoadJSTPlugins) {
        [COScript loadPlugins];
    }
    
    if (base) {
        [_env setObject:base forKey:@"scriptURL"];
    }
    
    if (!base && [[_env objectForKey:@"scriptURL"] isKindOfClass:[NSURL class]]) {
        base = [_env objectForKey:@"scriptURL"];
    }
    
    if ([self shouldPreprocess]) {
        str = [COSPreprocessor preprocessCode:str withBaseURL:base];
    }
    self.processedSource = str;
    
    [self pushAsCurrentCOScript];
    
    JSValueRef resultObj = NULL;
    
    @try {
        resultObj = [_mochaRuntime evalJSString:str scriptPath:[base path]];
    }
    @catch (NSException *e) {
        [self printException:e];
    }
    
    [self popAsCurrentCOScript];
    
    return resultObj;
}

- (id)executeString:(NSString*)str baseURL:(NSURL*)base {
    id resultObj = [_mochaRuntime objectForJSValue:[self executeStringAndReturnJSValue:str baseURL:base]];

    if (resultObj == [MOUndefined undefined]) {
        resultObj = nil;
    }
    
    return resultObj;
}

- (BOOL)hasFunctionNamed:(NSString*)name {
    JSValueRef exception = nil;
    JSStringRef jsFunctionName = JSStringCreateWithUTF8CString([name UTF8String]);
    JSValueRef jsFunctionValue = JSObjectGetProperty([_mochaRuntime context], JSContextGetGlobalObject([_mochaRuntime context]), jsFunctionName, &exception);
    JSStringRelease(jsFunctionName);
    
    
    return jsFunctionValue && (JSValueGetType([_mochaRuntime context], jsFunctionValue) == kJSTypeObject);
}

- (id)callFunctionNamed:(NSString*)name withArguments:(NSArray*)args {
    id returnValue = nil;
    
    @try {
        
        [self pushAsCurrentCOScript];
        
        returnValue = [_mochaRuntime callFunctionWithName:name withArgumentsInArray:args];
        
        if (returnValue == [MOUndefined undefined]) {
            returnValue = nil;
        }
    }
    @catch (NSException * e) {
        [self printException:e];
    }
    
    [self popAsCurrentCOScript];
    
    return returnValue;
}


- (id)callJSFunction:(JSObjectRef)jsFunction withArgumentsInArray:(NSArray *)arguments {
    [self pushAsCurrentCOScript];
    
    JSValueRef r = nil;
    @try {
        r = [_mochaRuntime callJSFunction:jsFunction withArgumentsInArray:arguments];
    }
    @catch (NSException * e) {
        [self printException:e];
    }
    
    [self popAsCurrentCOScript];
    
    if (r) {
        return [_mochaRuntime objectForJSValue:r];
    }
    
    return nil;
}

- (void)unprotect:(id)o {
    JSValueRef value = [_mochaRuntime JSValueForObject:o];
    
    assert(value);
    
    if (value) {
        JSObjectRef jsObject = JSValueToObject([_mochaRuntime context], value, NULL);
        id private = (__bridge id)JSObjectGetPrivate(jsObject);
        
        assert([private representedObject] == o);
        
//        debug(@"COS unprotecting %@", o);
        JSValueUnprotect([_mochaRuntime context], value);
    }
}

- (void)protect:(id)o {
    JSValueRef value = [_mochaRuntime JSValueForObject:o];
    
    assert(value);
    
    if (value) {
        JSObjectRef jsObject = JSValueToObject([_mochaRuntime context], value, NULL);
        
//        debug(@"COS protecting %@ / v: %p o: %p", o, value, jsObject);
        
        id private = (__bridge id)JSObjectGetPrivate(jsObject);
        
        assert([private representedObject] == o);
        
        JSValueProtect([_mochaRuntime context], value);
    }
}

// JavaScriptCore isn't safe for recursion.  So calling this function from
// within a script is a really bad idea.  Of couse, that's what it was written
// for, so it really needs to be taken out.

- (void)include:(NSString*)fileName {
    
    if (![fileName hasPrefix:@"/"] && [_env objectForKey:@"scriptURL"]) {
        NSString *parentDir = [[[_env objectForKey:@"scriptURL"] path] stringByDeletingLastPathComponent];
        fileName = [parentDir stringByAppendingPathComponent:fileName];
    }
    
    NSURL *scriptURL = [NSURL fileURLWithPath:fileName];
    NSError *err = nil;
    NSString *str = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:&err];
    
    if (!str) {
        NSLog(@"Could not open file '%@'", scriptURL);
        NSLog(@"Error: %@", err);
        return;
    }
    
    if (_shouldPreprocess) {
        str = [COSPreprocessor preprocessCode:str];
    }
    self.processedSource = str;
    
    [_mochaRuntime evalString:str];
}

# pragma mark - print

- (void)printException:(NSException*)e {
    NSMutableDictionary* errorToPrint = [@{
                                          @"payload": @[e],
                                          @"level": @"error"
                                          } mutableCopy];

    if (_printController) {
        [_printController scriptEncounteredException:e];
        errorToPrint[@"command"] = _printController;
    }

    NSMutableString *s = [NSMutableString string];
    
    [s appendFormat:@"%@", e];
    
    NSDictionary *d = [e userInfo];

    if ([d objectForKey:@"stack"] != nil && ![[d objectForKey:@"stack"] isEqualToString:@"undefined"]) {
        // this is the same algo as in skpm/util
        // https://github.com/skpm/util/blob/5edb84f6d7983320ab064b7f2cf575fbedbf183b/index.js#L679-L695
        // so that it's consistent when logging an error
        NSArray* stacks = [[d objectForKey:@"stack"] componentsSeparatedByString:@"\n"];
        for (NSString* stack in stacks) {
            NSMutableArray* parts = [[stack componentsSeparatedByString:@"/"] mutableCopy];
            if ([parts count] > 0) {
                NSString* fn = [parts[0] stringByReplacingOccurrencesOfString:@"@" withString:@""];
                [parts removeObjectAtIndex:0];
                NSString* callsite = [NSString stringWithFormat:@"/%@", [parts componentsJoinedByString:@"/"]];
                [s appendFormat:@"\n    at "];
                if (fn != nil && ![fn isEqualToString:@""]) {
                    [s appendFormat:@"%@ (", fn];
                }
                [s appendFormat:@"%@", callsite];
                if (fn != nil && ![fn isEqualToString:@""]) {
                    [s appendFormat:@")"];
                }
            }
        }
    } else if ([d objectForKey:@"sourceURL"] != nil) {
        [s appendFormat:@"\n    at %@", [d objectForKey:@"sourceURL"]];
        if ([d objectForKey:@"line"] != nil) {
            [s appendFormat:@":%@", [d objectForKey:@"line"]];
        }
        if ([d objectForKey:@"column"] != nil) {
            [s appendFormat:@":%@", [d objectForKey:@"column"]];
        }
    }
    
    for (id o in [d allKeys]) {
        if (![o isEqualToString:@"stack"] && ![o isEqualToString:@"line"] && ![o isEqualToString:@"column"] && ![o isEqualToString:@"sourceURL"]) {
            [s appendFormat:@"\n  %@: %@", o, [d objectForKey:o]];
        }
    }

    errorToPrint[@"stringValue"] = s;
    
    [self print:errorToPrint];
}

- (void)print:(id)s {
    
    if (_printController) {
        [_printController print:s];
    } else {
        if (![s isKindOfClass:[NSString class]]) {
            s = [s description];
        }
        
        printf("%s\n", [s UTF8String]);
    }
}

# pragma mark - proxy

+ (id)applicationOnPort:(NSString*)port {
    
    NSConnection *conn  = nil;
    NSUInteger tries    = 0;
    
    while (!conn && tries < 10) {
        
        conn = [NSConnection connectionWithRegisteredName:port host:nil];
        tries++;
        if (!conn) {
//            debug(@"Sleeping, waiting for %@ to open", port);
            sleep(1);
        }
    }
    
    if (!conn) {
        NSBeep();
        NSLog(@"Could not find a JSTalk connection to %@", port);
    }
    
    return [conn rootProxy];
}

+ (id)application:(NSString*)app {
    
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:app];
    
    if (!appPath) {
        NSLog(@"Could not find application '%@'", app);
        // fixme: why are we returning a bool?
        return [NSNumber numberWithBool:NO];
    }
    
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    NSString *bundleId  = [appBundle bundleIdentifier];
    
    // make sure it's running
	NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    BOOL found = NO;
    
    for (NSRunningApplication *rapp in runningApps) {
        
        if ([[rapp bundleIdentifier] isEqualToString:bundleId]) {
            found = YES;
            break;
        }
        
    }
    
	if (!found) {
        BOOL launched = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleId
                                                                             options:NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
                                                      additionalEventParamDescriptor:nil
                                                                    launchIdentifier:nil];
        if (!launched) {
            NSLog(@"Could not open up %@", appPath);
            return nil;
        }
    }
    
    
    return [self applicationOnPort:[NSString stringWithFormat:@"%@.JSTalk", bundleId]];
}

+ (id)app:(NSString*)app {
    return [self application:app];
}

+ (id)proxyForApp:(NSString*)app {
    return [self application:app];
}


@end



@implementation JSTalk

@end
