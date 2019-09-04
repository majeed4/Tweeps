//
//  TPRMentionsOperation.m
//  Tweepr
//
//  Created by Kamil Kocemba on 14/06/2013.
//
//

#import "TPRMentionsOperation.h"

@implementation TPRMentionsOperation

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.statusExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self getMentionsOlderThan:nil];
}

- (void)getMentionsOlderThan:(NSString *)maxId
{
    NSLog(@"Mentions: %@", maxId);
    
    [[[NetworkManager sharedInstance] twitterAPI] getStatusesMentionTimelineWithCount:@"200" sinceID:nil maxID:maxId trimUser:@0 contributorDetails:nil includeEntities:@0 successBlock:^(NSArray *statuses) {
        BOOL done = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DataManager *dataManager = [DataManager sharedInstance];
            
            [dataManager updateUserMentions:statuses
                                  inContext:[dataManager mainThreadContext]];
            
        });
        NSDictionary *maxUser = [statuses lastObject];
        NSString *nextId = maxUser[@"id_str"];
        if (nextId.length && ![maxId isEqualToString:nextId]) {
            done = NO;
            [self getMentionsOlderThan:nextId];
        }
        
        if (done) {
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

//- (void)getMentionsOlderThan:(NSString *)maxId {
//    NSLog(@"Mentions: %@", maxId);
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
//                                   @{ @"count" : @"200", @"trim_user" : @"false", @"include_rts" : @"false", @"include_entities" : @"false" }];
//    if (maxId)
//        params[@"max_id"] = maxId;
//    
//    NSString *url = @"https://api.twitter.com/1.1/statuses/mentions_timeline.json";
//    TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url] parameters:params  requestMethod:TWRequestMethodGET];
//	req.account = self.account;
//    
//    [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        BOOL done = YES;
//        NSError *err = nil;
//        NSArray *JSON = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&err];
//        if ([JSON isKindOfClass:[NSArray class]] && JSON.count) {
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                DataManager *dataManager = [DataManager sharedInstance];
//
//                [dataManager updateUserMentions:JSON
//                                      inContext:[dataManager mainThreadContext]];
//
//            });
//            
//            NSDictionary *maxUser = [JSON lastObject];
//            NSString *nextId = [[maxUser objectForKey:@"id_str"] description];
//            if (nextId.length && ![maxId isEqualToString:nextId]) {
//                done = NO;
//                [self getMentionsOlderThan:nextId];
//            }
//        }
//        if (done) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self willChangeValueForKey:@"isExecuting"];
//                [self willChangeValueForKey:@"isFinished"];
//                self.executing = NO;
//                self.finished = YES;
//                [self didChangeValueForKey:@"isExecuting"];
//                [self didChangeValueForKey:@"isFinished"];
//            });
//        }
//        if (error)
//            NSLog(@"%@", error);
//    }];
//}

@end
