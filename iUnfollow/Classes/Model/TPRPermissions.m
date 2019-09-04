//
//  TPRPermissions.m
//  Tweepr
//

#import "TPRPermissions.h"

@implementation TPRPermissions

@synthesize applicationLimit,applicationRemaining;
@synthesize userDetailsLimit,userDetailsRemaining;
@synthesize usersLookupLimit,usersLookupRemaining;
@synthesize followingIdsLimit,followingIdsRemaining;
@synthesize followersIdsLimit,followersIdsRemaining;
@synthesize friendshipsOutgoingLimit,friendshipsOutgoingRemaining;

@synthesize description;

+ (TPRPermissions *)sharedInstance {
	static TPRPermissions *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[TPRPermissions alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	self = [super init]; 
	if (self) {
		self.applicationLimit = 0;
		self.applicationRemaining = 0;
		self.userDetailsLimit = 0;
		self.userDetailsRemaining = 0;
		self.usersLookupLimit = 0;
		self.usersLookupRemaining = 0;
		self.followersIdsLimit = 0;
		self.followingIdsRemaining = 0;
		self.followersIdsLimit = 0;
		self.followersIdsRemaining = 0;
		self.friendshipsOutgoingLimit = 0;
		self.friendshipsOutgoingRemaining = 0;
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"\n application remaining = %ld application limit = %ld\n user details remaining = %ld user details limit %ld\n userlookup remainig =%ldd userlookup limit = %ld\n following ids remaining = %ld following ids limit %ld\n followers ids remaining = %ld, followers ids limit%ld\n outgoing friendships remaining = %ld outgoing friendships limit =  %ld\n",
			(long)self.applicationRemaining,(long)self.applicationLimit,
			(long)self.userDetailsRemaining,(long)self.userDetailsLimit,
			(long)self.usersLookupRemaining,(long)self.usersLookupLimit,
			(long)self.followingIdsRemaining,(long)self.followingIdsLimit,
			(long)self.followersIdsRemaining,(long)self.followersIdsLimit,
			(long)self.friendshipsOutgoingRemaining,(long)self.friendshipsOutgoingLimit];
}

- (BOOL)canMakeLimitReq {
	if (self.applicationLimit == 0) {
		return YES;
	}
	if (self.applicationRemaining == 0) {
		return NO;
	}
	self.applicationRemaining = self.applicationRemaining - 1;
	return YES;
}

- (BOOL)canMakeUserDetailsReq {
	if (self.userDetailsLimit == 0) {
		return YES;
	}
	if (self.userDetailsRemaining == 0) {
		return NO;
	}
	self.userDetailsRemaining = self.userDetailsRemaining - 1;
	return YES;
}

- (BOOL)canMakeUserLookupReq
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	if (self.usersLookupLimit == 0)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Lookup limit is zero", self, __PRETTY_FUNCTION__);
		return YES;
	}
    
	if (self.usersLookupRemaining == 0)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - No lookups remaining", self, __PRETTY_FUNCTION__);
		return NO;
	}
    
	self.usersLookupRemaining = self.usersLookupRemaining - 1;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
	return YES;
}

- (BOOL)canMakeFollowersReq {
	if (self.followersIdsLimit == 0) {
		return YES;
	}
	if (self.followersIdsRemaining == 0) {
		return NO;
	}
	self.followersIdsRemaining = self.followersIdsRemaining - 1;
	return YES;
}

- (BOOL)canMakeFollowingReq {
	if (self.followingIdsLimit == 0) {
		return YES;
	}
	if (self.followingIdsRemaining == 0) {
		return NO;
	}
	self.followingIdsRemaining = self.followingIdsRemaining - 1;
	return YES;
}

- (BOOL)canMakeFriendshipOutgoingReq {
	if (self.friendshipsOutgoingLimit == 0) {
		return YES;
	}
	if (self.friendshipsOutgoingRemaining == 0) {
		return NO;
	} 
	self.friendshipsOutgoingRemaining = self.friendshipsOutgoingRemaining - 1;
	return YES;
}

@end
