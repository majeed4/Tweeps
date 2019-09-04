//
//  TPRTwitterOperation.h
//  Tweepr
//
//  Created by Kamil Kocemba on 18/05/2013.
//
//

#import "TwitterUser.h"
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>

@interface TPRTwitterOperation : NSOperation

//@property (nonatomic, strong) ACAccount *account;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, assign) BOOL statusFinished;
@property (nonatomic, assign) BOOL statusExecuting;

//- (id)initWithAccount:(ACAccount *)account;
- (id)initWithUserID:(NSString *)userID;

@end
