//
//  NSNotificationCenter+BTIAdditions.h
//
//  Created by Brian Slick in Sept 2012.
//  Copyright (c) 2012 BriTer Ideas LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 
 OVERVIEW
 
 These categories provide easy means of posting notifications on the main thread.  Handy for operations that are happening in a background thread.
 
 */

@interface NSNotificationCenter (BTIAdditions)

- (void)postNotificationNameOnMainThreadBTI:(NSString *)notificationName;
- (void)postNotificationNameOnMainThreadBTI:(NSString *)notificationName userInfo:(NSDictionary *)userInfo;
- (void)postNotificationNameOnMainThreadBTI:(NSString *)notificationName object:(id)object userInfo:(NSDictionary *)userInfo;

@end