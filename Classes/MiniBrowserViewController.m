//
//  MiniBrowserViewController.m
//  DigitalNZ
//
//  The MIT License
//
//  Copyright © 2010 National Library of New Zealand (www.natlib.govt.nz)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), 
//  to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
//  IN THE SOFTWARE.
//

#import "MiniBrowserViewController.h"
#import "DigitalNZAppDelegate.h"

@implementation MiniBrowserViewController
@synthesize contentUrl;
@synthesize scrollView;
@synthesize webBrowser;
@synthesize activityIndicator;


	//reload the page with the new content
- (void) reloadPage
{
	[activityIndicator startAnimating];
	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	NSMutableDictionary *theItem = [globalDelegate.dataSource objectAtIndex:globalDelegate.rowIndex];
	
	if (theItem != nil)
	{
		
		NSString *landingPage = [theItem objectForKey:@"source-url"];
		
		landingPage = [[landingPage componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] componentsJoinedByString: @""];
		landingPage = [[landingPage componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString: @""];
		
		[self setContentUrl:landingPage];
		
		if (contentUrl!= nil && [contentUrl length] > 0)
			[webBrowser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:contentUrl]]];
	}	
}
	//navigate back
- (IBAction) onNavigateBack:(id)sender
{
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	if (globalDelegate.rowIndex > 0)
	{
		globalDelegate.rowIndex--;
	}
	if (globalDelegate.rowIndex < 0)
		globalDelegate.rowIndex = 0;
	
	[self reloadPage];
	
}
	//navigate forward
- (IBAction) onNavigateForward:(id)sender
{
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	globalDelegate.rowIndex++;
	
	NSInteger total = [globalDelegate.dataSource count];
	if (total == 0)
	{		
		globalDelegate.rowIndex = 0;
	}
	if (globalDelegate.rowIndex >= total)
	{
		globalDelegate.rowIndex = total - 1;
	
	}
	[self reloadPage];
	
}

	//sends the link the the desired email address
- (IBAction)email:(id)sender{
	MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc]init];
	mailController.mailComposeDelegate = self;
	
	[mailController setSubject:@"Digital NZ Search"];
	
	[mailController setMessageBody:contentUrl isHTML:YES];
	[self presentModalViewController:mailController	animated:YES];
	[mailController release];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result 
						error:(NSError *)error
{
	[self dismissModalViewControllerAnimated:YES];
}

	// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
	contentUrl = [[NSString alloc] init];
    return self;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[activityIndicator stopAnimating];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[activityIndicator startAnimating];
	
	[super viewDidLoad];
	
	if (contentUrl!= nil && [contentUrl length] > 0)
		[webBrowser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:contentUrl]]];
	
	UIImage *headerImage = [UIImage imageNamed: @"DNZ_TRANSPARENT_BLACK_35.png"];
	UIImageView *headerImageView = [[UIImageView alloc] initWithImage: headerImage];
	
	self.navigationItem.titleView = headerImageView;
	[headerImageView release];
	
	[webBrowser scalesPageToFit];
	
	scrollView.contentSize = CGSizeMake(webBrowser.frame.size.width, webBrowser.frame.size.height);
	scrollView.maximumZoomScale = 4.0;
	scrollView.minimumZoomScale = 0.75;
	scrollView.clipsToBounds = YES;
	scrollView.delegate = self;
	scrollView.autoresizesSubviews = YES;
	webBrowser.delegate = self;
	
		//webBrowser.allowsInlineMediaPlayback = YES;
	[scrollView addSubview:webBrowser];	
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	
	return webBrowser;
}


- (void)didReceiveMemoryWarning {	
	[super didReceiveMemoryWarning];
	
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    
	webBrowser.delegate = nil;
	webBrowser = nil;
	
	[super viewDidUnload];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES; // support screen orientation
}

- (void)dealloc {
	[webBrowser release];
	[contentUrl release];
	[scrollView release];
	[activityIndicator release];
	

    [super dealloc];
}


@end
