//
//  TPRUnfollowOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 11/05/2013.
//
//

#import "TPRUnfollowOperation.h"

@interface TPRUnfollowOperation ()

@property (nonatomic, strong) TwitterUser *user;

@end

@implementation TPRUnfollowOperation

- (id)initWithTwitterUser:(TwitterUser *)user {
    if ((self = [super initWithUserID:user.identifier])) {
        self.user = user;
    }
    return self;
}

//- (id)initWithTwitterUser:(TwitterUser *)user account:(ACAccount *)account {
//    if ((self = [super initWithAccount:account])) {
//        self.user = user;
//    }
//    return self;
//}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    [[[NetworkManager sharedInstance] twitterAPI] postFriendshipsDestroyScreenName:self.user.screenName orUserID:self.user.identifier successBlock:^(NSDictionary *unfollowedUser) {
        [self willChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.statusExecuting = NO;
        self.statusFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
        NSLog(@"Unfollowed user: %@", self.user.screenName);
    } errorBlock:^(NSError *error) {
        NSLog(@"Unable to follow user %@: %@", self.user.screenName, error.localizedDescription);
    }];
}

//- (void)start2 {
//    NSString *url = @"https://api.twitter.com/1.1/friendships/destroy.json";
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url]
//										 parameters:@{ @"screen_name" : self.user.screenName }
//									  requestMethod:TWRequestMethodPOST];
//    req.account = self.account;
//    
//    [self willChangeValueForKey:@"isExecuting"];
//    self.executing = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        
//        [self willChangeValueForKey:@"isExecuting"];
//        [self willChangeValueForKey:@"isFinished"];
//        self.executing = NO;
//        self.finished = YES;
//        [self didChangeValueForKey:@"isExecuting"];
//        [self didChangeValueForKey:@"isFinished"];
//        NSLog(@"Unfollowed user: %@", self.user.screenName);
//    }];
//}

@end
