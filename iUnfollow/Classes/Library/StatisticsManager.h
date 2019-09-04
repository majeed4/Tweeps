//
//  StatisticsManager.h
//  iUnfollow
//
//  Created by Andrei Salanta on 1/16/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatisticsManager : NSObject

+ (StatisticsManager *)sharedInstance;


- (void)setAllTimesInitalFollowingIds:(NSArray *)array;
- (void)setAllTimesNowFollowingIds:(NSArray *)array;

- (NSInteger)getAllTimesNowFollowing;
- (NSInteger)getAllTimesNowUnfollowing;
- (NSInteger)getRecentUnFollowing;
- (NSInteger)getRecentFollowing;

- (NSInteger)getAllTimesNowFollowingYou;
- (NSInteger)getAllTimesNowUnfollowingYou;
- (NSInteger)getRecentUnFollowingYou;
- (NSInteger)getRecentFollowingYou;


- (NSArray *)getRecentFollowingIds;
- (NSArray *)getRecentFollowingYouIds;
- (NSArray *)getRecentUnfollowingIds;
- (NSArray *)getRecentUnfollowingYouIds;

@end
