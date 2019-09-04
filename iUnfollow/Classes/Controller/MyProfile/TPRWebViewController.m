//
//  TPRWebViewController.m
//  Tweepr
//

#import "TPRWebViewController.h"

@interface TPRWebViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation TPRWebViewController

@synthesize activityIndicator;
@synthesize webView,pageTitle,url;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.view = self.webView;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.center = self.view.center;
    [self.view addSubview:self.activityIndicator];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self.navigationController action:@selector(dismissModalViewControllerAnimated:)];
    
	if (self.pageTitle)
    {
		self.title = self.pageTitle;
	}
    else
    {
		self.title = self.url;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.url]]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.webView stopLoading];
	[self.activityIndicator stopAnimating];
	self.webView.delegate = nil;
	[self.webView stopLoading];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

	self.webView = nil;
	[self setActivityIndicator:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - web view delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //NSLog(@"%@", webView.request.HTTPBody);
	[self.activityIndicator stopAnimating];
}

- (void)closeLoginViewController {
    [self.delegate didCloseWebViewController];
}

@end
