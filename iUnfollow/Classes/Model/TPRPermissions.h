//
//  TPRPermissions.h
//  Tweepr
//

@interface TPRPermissions : NSObject

+ (TPRPermissions *)sharedInstance;

@property NSInteger userDetailsLimit;
@property NSInteger userDetailsRemaining;

@property NSInteger friendshipsOutgoingLimit;
@property NSInteger friendshipsOutgoingRemaining;

@property NSInteger applicationLimit;
@property NSInteger applicationRemaining;

@property NSInteger followersIdsLimit;
@property NSInteger followersIdsRemaining;

@property NSInteger followingIdsLimit;
@property NSInteger followingIdsRemaining;

@property NSInteger usersLookupLimit;
@property NSInteger usersLookupRemaining;

@property (strong, nonatomic) NSString *description;

- (BOOL)canMakeLimitReq;
- (BOOL)canMakeUserDetailsReq;
- (BOOL)canMakeFriendshipOutgoingReq;
- (BOOL)canMakeFollowersReq;
- (BOOL)canMakeFollowingReq;
- (BOOL)canMakeUserLookupReq;

@end
