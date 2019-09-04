//
//  TPRUnblockOperation.h
//  Tweepr
//
//  Created by Kamil Kocemba on 04/06/2013.
//
//

#import "TPRTwitterOperation.h"

@interface TPRUnblockOperation : TPRTwitterOperation

//- (id)initWithTwitterUser:(TwitterUser *)user account:(ACAccount *)account;
- (id)initWithTwitterUser:(TwitterUser *)user userID:(NSString *)userID;
@end
