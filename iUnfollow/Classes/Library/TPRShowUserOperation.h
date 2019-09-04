//
//  TPRShowUserOperation.h
//  Tweepr
//
//  Created by Kamil Kocemba on 12/06/2013.
//
//

#import "TPRTwitterOperation.h"

@interface TPRShowUserOperation : TPRTwitterOperation

//- (id)initWithTwitterUser:(TwitterUser *)user account:(ACAccount *)account;
- (id)initWithTwitterUser:(TwitterUser *)user userID:(NSString *)userID;

@end
