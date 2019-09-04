//
//  TPRTweetOperation.h
//  Tweepr
//
//  Created by Kamil Kocemba on 12/06/2013.
//
//

#import "TPRTwitterOperation.h"

@interface TPRTweetOperation : TPRTwitterOperation

//- (id)initWithStatus:(NSString *)status account:(ACAccount *)account;
- (id)initWithStatus:(NSString *)status userID:(NSString *)userID;

@end
