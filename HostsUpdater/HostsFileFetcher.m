//
//  HostsFileFetcher.m
//  HostsUpdater
//
//  Created by Harshad on 11/03/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "HostsFileFetcher.h"
#import "Reachability.h"

#import "HUPConstants.h"

#include <notify.h>

NSString *const HUPHostsFilePath = @"/etc/hosts";
NSString *const HUPRemoteHostsFile = @"http://hosts-file.net/.%5Cad_servers.txt";

NSTimeInterval const HUPUpdateInterval = 5 * 3600; // 5 hours

@implementation HostsFileFetcher {
    NSTimer *_timer;
    NSDate *_lastUpdatedDate;
    Reachability *_reachibility;
    NSString *_customDomains;
    NSString *_fetchedDomains;
}

- (void)writeHostsFile {
    NSString *defaultMacHosts = [NSString stringWithFormat:@"127.0.0.1       localhost\n255.255.255.255 broadcasthost\n::1             localhost\nfe80::1%%lo0     localhost\n"];
    
    _customDomains = [NSString stringWithContentsOfFile:HUPCustomDomainsFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *finalFile = [NSString stringWithFormat:@"%@\n%@\n%@\n", defaultMacHosts, _customDomains, _fetchedDomains];
    finalFile = [finalFile stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
    [finalFile writeToFile:HUPHostsFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)updateHostsFile {
    if ([[NSDate date] timeIntervalSinceDate:_lastUpdatedDate] > HUPUpdateInterval - 10) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:HUPRemoteHostsFile]];
        NSData *fileData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        if (fileData != nil && fileData.length > 0) {
            @autoreleasepool {
                NSString *hosts = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
                NSMutableArray *entries = [[hosts componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
                
                NSInteger indexToRemoveUpTo = -1;
                for (NSString *anEntry in entries) {
                    if ([anEntry hasPrefix:@"#"] || [anEntry rangeOfString:@"localhost"].location != NSNotFound) {
                        ++indexToRemoveUpTo;
                    } else if (anEntry.length > 0) {
                        break;
                    }
                }
                if (indexToRemoveUpTo > -1) {
                    for (int currentIndex = 0; currentIndex != indexToRemoveUpTo + 1; ++currentIndex) {
                        [entries removeObjectAtIndex:currentIndex];
                    }
                }
                
                NSString *modifiedHosts = [entries componentsJoinedByString:[NSString stringWithFormat:@"\n"]];
                _fetchedDomains = modifiedHosts;
                
                [self writeHostsFile];
            }
            _lastUpdatedDate = [NSDate date];
        }
    }
}

- (void)checkForUpdatedFile:(NSTimer *)timer {
    [self updateHostsFile];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:HUPCustomDomainsDirectoryPath isDirectory:&isDirectory] || !isDirectory) {
            [fileManager createDirectoryAtPath:HUPCustomDomainsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
            [fileManager createFileAtPath:HUPCustomDomainsFilePath contents:[@"# Add domains here separated by new lines\n\n" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        }
        
        _customDomains = [NSString stringWithContentsOfFile:HUPCustomDomainsFilePath encoding:NSUTF8StringEncoding error:nil];
        
        _lastUpdatedDate = [NSDate dateWithTimeIntervalSince1970:0.0f];
        _timer = [NSTimer scheduledTimerWithTimeInterval:HUPUpdateInterval target:self selector:@selector(checkForUpdatedFile:) userInfo:nil repeats:YES];
        
        _reachibility = [Reachability reachabilityWithHostname:@"http://hosts-file.net"];
        __weak typeof(self) wSelf = self;
        [_reachibility setReachableBlock:^(Reachability*reach) {
            [wSelf updateHostsFile];
        }];
        [_reachibility startNotifier];
        
        int fileChangedToken;
        notify_register_dispatch([HUPDomainChangedNotificationName cStringUsingEncoding:NSUTF8StringEncoding], &fileChangedToken, dispatch_get_main_queue(), ^(int token) {
            [self writeHostsFile];
            
        });
        
    }
    
    return self;
}

@end
