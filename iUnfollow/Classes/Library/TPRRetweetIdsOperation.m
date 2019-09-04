//
//  TPRRetweetsOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 31/05/2013.
//
//

#import "TPRRetweetIdsOperation.h"

@interface TPRRetweetIdsOperation ()

@property (nonatomic, strong) UserTweet *tweet;

@end

@implementation TPRRetweetIdsOperation

- (id)initWithUserID:(NSString *)userID tweet:(UserTweet *)tweet {
    if ((self = [super initWithUserID:userID])) {
        self.tweet = tweet;
    }
    return self;
}

//- (id)initWithAccount:(ACAccount *)account tweet:(UserTweet *)tweet {
//    if ((self = [super initWithAccount:account])) {
//        self.tweet = tweet;
//    }
//    return self;
//}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self getRetweetsWithCursor:nil];
}

- (void)getRetweetsWithCursor:(NSString *)cursor
{
    if (!cursor.length)
        cursor = @"-1";
    NSLog(@"Retweeters: %@", cursor);
    
    [[[NetworkManager sharedInstance] twitterAPI] getStatusesRetweetersIDsForStatusID:self.tweet.tweetId cursor:cursor successBlock:^(NSArray *ids, NSString *previousCursor, NSString *nextCursor) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            
            [dataManager updateRetweetsOfTweet:[self tweet]
                                        values:ids
                                     inContext:[dataManager mainThreadContext]];
            
            if (nextCursor && ![nextCursor isEqualToString:@"0"])
            {
                [self getRetweetsWithCursor:nextCursor];
            }
            else
            {
                [self willChangeValueForKey:@"isExecuting"];
                [self willChangeValueForKey:@"isFinished"];
                self.statusExecuting = NO;
                self.statusFinished = YES;
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];
            }
            
        });
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

//- (void)getRetweetsWithCursor:(NSString *)cursor {
//    if (!cursor.length)
//        cursor = @"-1";
//    NSLog(@"Retweeters: %@", cursor);
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
//                                   @{ @"id" : self.tweet.tweetId, @"cursor" : @"cursor", @"stringify_ids" : @"true" }];
//    
//    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweeters/ids.json"];
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url] parameters:params  requestMethod:TWRequestMethodGET];
//	req.account = self.account;
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        NSError *err = nil;
//        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&err];
//        NSString *nextCursor = [[JSON objectForKey:@"next_cursor"] description];
//        NSArray *ids = [JSON objectForKey:@"ids"];
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            DataManager *dataManager = [DataManager sharedInstance];
//
//            [dataManager updateRetweetsOfTweet:[self tweet]
//                                        values:ids
//                                     inContext:[dataManager mainThreadContext]];
//
//            if (nextCursor && ![nextCursor isEqualToString:@"0"])
//            {
//                [self getRetweetsWithCursor:nextCursor];
//            }
//            else
//            {
//                [self willChangeValueForKey:@"isExecuting"];
//                [self willChangeValueForKey:@"isFinished"];
//                self.executing = NO;
//                self.finished = YES;
//                [self didChangeValueForKey:@"isExecuting"];
//                [self didChangeValueForKey:@"isFinished"];
//            }
//
//        });
//        if (error)
//            NSLog(@"%@", error);
//    }];
//}

@end
