//
//  DigitalNZAppDelegate.m
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

#import "DigitalNZAppDelegate.h"
#import "SearchViewController.h"


@implementation DigitalNZAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize dataSource;
@synthesize rowIndex;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    

	rowIndex = 0;
	
	dataSource = [[NSMutableArray alloc] init];
	
    // Override point for customization after application launch
	navigationController = [[UINavigationController alloc] init];
    SearchViewController *searchController = [[SearchViewController alloc] initWithNibName:@"SearchView" bundle:nil];
	
	[navigationController pushViewController:searchController animated:NO]; // show first view
	[searchController release];
	
	[window addSubview:navigationController.view];	
	[window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
	[navigationController release];
    [window release];
	[dataSource release];
	
	[super dealloc];
}


@end
