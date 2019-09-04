//
//  TPRRetweetsOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 31/05/2013.
//
//

#import "TPRRetweetsOperation.h"

@interface TPRRetweetsOperation ()

@property (nonatomic, strong) UserTweet *tweet;

@end

@implementation TPRRetweetsOperation

- (id)initWithUserID:(NSString *)userID tweet:(UserTweet *)tweet
{
    if ((self = [super initWithUserID:userID]))
    {
        self.tweet = tweet;
    }
    return self;
}

//- (id)initWithAccount:(ACAccount *)account
//                tweet:(UserTweet *)tweet
//{
//    if ((self = [super initWithAccount:account]))
//    {
//        self.tweet = tweet;
//    }
//    return self;
//}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [[[NetworkManager sharedInstance] twitterAPI] getStatusesRetweetsForID:self.tweet.tweetId count:@"100" trimUser:@0 successBlock:^(NSArray *statuses) {
        BOOL done = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            
            [dataManager updateRetweetsOfTweet:[self tweet]
                                    fullValues:statuses
                                     inContext:[dataManager mainThreadContext]];
            
            NSLog(@"Notification didFetchUserTweetsNotification");
            [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserTweetsNotification object:self];
            
        });
        
        if (done)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self willChangeValueForKey:@"isExecuting"];
                [self willChangeValueForKey:@"isFinished"];
                self.statusExecuting = NO;
                self.statusFinished = YES;
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];
                
            });
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

//- (void)start
//{
//    [self willChangeValueForKey:@"isExecuting"];
//    self.executing = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
//                                   @{ @"count" : @"100", @"trim_user" : @"false" }];
//    
//    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweets/%@.json", self.tweet.tweetId];
//    NSLog(@"%@", url);
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url]
//                                         parameters:params
//                                      requestMethod:TWRequestMethodGET];
//	req.account = self.account;
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//
//        BOOL done = YES;
//        NSError *err = nil;
//        NSArray *JSON = [NSJSONSerialization JSONObjectWithData:responseData
//                                                        options:0
//                                                          error:&err];
//
//        if ( ([JSON isKindOfClass:[NSArray class]]) && ([JSON count] > 0) )
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                DataManager *dataManager = [DataManager sharedInstance];
//
//                [dataManager updateRetweetsOfTweet:[self tweet]
//                                        fullValues:JSON
//                                         inContext:[dataManager mainThreadContext]];
//
//                NSLog(@"Notification didFetchUserTweetsNotification");
//                [[NSNotificationCenter defaultCenter] postNotificationName:didFetchUserTweetsNotification object:self];
//
//            });
//        }
//
//        if (done)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                [self willChangeValueForKey:@"isExecuting"];
//                [self willChangeValueForKey:@"isFinished"];
//                self.executing = NO;
//                self.finished = YES;
//                [self didChangeValueForKey:@"isExecuting"];
//                [self didChangeValueForKey:@"isFinished"];
//
//            });
//        }
//
//        if (error)
//        {
//            NSLog(@"%@", error);
//        }
//    }];
//}

@end
