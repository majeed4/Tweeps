//
//  TPRWebViewController
//  Tweepr
//

@protocol TPRWebViewControllerDelegate

- (void)didCloseWebViewController;

@end

@interface TPRWebViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *pageTitle;
@property (weak, nonatomic) id<TPRWebViewControllerDelegate> delegate;

@end
