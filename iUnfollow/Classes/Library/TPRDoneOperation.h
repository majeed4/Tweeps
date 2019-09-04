//
//  TPRDoneOperation.h
//  Tweepr
//
//  Created by Kamil Kocemba on 11/05/2013.
//
//

@interface TPRDoneOperation : NSOperation

- (id)initWithBlock:(void(^)(void))completion;

@end
