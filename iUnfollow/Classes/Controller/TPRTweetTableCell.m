//
//  TPRTweetTableCell.m
//  Tweepr
//
//  Created by Kamil Kocemba on 11/06/2013.
//
//

#import "TPRTweetTableCell.h"

@interface TPRTweetTableCell ()

@property (nonatomic, strong) UIImageView *mediaBackgroundView;
@property (nonatomic, strong) UIImageView *separatorView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *rightBackgroundView, *rightBackgroundDivider;

@end

@implementation TPRTweetTableCell

- (void)_configureCell {
    self.textLabel.numberOfLines = 0;
    self.textLabel.font = [UIFont TPRFontWithSize:13];
    self.textLabel.textColor = [UIColor blackColor];
    self.textLabel.backgroundColor = [UIColor clearColor];
    if ([Utils isArabic])
        self.textLabel.textAlignment = NSTextAlignmentRight;
    
    self.detailTextLabel.font = [UIFont TPRFontWithSize:11];
    self.detailTextLabel.textColor = [UIColor blackColor];
    self.detailTextLabel.highlightedTextColor = [UIColor TPRHighlightedTextColor];
    self.detailTextLabel.textAlignment = NSTextAlignmentRight;
    self.detailTextLabel.backgroundColor  = [UIColor clearColor];
    
    UILabel *mediaUrlLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    mediaUrlLabel.font = [UIFont TPRFontWithSize:11];
    mediaUrlLabel.textColor = [UIColor TPRDarkTextColor];
    mediaUrlLabel.textAlignment = NSTextAlignmentLeft;
    mediaUrlLabel.backgroundColor = [UIColor clearColor];
    mediaUrlLabel.adjustsFontSizeToFitWidth = YES;
    self.mediaUrlLabel = mediaUrlLabel;
    
    self.rightBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rt_bg"]];
    self.iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rt_icon"]];
    self.iconImageView.contentMode = UIViewContentModeCenter;
    self.rightBackgroundDivider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_nar"]];
    
    UILabel *retweetsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    retweetsLabel.backgroundColor = [UIColor clearColor];
    retweetsLabel.font = [UIFont TPRFontWithSize:16];
    retweetsLabel.textColor = [UIColor blackColor];
    retweetsLabel.textAlignment = NSTextAlignmentCenter;
    retweetsLabel.adjustsFontSizeToFitWidth = YES;
    self.retweetsLabel = retweetsLabel;
    
    UILabel *screenNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    screenNameLabel.font = [UIFont TPRFontWithSize:10];
    screenNameLabel.textColor = [UIColor TPRBlueColor];
    screenNameLabel.backgroundColor = [UIColor clearColor];
    screenNameLabel.textAlignment = NSTextAlignmentCenter;
    screenNameLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:screenNameLabel];
    self.screenNameLabel = screenNameLabel;
    
    UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [playButton setImage:[UIImage imageNamed:@"video-play"] forState:UIControlStateNormal];
    self.playButton = playButton;
    
    UIImageView *mediaBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"media-frame"]];
    self.mediaBackgroundView = mediaBackgroundView;
    
    self.clipsToBounds = YES;
    
    UIImageView *mediaImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.mediaImageView = mediaImageView;
    mediaImageView.clipsToBounds = YES;
    mediaImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.backgroundColor = [UIColor TPRBackgroundColor];
    
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.userImageView.clipsToBounds = YES;
    [self addSubview:self.userImageView];

    self.separatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
    [self addSubview:self.separatorView];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
        [self _configureCell];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self _configureCell];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.userImageView.frame = CGRectMake(18, 16, 50, 50);
    self.screenNameLabel.frame = CGRectMake(5, 72, 72, 10);
    [self bringSubviewToFront:self.userImageView];
    
    CGSize maxSize = CGSizeMake(320 - 90, CGFLOAT_MAX);
    if (self.showRetweets)
        maxSize = CGSizeMake(320 - 90 - 60, CGFLOAT_MAX);
    CGSize size = [self.textLabel.text sizeWithFont:[UIFont TPRFontWithSize:13] constrainedToSize:maxSize];
    
    self.textLabel.frame = CGRectMake(80, 10, size.width, size.height);
    self.detailTextLabel.frame = CGRectMake(CGRectGetWidth(self.bounds) - 140, CGRectGetHeight(self.bounds) - 24, 130, 20);
    
    if (self.showRetweets) {
        if (!self.retweetsLabel.superview)
            [self addSubview:self.retweetsLabel];
        if (!self.rightBackgroundDivider.superview)
            [self addSubview:self.rightBackgroundDivider];
        if (!self.rightBackgroundView.superview)
            [self addSubview:self.rightBackgroundView];
        [self bringSubviewToFront:self.rightBackgroundDivider];
        
        if (!self.iconImageView.superview)
            [self addSubview:self.iconImageView];
        
        self.rightBackgroundView.frame = CGRectMake(320 - 45, 0, 45, CGRectGetHeight(self.bounds));
        self.rightBackgroundDivider.frame = CGRectMake(320 - 45 + 6, CGRectGetHeight(self.bounds) / 2 - 1, 33, 1);
        self.iconImageView.frame = CGRectMake(320 - 45, 0, 45, CGRectGetHeight(self.bounds) / 2);
        self.retweetsLabel.frame = CGRectMake(320 - 45, CGRectGetHeight(self.bounds) / 2, 45, CGRectGetHeight(self.bounds) / 2);
        [self bringSubviewToFront:self.retweetsLabel];
        
        self.accessoryView.frame = CGRectOffset(self.accessoryView.frame, -36, 0);
        self.detailTextLabel.frame = CGRectOffset(self.detailTextLabel.frame, -40, 0);
    } else {
        [self.retweetsLabel removeFromSuperview];
        [self.rightBackgroundView removeFromSuperview];
        [self.rightBackgroundDivider removeFromSuperview];
        [self.iconImageView removeFromSuperview];
    }
        
    if (self.hasMedia) {
        
//        if (!self.imageView.superview)
//            [self addSubview:self.imageView];
        if (!self.mediaImageView.superview)
            [self addSubview:self.mediaImageView];
        if (!self.mediaBackgroundView.superview)
            [self insertSubview:self.mediaBackgroundView aboveSubview:self.backgroundView];
        if (!self.mediaUrlLabel.superview)
            [self addSubview:self.mediaUrlLabel];

        CGFloat offsetTop = MAX(CGRectGetMaxY(self.textLabel.frame) + 6, CGRectGetMaxY(self.screenNameLabel.frame) + 6);
        self.mediaBackgroundView.frame = CGRectMake(10, offsetTop, 300, 190);
        UIEdgeInsets backgroundInsets = UIEdgeInsetsMake(8, 10, 34, 10);
//        self.imageView.frame = UIEdgeInsetsInsetRect(self.mediaBackgroundView.frame, backgroundInsets);
        self.mediaImageView.frame = UIEdgeInsetsInsetRect(self.mediaBackgroundView.frame, backgroundInsets);

        CGFloat detailLabelOffset = -10;
        self.detailTextLabel.frame = CGRectOffset(self.detailTextLabel.frame, -10, detailLabelOffset);
        self.mediaUrlLabel.frame = CGRectMake(20, CGRectGetMinY(self.detailTextLabel.frame), 170, CGRectGetHeight(self.detailTextLabel.frame));

        [self bringSubviewToFront:self.mediaImageView];

        if (self.showPlayButton)
        {
            if (!self.playButton.superview)
            {
                [self addSubview:self.playButton];
            }
//            self.playButton.frame = self.imageView.frame;
            self.playButton.frame = self.mediaImageView.frame;
            [self bringSubviewToFront:self.playButton];
        }
        else
        {
            [self.playButton removeFromSuperview];
        }
        
    } else {
        [self.mediaBackgroundView removeFromSuperview];
//        [self.imageView removeFromSuperview];
        [self.mediaImageView removeFromSuperview];
        [self.mediaUrlLabel removeFromSuperview];
    }
    
    self.separatorView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - 1, 320, 1);
}

+ (CGFloat)heightWithText:(NSString *)text hasMedia:(BOOL)hasMedia showRetweets:(BOOL)showRetweets {
    CGSize maxSize = CGSizeMake(320 - 90, CGFLOAT_MAX);
    if (showRetweets)
        maxSize = CGSizeMake(320 - 90 - 60, CGFLOAT_MAX);
    CGSize size = [text sizeWithFont:[UIFont TPRFontWithSize:13] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
    size.height = MAX(size.height, 72);
    if (hasMedia)
        return size.height + 190 + 16 + 6;
    return size.height + 34;
}

+ (CGFloat)heightWithText:(NSString *)text hasMedia:(BOOL)hasMedia {
    return [TPRTweetTableCell heightWithText:text hasMedia:hasMedia showRetweets:NO];
}


@end
