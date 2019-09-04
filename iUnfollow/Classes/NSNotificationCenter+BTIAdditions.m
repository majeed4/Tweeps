//
//  NSNotificationCenter+BTIAdditions.m
//
//  Created by Brian Slick in Sept 2012.
//  Copyright (c) 2012 BriTer Ideas LLC. All rights reserved.
//

#import "NSNotificationCenter+BTIAdditions.h"

@implementation NSNotificationCenter (BTIAdditions)

- (void)postNotificationNameOnMainThreadBTI:(NSString *)notificationName
{
	//BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
	
	[self postNotificationNameOnMainThreadBTI:notificationName
									   object:nil
									 userInfo:nil];
	
	//BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)postNotificationNameOnMainThreadBTI:(NSString *)notificationName
								   userInfo:(NSDictionary *)userInfo
{
	//BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
	
	[self postNotificationNameOnMainThreadBTI:notificationName
									   object:nil
									 userInfo:userInfo];
	
	//BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)postNotificationNameOnMainThreadBTI:(NSString *)notificationName
									 object:(id)object
								   userInfo:(NSDictionary *)userInfo
{
	//BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
	
	NSNotification *notification = [NSNotification notificationWithName:notificationName
																 object:object
															   userInfo:userInfo];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[[NSNotificationCenter defaultCenter] postNotification:notification];
		
	});
	
	//BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

@end
