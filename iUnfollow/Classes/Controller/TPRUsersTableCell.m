//
//  TPRUsersTableCell.m
//  Tweepr
//
//  Created by Kamil Kocemba on 14/06/2013.
//
//

#import "TPRUsersTableCell.h"

@interface TPRUsersTableCell ()

@property (nonatomic, strong) UIImageView *rightBackgroundView, *separatorView, *iconImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIImageView *smallSeparator, *rightBackgroundDivider;

@end

@implementation TPRUsersTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
        
        self.imageView.clipsToBounds = YES;
        
        BOOL isRightToLeft = [Utils isArabic];
        
        
        self.rightBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rt_bg"]];
        self.rightBackgroundDivider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_nar"]];
        
        self.retweetsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.retweetsLabel.font = [UIFont TPRFontWithSize:16];
        self.retweetsLabel.textColor = [UIColor blackColor];
        self.retweetsLabel.textAlignment = NSTextAlignmentCenter;
        self.retweetsLabel.backgroundColor = [UIColor clearColor];
        self.retweetsLabel.adjustsFontSizeToFitWidth = YES;
        
        self.screenNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.screenNameLabel.font = [UIFont TPRFontWithSize:14];
        self.screenNameLabel.textColor = [UIColor TPRBlueColor];
        self.screenNameLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.screenNameLabel];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.font = [UIFont TPRFontWithSize:18];
        self.nameLabel.textColor = [UIColor blackColor];
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.nameLabel];
        
        self.followersLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.followersLabel.font = [UIFont systemFontOfSize:11];
        self.followersLabel.textColor = [UIColor blackColor];
        self.followersLabel.backgroundColor = [UIColor clearColor];
        self.followersLabel.textAlignment = isRightToLeft ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [self addSubview:self.followersLabel];
        
        self.followingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.followingLabel.font = [UIFont systemFontOfSize:11];
        self.followingLabel.textColor = [UIColor blackColor];
        self.followingLabel.backgroundColor = [UIColor clearColor];
        self.followingLabel.textAlignment = isRightToLeft ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [self addSubview:self.followingLabel];
        
        self.checkBox = [[UIButton alloc] init];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:self.activityIndicator];
        
        self.backgroundColor = [UIColor TPRBackgroundColor];
        self.selectedBackgroundView = [[UIView alloc] init];
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure-indicator"]];
        
        self.separatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
        [self addSubview:self.separatorView];
        
        self.smallSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_nar"]];
        [self addSubview:self.smallSeparator];
        
        self.iconImageView = [[UIImageView alloc] init];
        self.iconImageView.contentMode = UIViewContentModeCenter;
        
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setLoaded:(BOOL)loaded
{
    if (loaded != self.loaded && loaded)
    {
        [self.activityIndicator stopAnimating];

        [UIView animateWithDuration:0.5 animations:^{
            
            self.activityIndicator.alpha = 0.0;
            self.nameLabel.alpha = 1.0;
            self.imageView.alpha = 1.0;
            self.retweetsLabel.alpha = 1.0;
            self.followingLabel.alpha = 1.0;
            self.followersLabel.alpha = 1.0;
            self.accessoryView.alpha = 1.0;
            self.screenNameLabel.alpha = 1.0;
            self.checkBox.alpha = 1.0;
            
        }];
    }
    else if (!loaded)
    {
        if (!self.activityIndicator.isAnimating)
        {
            [self.activityIndicator startAnimating];
        }
        self.activityIndicator.alpha = 1.0;
        self.nameLabel.alpha = 0.0;
        self.imageView.alpha = 0.0;
        self.retweetsLabel.alpha = 0.0;
        self.followingLabel.alpha = 0.0;
        self.followersLabel.alpha = 0.0;
        self.accessoryView.alpha = 0.0;
        self.screenNameLabel.alpha = 0.0;
        self.checkBox.alpha = 0.0;
    }

    _loaded = loaded;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(12, 10, 60, 60);
    
    self.activityIndicator.frame = CGRectMake(CGRectGetWidth(self.bounds) / 2 - 20, CGRectGetHeight(self.bounds) / 2 - 20, 40, 40);
    
    self.nameLabel.frame = CGRectMake(86, 9, 161, 21);
    self.screenNameLabel.frame = CGRectMake(86, 30, 118, 21);
    
    self.smallSeparator.frame = CGRectMake(86, 52, 162, 1);
    
    self.followingLabel.frame = CGRectMake(87, 54, 85, 21);
    self.followersLabel.frame = CGRectMake(175, 54, 85, 21);
    
    
    if ([Utils isArabic]) {
        self.followingLabel.frame = CGRectOffset(self.followingLabel.frame, -40, 0);
        self.followersLabel.frame = CGRectOffset(self.followersLabel.frame, -40, 0);
    }
    
    if (!self.showDisclosureIndicator) {
        self.accessoryView.frame = CGRectZero;
    }
    
    if (self.showCheckbox) {
        self.accessoryView.frame = CGRectZero;
        if (!self.checkBox.superview)
            [self addSubview:self.checkBox];
        self.checkBox.frame = CGRectMake(274, 26, 33, 33);
    } else {
        if (self.checkBox.superview)
            [self.checkBox removeFromSuperview];
    }
    
    if (self.showRetweetCount || self.showMentionsCount) {
        if (!self.rightBackgroundView.superview)
            [self addSubview:self.rightBackgroundView];
        
        if (!self.rightBackgroundDivider.superview)
            [self addSubview:self.rightBackgroundDivider];

        if (!self.retweetsLabel.superview)
            [self addSubview:self.retweetsLabel];

        if (!self.iconImageView.superview)
            [self addSubview:self.iconImageView];
        
        if (self.showRetweetCount)
            self.iconImageView.image = [UIImage imageNamed:@"rt_icon"];
        if (self.showMentionsCount)
            self.iconImageView.image = [UIImage imageNamed:@"mts_icon"];
        
        self.rightBackgroundView.frame = CGRectMake(320 - 45, 0, 45, CGRectGetHeight(self.bounds));
        self.rightBackgroundDivider.frame = CGRectMake(320 - 45 + 6, CGRectGetHeight(self.bounds) / 2 - 1, 33, 1);
        self.iconImageView.frame = CGRectMake(320 - 45, 0, 45, CGRectGetHeight(self.bounds) / 2);
        
        
        self.retweetsLabel.frame = CGRectMake(320 - 45, CGRectGetHeight(self.bounds) / 2, 45, CGRectGetHeight(self.bounds) / 2);
        self.accessoryView.frame = CGRectOffset(self.accessoryView.frame, -35, 0);
        
    } else {
        
        if (self.rightBackgroundView.superview)
            [self.rightBackgroundView removeFromSuperview];
        
        if (self.rightBackgroundDivider.superview)
            [self.rightBackgroundDivider removeFromSuperview];
        
        if (self.retweetsLabel.superview)
            [self.retweetsLabel removeFromSuperview];
        
        if (self.iconImageView.superview)
            [self.iconImageView removeFromSuperview];
    }
    
    self.separatorView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - 1, 320, 1);
    [self bringSubviewToFront:self.imageView];

}

@end
