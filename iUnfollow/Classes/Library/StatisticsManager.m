//
//  StatisticsManager.m
//  iUnfollow
//
//  Created by Andrei Salanta on 1/16/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StatisticsManager.h"
#import "Constants.h"
#import "AcountUser.h"

@interface StatisticsManager ()


- (NSArray *)getAllInitialTimeFollowingIds;
- (NSArray *)getAllNowTimeFollowingIds;

- (void)setRecentFollowingIds:(NSArray *)arr;
- (void)setRecentFollowingYouIds:(NSArray *)arr;
- (void)setRecentUnfollowingIds:(NSArray *)arr;
- (void)setRecentUnfollowingYouIds:(NSArray *)arr;

@end

@implementation StatisticsManager

+ (StatisticsManager *)sharedInstance {
	static StatisticsManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[StatisticsManager alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(followingUserIdsFinish:)
													 name:stFollowingIdsFinished 
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(stFollowedIdsFinish:)
													 name:stFollowedIdsFinished 
												   object:nil];
	}
	return self;
}

- (NSArray *)getAllInitialTimeFollowingIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	NSArray *arr = [dict objectForKey:@"allTimeInitialFollowingIds"];
	return arr;
}

- (NSArray *)getAllNowTimeFollowingIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	NSArray *arr = [dict objectForKey:@"allTimeNowFollowingIds"];
	return arr;
}

- (void)setAllTimesInitalFollowingIds:(NSArray *)array {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:array forKey:@"allTimeInitialFollowingIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (void)setAllTimesNowFollowingIds:(NSArray *)array {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:array forKey:@"allTimeNowFollowingIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (void)setAllTimesNowFollowingTempIds:(NSArray *)tmp {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:tmp forKey:@"allTimesNowFollowingTmp"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];

}

- (NSArray *)getAllTimesNowFollowingTempIds { 
	if (![AcountUser sharedInstance].acountIdentifier) {
		return nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [dict objectForKey:@"allTimesNowFollowingTmp"];
}

- (NSArray *)getAllInitialTimeFollowedIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	NSArray *arr = [dict objectForKey:@"allTimeInitialFollowedIds"];
	return arr;
}

- (NSArray *)getAllNowTimeFollowedIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	NSArray *arr = [dict objectForKey:@"allTimeNowFollowedIds"];
	return arr;
}

- (void)setAllTimesInitalFollowedIds:(NSArray *)array {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:array forKey:@"allTimeInitialFollowedIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];

}

- (void)setAllTimesNowFollowedIds:(NSArray *)array {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:array forKey:@"allTimeNowFollowedIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (void)setAllTimesNowFollowedTempIds:(NSArray *)tmp {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:tmp forKey:@"allTimesNowFollowedTmp"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (NSArray *)getAllTimesNowFollowedTempIds { 
	if (![AcountUser sharedInstance].acountIdentifier) {
		return nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [dict objectForKey:@"allTimesNowFollowedTmp"];
}


- (void)setAllTimesNowFollowing:(NSInteger)value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"allTimesNowFollowingValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (NSInteger)getAllTimesNowFollowing {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"allTimesNowFollowingValue"] integerValue];
}

- (void)setAllTimesNowUnfollowing:(NSInteger)value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"allTimesNowUnfollowingValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];	
}

- (NSInteger)getAllTimesNowUnfollowing {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"allTimesNowUnfollowingValue"] integerValue];
} 

- (void)setRecentFollowing:(NSInteger) value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"recentNowFollowingValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (NSInteger)getRecentFollowing {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"recentNowFollowingValue"] integerValue];
}

- (void)setRecentUnFollowing:(NSInteger)value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"recentNowUnFollowingValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (NSInteger)getRecentUnFollowing {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"recentNowUnFollowingValue"] integerValue];
}

- (void)setAllTimesNowFollowingYou:(NSInteger)value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"allTimesNowFollowingYouValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (NSInteger)getAllTimesNowFollowingYou {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"allTimesNowFollowingYouValue"] integerValue];
}

- (void)setAllTimesNowUnfollowingYou:(NSInteger)value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"allTimesNowUnfollowingYouValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	
	[defaults synchronize];
}

- (NSInteger)getAllTimesNowUnfollowingYou {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"allTimesNowUnfollowingYouValue"] integerValue];
} 

- (void)setRecentFollowingYou:(NSInteger)value {
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"recentNowFollowingYouValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	
	[defaults synchronize];
}

- (NSInteger)getRecentFollowingYou {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"recentNowFollowingYouValue"] integerValue];
}

- (void)setRecentUnFollowingYou:(NSInteger)value {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:[NSNumber numberWithInteger:value] forKey:@"recentNowUnFollowingYouValue"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	
	[defaults synchronize];
}

- (NSInteger)getRecentUnFollowingYou {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [[dict objectForKey:@"recentNowUnFollowingYouValue"] integerValue];
}

#pragma mark - diff methods

- (NSInteger)allTimeFollowingDiff {
	
	NSMutableArray *followingArr = [[NSMutableArray alloc] init];
	NSInteger newCount = 0;
	
	NSArray *inital = [self getAllTimesNowFollowingTempIds];
	NSArray *now = [self getAllNowTimeFollowingIds];
	
	if (inital.count == 0) {
		return 0;
	} else {
		for (NSString *identifier in now) {
			if (![inital containsObject:identifier]) {
				newCount ++;
				[followingArr addObject:identifier];
			}
		}
	}
	[self setRecentFollowingIds:followingArr];
	return newCount;
}

- (NSInteger)allTimeUnfollowingDiff {
	NSMutableArray *unfollowingArr = [[NSMutableArray alloc] init];
	
	NSInteger newCount = 0;
	
	NSArray *inital = [self getAllTimesNowFollowingTempIds];
	NSArray *now = [self getAllNowTimeFollowingIds];
	
	if (inital.count == 0) {
		return 0;
	} else {
		for (NSString *identifier in inital) {
			if (![now containsObject:identifier]) {
				newCount ++;
				[unfollowingArr addObject:identifier];
			}
		}
	}
	[self setRecentUnfollowingIds:unfollowingArr];
	return newCount;
} 

- (NSInteger)allTimeFollowingYouDiff {
	NSMutableArray *followingYou = [[NSMutableArray alloc] init];
	NSInteger newCount = 0;
	
	NSArray *inital = [self getAllTimesNowFollowedTempIds];
	NSArray *now = [self getAllNowTimeFollowedIds];
	
	if (inital.count == 0) {
		return 0;
	} else {
		for (NSString *identifier in now) {
			if (![inital containsObject:identifier]) {
				newCount ++;
				[followingYou addObject:identifier];
			}
		}
	}
	[self setRecentFollowingYouIds:followingYou];
	return newCount;
}

- (NSInteger)allTimeUnfollowedDiff {
	NSMutableArray *unfolloweYouArr = [[NSMutableArray alloc] init];
	NSInteger newCount = 0;
	
	NSArray *inital = [self getAllTimesNowFollowedTempIds];
	NSArray *now = [self getAllNowTimeFollowedIds];
	
	if (inital.count == 0) {
		return 0;
	} else {
		for (NSString *identifier in inital) {
			if (![now containsObject:identifier]) {
				newCount ++;
				[unfolloweYouArr addObject:identifier];
			}
		}
	}
	[self setRecentUnfollowingYouIds:unfolloweYouArr];
	return newCount;
}


#pragma mark - history ids

- (NSArray *)getRecentFollowingIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [dict objectForKey:@"RecentFollowingIds"];
}

- (NSArray *)getRecentFollowingYouIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [dict objectForKey:@"RecentFollowingYouIds"];
}

- (NSArray *)getRecentUnfollowingIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [dict objectForKey:@"RecentUnfollowingIds"];
}

- (NSArray *)getRecentUnfollowingYouIds {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return 0;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	return [dict objectForKey:@"RecentUnfollowingYouIds"];
}

- (void)setRecentFollowingIds:(NSArray *)arr {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:arr forKey:@"RecentFollowingIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (void)setRecentFollowingYouIds:(NSArray *)arr {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:arr forKey:@"RecentFollowingYouIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];

}

- (void)setRecentUnfollowingIds:(NSArray *)arr {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:arr forKey:@"RecentUnfollowingIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}

- (void)setRecentUnfollowingYouIds:(NSArray *)arr {
	if (![AcountUser sharedInstance].acountIdentifier) {
		return;
	}
	NSMutableDictionary *mutableDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = (NSDictionary *)[defaults objectForKey:[AcountUser sharedInstance].acountIdentifier];
	if (!dict) {
		mutableDict = [[NSMutableDictionary alloc] init];
	} else {
		mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	[mutableDict setObject:arr forKey:@"RecentUnfollowingYouIds"];
	
	[defaults setObject:mutableDict forKey:[AcountUser sharedInstance].acountIdentifier];
	[defaults synchronize];
}


#pragma mark - notifications

- (void)followingUserIdsFinish:(NSNotification *)notification {
	dispatch_async(dispatch_get_main_queue(), ^{
	NSArray *allTimesNowIds = (NSArray *)[notification object];
	NSMutableArray *allTimesInitialIds = [[NSMutableArray alloc] initWithArray:[self getAllInitialTimeFollowingIds]];
	if (allTimesInitialIds.count == 0) {
		[self setAllTimesInitalFollowingIds:allTimesNowIds];
		[self setAllTimesNowFollowingIds:allTimesNowIds];
		[self setAllTimesNowFollowingTempIds:allTimesNowIds];
	} else {
		[self setAllTimesNowFollowingIds:allTimesNowIds];
		NSInteger unfollowDiff = [self allTimeUnfollowingDiff];
		NSInteger unfollowOld = [self getAllTimesNowUnfollowing];
		[self setRecentUnFollowing:unfollowDiff];
		
		[self setAllTimesNowUnfollowing:unfollowOld+unfollowDiff];
		
		NSInteger allTimeFollowingOld = [self getAllTimesNowFollowing];
		NSInteger nowDiff = [self allTimeFollowingDiff];
		
		[self setAllTimesNowFollowing:allTimeFollowingOld+nowDiff];
		
		[self setRecentFollowing:nowDiff];
		
		for (NSString *identifier in allTimesNowIds) {
			if (![allTimesInitialIds containsObject:identifier]) {
				[allTimesInitialIds addObject:identifier];
			}
		}
		[self setAllTimesInitalFollowingIds:allTimesInitialIds];
		[self setAllTimesNowFollowingTempIds:allTimesNowIds];
	}	
	});
}

- (void)stFollowedIdsFinish:(NSNotification *)notification {
	dispatch_async(dispatch_get_main_queue(), ^{
	NSArray *allTimesFollowedIds = (NSArray *)[notification object]; 
	NSMutableArray *allTimesInitialIds = [[NSMutableArray alloc] initWithArray:[self getAllInitialTimeFollowedIds]];

	if (allTimesInitialIds.count == 0) {
		[self setAllTimesInitalFollowedIds:allTimesFollowedIds];
		[self setAllTimesNowFollowedIds:allTimesFollowedIds];
		[self setAllTimesNowFollowedTempIds:allTimesFollowedIds];

	} else {
		[self setAllTimesNowFollowedIds:allTimesFollowedIds];
		NSInteger unfollowedYouDiff = [self allTimeUnfollowedDiff];
		NSInteger unfollowedYouOld = [self getAllTimesNowUnfollowingYou];
		
		[self setRecentUnFollowingYou:unfollowedYouDiff];
		
		[self setAllTimesNowUnfollowingYou:unfollowedYouOld+unfollowedYouDiff];
		
		NSInteger allTimeFollowingOld = [self getAllTimesNowFollowingYou];
		NSInteger nowDiff = [self allTimeFollowingYouDiff];
		
		[self setAllTimesNowFollowingYou:allTimeFollowingOld+nowDiff];
		[self setRecentFollowingYou:nowDiff];
		
		for (NSString *identifier in allTimesFollowedIds) {
			if (![allTimesInitialIds containsObject:identifier]) {
				[allTimesInitialIds addObject:identifier];
			}
		}
		[self setAllTimesInitalFollowedIds:allTimesInitialIds];
		[self setAllTimesNowFollowedTempIds:allTimesFollowedIds];
		
	}
	});
}


@end
