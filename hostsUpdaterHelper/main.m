//
//  main.m
//  hostsUpdaterHelper
//
//  Created by Harshad on 14/03/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <notify.h>

#import "HUPConstants.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        if (argc > 1) {
            const char *domain = argv[1];

            NSString *domainString = [NSString stringWithCString:domain encoding:NSUTF8StringEncoding];
            NSURL *domainURL = [NSURL URLWithString:domainString];
            NSString *host = [NSString stringWithFormat:@"127.0.0.1    %@\n", [domainURL host]];
            NSString *savedDomains = [NSString stringWithContentsOfFile:HUPCustomDomainsFilePath encoding:NSUTF8StringEncoding error:nil];
            if (savedDomains == nil) {
                savedDomains = @"";
            }
            savedDomains = [savedDomains stringByAppendingString:host];
            [savedDomains writeToFile:HUPCustomDomainsFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            notify_post([HUPDomainChangedNotificationName cStringUsingEncoding:NSUTF8StringEncoding]);
            
        }
        
    }
    return 0;
}

