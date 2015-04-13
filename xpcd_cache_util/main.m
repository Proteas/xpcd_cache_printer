//
//  main.m
//  xpcd_cache_util
//
//  Created by Proteas on 15/4/12.
//  Copyright (c) 2015年 Proteas. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach-o/getsect.h>


#define XPC_PLIST_CACHE_KEY "LaunchDaemons"

CFPropertyListRef GetPropertyListFromCache(const char *libPath);


CFPropertyListRef
GetPropertyListFromCache(const char *libPath)
{
    if (libPath == NULL) {
        NSLog(@"[-] GetPropertyListFromCache: invalid param");
        return NULL;
    }
    
    static CFPropertyListRef propertyList;
    CFDataRef cacheData;
    CFErrorRef error;
    
    if (!propertyList) {
        uint8_t *data = NULL;
        unsigned long sz = 0;
        
        void *handle = dlopen(libPath, RTLD_NOW);
        
        if (handle) {
            void *fnptr = dlsym(handle, "__xpcd_cache");
            
            if (fnptr) {
                Dl_info image_info;
                
                int rv = dladdr(fnptr, &image_info);
                if (rv != 0) {
                    data = getsectiondata(image_info.dli_fbase, "__TEXT", "__xpcd_cache", &sz);
                } else {
                    NSLog(@"cache loading failed: failed to find address of __xpcd_cache symbol.");
                }
            } else {
                NSLog(@"cache loading failed: failed to find __xpcd_cache symbol in cache.");
            }
        } else {
            NSLog(@"cache loading failed: dlopen returned %s.", dlerror());
        }
        
        if (data) {
            cacheData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, data, sz, kCFAllocatorNull);
            if (cacheData) {
                propertyList = CFPropertyListCreateWithData(kCFAllocatorDefault, cacheData, kCFPropertyListMutableContainersAndLeaves, NULL, &error);
                CFRelease(cacheData);
            } else {
                NSLog(@"cache loading failed: unable to create data out of memory region.");
            }
        } else {
            NSLog(@"cache loading failed: no cache data found in __TEXT,__xpcd_cache segment.");
        }
    }
    
    return propertyList;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        const char *libPath = NULL;
        if (argc == 1) {
            libPath = "/System/Library/Caches/com.apple.xpcd/xpcd_cache.dylib";
        } else {
            libPath = argv[1];
        }
        
        CFPropertyListRef plist = GetPropertyListFromCache(libPath);
        NSDictionary *dict = (__bridge NSDictionary*)plist;
        
        NSString *plistPath = nil;
        if (argc == 3) {
            plistPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        }
        
        if (plistPath) {
            [dict writeToFile:plistPath atomically:NO];
        } else {
            NSLog(@"--->xpcd_cached plist:\n %@\n", dict);
        }
    }
    
    return 0;
}
