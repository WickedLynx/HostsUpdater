//
//  HostsFileFetcher.m
//  HostsUpdater
//
//  Created by Harshad Dange on 11/03/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "HostsFileFetcher.h"
#import "Reachability.h"

NSString *const HUPHostsFilePath = @"/etc/hosts";
NSString *const HUPRemoteHostsFile = @"http://hosts-file.net/.%5Cad_servers.txt";
NSTimeInterval const HUPUpdateInterval = 6 * 3600; // 6 hours

@implementation HostsFileFetcher {
    NSTimer *_timer;
    NSDate *_lastUpdatedDate;
    Reachability *_reachibility;
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
                NSString *defaultMacHosts = [NSString stringWithFormat:@"127.0.0.1       localhost\r255.255.255.255 broadcasthost\r::1             localhost\rfe80::1%%lo0     localhost\r184.72.115.86    search.yahoo.com\r"];
                modifiedHosts = [defaultMacHosts stringByAppendingString:modifiedHosts];
                modifiedHosts = [modifiedHosts stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
                [modifiedHosts writeToFile:HUPHostsFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
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
        
        _lastUpdatedDate = [NSDate dateWithTimeIntervalSince1970:0.0f];
        _timer = [NSTimer scheduledTimerWithTimeInterval:HUPUpdateInterval target:self selector:@selector(checkForUpdatedFile:) userInfo:nil repeats:YES];
        
        _reachibility = [Reachability reachabilityWithHostname:@"http://hosts-file.net"];
        __weak typeof(self) wSelf = self;
        [_reachibility setReachableBlock:^(Reachability*reach) {
            [wSelf updateHostsFile];
        }];
        [_reachibility startNotifier];


    }
    
    return self;
}

@end
