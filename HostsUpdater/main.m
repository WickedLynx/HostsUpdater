//
//  main.m
//  HostsUpdater
//
//  Created by Harshad on 11/03/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HostsFileFetcher.h"

HostsFileFetcher *fileFetcher = nil;

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        if (fileFetcher == nil) {
            fileFetcher = [[HostsFileFetcher alloc] init];
        }
        
        [[NSRunLoop currentRunLoop] run];
        
        
    }
}

