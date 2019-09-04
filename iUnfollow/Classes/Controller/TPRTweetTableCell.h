//
//  TPRTweetTableCell.h
//  Tweepr
//
//  Created by Kamil Kocemba on 11/06/2013.
//
//

@interface TPRTweetTableCell : UITableViewCell

@property (nonatomic, strong) UILabel *retweetsLabel;
@property (nonatomic, strong) UILabel *screenNameLabel;
@property (nonatomic, strong) UILabel *mediaUrlLabel;
@property (nonatomic, strong) UIImageView *userImageView;
@property (nonatomic, strong) UIImageView *mediaImageView;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, assign) BOOL hasMedia;
@property (nonatomic, assign) BOOL showRetweets;
@property (nonatomic, assign) BOOL showDisclosureIndicator;
@property (nonatomic, assign) BOOL showPlayButton;

+ (CGFloat)heightWithText:(NSString *)text hasMedia:(BOOL)hasMedia;
+ (CGFloat)heightWithText:(NSString *)text hasMedia:(BOOL)hasMedia showRetweets:(BOOL)showRetweets;

@end
