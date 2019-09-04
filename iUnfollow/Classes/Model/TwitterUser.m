//
//  TwitterUser.m
//  Tweepr
//
//  Created by Kamil Kocemba on 27/05/2013.
//
//

#import "TwitterUser.h"
#import "Tweet.h"


@implementation TwitterUser

@dynamic biography;
@dynamic blocked;
@dynamic followed;
@dynamic following;
@dynamic fullName;
@dynamic identifier;
@dynamic lastTweetDate;
@dynamic numFavourites;
@dynamic numFollowers;
@dynamic numFollowing;
@dynamic numTweets;
@dynamic profileImageUrl;
@dynamic screenName;
@dynamic selected;
@dynamic timeStamp;
@dynamic userIdentifier;
@dynamic websiteUrl;
@dynamic tweets;
@dynamic hasDefaultImg;
@dynamic didTweet;
@dynamic retweets;
@dynamic userRetweets;
@dynamic isUnfollower;
@dynamic lastFollowedOn;
@dynamic lastFollowingOn;
@dynamic mentionedInTweets;
@dynamic tweetsMentioningUser;
@dynamic profileBackgroundUrl;

- (BOOL)hasDetails {
    return (self.screenName != nil);
}

@end
