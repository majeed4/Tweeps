//
//  TPRRetweetsOperation.h
//  Tweepr
//
//  Created by Kamil Kocemba on 31/05/2013.
//
//

#import "TPRTwitterOperation.h"
#import "UserTweet.h"

@interface TPRRetweetIdsOperation : TPRTwitterOperation

//- (id)initWithAccount:(ACAccount *)account tweet:(UserTweet *)tweet;
- (id)initWithUserID:(NSString *)userID tweet:(UserTweet *)tweet;

@end
