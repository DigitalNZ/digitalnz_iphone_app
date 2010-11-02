//
//  SearchViewController.m
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


#import "SearchViewController.h"
#import "AsyncImageView.h"   
#import "MiniBrowserViewController.h"
#import "AboutViewController.h"
#import "Reachability.h"
#import "DigitalNZAppDelegate.h"


@implementation SearchViewController
//@synthesize dataSource;
@synthesize imageView,activityIndicator;
@synthesize totalResults,totalResultString, searchEntry,queue;
@synthesize pageOffset;
@synthesize search;
@synthesize searchResultsTable;
@synthesize IsConnected;

NSString * const const_Title = @"title";
NSString * const const_SourceUrl = @"source-url";
NSString * const const_Summary = @"description";
NSString * const const_Thumbnail = @"thumbnail-url";
NSString * const const_ContentProvider = @"content-provider";
NSString * const const_Category = @"category";
NSString * const const_Date = @"date";
NSString * const const_ResultCount = @"result-count";

// detect orientation
- (void)orientationDidChange:(NSNotification *)note
{
	[self setRotatingImages];
}
- (void) setRotatingImages
{
	if ([imageView isHidden] == NO)
	{	
		UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			// The device is an iPad running iPhone 3.2 or later.
			if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown)
			{
				imageView.animationImages = [NSArray arrayWithObjects:
											 [UIImage imageNamed:@"ipad-portrait-haeremai.jpg"], nil];
				
			}
			else if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight){
				imageView.animationImages = [NSArray arrayWithObjects:
											 [UIImage imageNamed:@"ipad-landscape-haeremai.jpg"], nil];
				
			}		
			
		} else {
			if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown)
			{
				imageView.animationImages = [NSArray arrayWithObjects:
											 [UIImage imageNamed:@"iphone-portrait-haeremai.jpg"], nil];
				
			}
			else if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight){
				imageView.animationImages = [NSArray arrayWithObjects:
											 [UIImage imageNamed:@"iphone-landscape-haeremai.jpg"], nil];
				
			}
		}

		[imageView startAnimating];
				
	}
	
}

- (void)viewWillAppear:(BOOL)animated
{
	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	if (globalDelegate.rowIndex >= 0 && globalDelegate.rowIndex < [globalDelegate.dataSource count])
	{
		if(totalResults==0){
			totalResults = [totalResultString intValue];
			search.text = searchEntry;
		}
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:globalDelegate.rowIndex inSection:0];
		[searchResultsTable	reloadData];	
		[searchResultsTable selectRowAtIndexPath:indexPath
										animated:NO
								  scrollPosition:UITableViewScrollPositionBottom];
		
	}
	[self setRotatingImages];
	
	
}

#pragma mark -
#pragma mark Reachability
//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateConnectivityStatus: curReach];
}
- (void) updateConnectivityStatus: (Reachability*) curReach
{
	NetworkStatus netStatus = [curReach currentReachabilityStatus];
	BOOL connectionRequired= [curReach connectionRequired];
	
	if(curReach == hostReach)
	{
		IsConnected = connectionRequired ? NO : YES;
    }
	
	if (curReach == internetReach || curReach == wifiReach)
	{	
		switch (netStatus)
		{
			case NotReachable:
			{
				IsConnected = NO;
				break;
			}
				
			case ReachableViaWWAN:
			{
				IsConnected = YES;
				break;
			}
			case ReachableViaWiFi:
			{
				IsConnected = YES;
				break;
			}
		}
	}
}

// handle the info button click trigger from the UINavigationController icon
- (void)onInfoClicked:(UIButton *)button
{
	AboutViewController *about = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
	[self.navigationController pushViewController:about animated:YES];
	[about release];
}

#pragma mark -
#pragma mark Custom Actions
- (void)doSearch:(NSString *)searchTerm
{		
	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	globalDelegate.dataSource = [[NSMutableArray alloc] init];
	
	self.totalResults = 0;
	self.pageOffset = 0;
	
	[imageView setHidden:YES];
	searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
	//create multithreading operation for the search so the interface doesn't stall with slow connections
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performSearch:) object:searchTerm];
	[queue addOperation:operation];
	[queue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:NULL];
	[operation release];
	
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//if it gets an observer call check if it was from the multithread queue
	if(object == queue &&[@"operations" isEqual: keyPath]){
		//if it was, check that the queue is empty (the seccond thread has finished running)
		NSArray *operations = [change objectForKey:NSKeyValueChangeNewKey];
		if(![self hasActiveOperations: operations]){
			[activityIndicator stopAnimating];
			//refresh the interface from the main thread
			[self performSelectorOnMainThread:@selector(refreshDisplay) withObject:nil waitUntilDone:NO];
		}
	}
}
//checking wheather there are threads in the queue
-(BOOL) hasActiveOperations:(NSArray *)operations{
	for(id operation in operations){
			return YES;
	}
	return NO;
}

-(void)refreshDisplay
{
	
	//wait a fraction of a seccond to let the multithread finish then refresh the table to show images.
	[NSThread sleepForTimeInterval:0.1];
	[searchResultsTable reloadData];
	
}
-(void)performSearch:(NSString *)searchTerm //currentPage:(NSInteger *)currentPage 
{
	
	if (!IsConnected)
	{
		UIAlertView * alert = [[UIAlertView alloc]
							   initWithTitle:@"Internet Connection" 
							   message:@"This device is currently disconnected from the internet." 
							   delegate:self 
							   cancelButtonTitle:@"OK" 
							   otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;	
		
	}
	NSString * encodedParam =  [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *urlString = [NSString stringWithFormat: 
						   @"http://api.digitalnz.org/records/v1.xml/?search_text=%@&start=%i&num_results=%i&api_key=%@", 
						   encodedParam, 
						   self.pageOffset,
						   constPageSize,
						   constApiKey];
	
	[self parseXMLFileAtURL:urlString];	
}

#pragma mark -
#pragma mark Search Bar Delegate Methods
-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar endEditing:YES];
	
	NSString *searchTerm = [searchBar text];
	searchEntry = [searchBar text];
	[searchEntry retain];
	
	[activityIndicator startAnimating];
	[self doSearch:searchTerm];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if ([searchText length] == 0)
	{
		DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
		
		globalDelegate.dataSource = [[NSMutableArray alloc] init];
		
		self.totalResults = 0;
		self.pageOffset = 0;
		
		[searchResultsTable reloadData];
		
	}
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	[searchBar endEditing:YES];
	
	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	globalDelegate.dataSource = [[NSMutableArray alloc] init];
	
	self.totalResults = 0;
	self.pageOffset = 0;
	
	[searchResultsTable reloadData];
	
}

#pragma mark -
#pragma mark Table View Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}
- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection:(NSInteger *)section
{	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	// used by the table - asks how many rows are in a section
	if ([globalDelegate.dataSource count] == 0){
		return 1;
		
	} else if ([globalDelegate.dataSource count] < self.totalResults-1) {
		
		// Add an object to the end of the array for the "Load more..." table cell.
		return [globalDelegate.dataSource count] + 1;
		
		
	}	
	// Return the number of rows as there are in the searchResults array.
	return [globalDelegate.dataSource count];
	
}

-(UITableViewCell *)tableView:(UITableView *)tableView
		cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"In cellForRowAtIndexPath with index: %i",indexPath.row);
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	// called by table view when it needs to draw one of its rows.  
	static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
	NSInteger total = [globalDelegate.dataSource count];
	
	if ([globalDelegate.dataSource count] == 0){ 
		// Disable user interaction for this cell.
		UITableViewCell *cell = [[[UITableViewCell alloc] init] autorelease]; 
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;		
	} 
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
									   reuseIdentifier:SimpleTableIdentifier] autorelease];
	}
	else {
		AsyncImageView *oldImage = (AsyncImageView *) [cell.contentView viewWithTag:999];
		if (oldImage !=nil)
			[oldImage removeFromSuperview];
	}	
	
	// show more results 
	if (indexPath.row == total && total < totalResults-1){ // Special Case 2		
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text = @"Load More Results...";
		cell.indentationLevel = 8;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%i results match your search criteria", totalResults];
	}
	else {
		
#ifdef __IPHONE_3_0
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
#endif
		
		NSUInteger row = [indexPath row];	
		
		NSMutableDictionary *theItem = [globalDelegate.dataSource objectAtIndex:row];
		if (theItem == nil)
		{
			return cell;
		}
		
		
		
		
		NSString *thumbnail = [theItem objectForKey:const_Thumbnail];
		thumbnail = [[thumbnail componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] componentsJoinedByString: @""];
		thumbnail = [[thumbnail componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString: @""];
		
		NSString *cellValue = [theItem objectForKey:const_Title];
		
		cell.textLabel.text = cellValue;
		cell.indentationLevel = 8;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
		
		NSString *desc = [theItem objectForKey:const_Summary];
		NSString *displayString = @"";
		if ([desc length] > 150)
		{
			displayString = [NSString stringWithFormat:@"%@.", [desc substringToIndex:149]];	
		}
		else {
			displayString = desc;
		}
		
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\nProvider:%@",
									 displayString,
									 [theItem objectForKey:const_ContentProvider]];
		
		//stringWithFormat [theItem objectForKey:@"content-provider"];
		cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
		cell.detailTextLabel.numberOfLines = 3;
		
		CGRect frame;
		frame.size.width=75; frame.size.height=75;
		frame.origin.x=5; frame.origin.y=0;
		AsyncImageView* asyncImage = [[[AsyncImageView alloc]
									   initWithFrame:frame] autorelease];
		asyncImage.tag = 999;
		NSURL *url = [NSURL URLWithString:thumbnail];
		
		[asyncImage loadImageFromURL:url];
		
		[cell.contentView addSubview:asyncImage];
		
	}
	// alternate row colors
	
	searchResultsTable.backgroundColor = [UIColor whiteColor];
	if (indexPath.row % 2)
	{
		
		[cell setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0.5]];
	}
	else 
	{
		[cell setBackgroundColor:[UIColor colorWithHue:0.3 saturation:0.5 brightness:1.0 alpha:0.5]];
	}
	
	return cell;
}

//make the cell height large
-(CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 80;
}
// table row selection
- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	if ([globalDelegate.dataSource count] == 0)
	{
		return;
	}
	
	[search endEditing:YES];
	
	NSInteger total = [globalDelegate.dataSource count];
	if (indexPath.row == total && total < (totalResults - 1) )
	{	
		
		self.pageOffset = (NSInteger*) [globalDelegate.dataSource count] + 1;
		
		//search.text currentPage:pageOffset];
		
		[activityIndicator startAnimating];
		
		queue = [NSOperationQueue new];
		[queue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:NULL];
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performSearch:) object:search.text];
		[queue addOperation:operation];
		[operation release];
		//[self performSearch:search.text]; //currentPage:pageOffset];
		
	}
	else {
		NSMutableDictionary *theItem = [globalDelegate.dataSource objectAtIndex:indexPath.row];
		
		if (theItem != nil)
		{
			
			NSString *landingPage = [theItem objectForKey:const_SourceUrl];
			
			landingPage = [[landingPage componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] componentsJoinedByString: @""];
			landingPage = [[landingPage componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString: @""];
			
			MiniBrowserViewController *browserController = [[MiniBrowserViewController alloc] initWithNibName:@"MiniBrowserView" bundle:nil];
			[globalDelegate setRowIndex:indexPath.row];
			//[browserController setRowIndex:indexPath.row];
			browserController.contentUrl = landingPage;
			[self.navigationController pushViewController:browserController animated:YES];
			
		}
	}	
}

-(void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	
	
	if ([globalDelegate.dataSource count] == 0 || indexPath.row == [globalDelegate.dataSource count])
	{
		return;
	}
	
	NSMutableDictionary *theItem = [globalDelegate.dataSource objectAtIndex:indexPath.row];
	if (theItem == nil)
	{
		return;
	}
	
	NSString *landingPage = [theItem objectForKey:const_SourceUrl];
	
	landingPage = [[landingPage componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] componentsJoinedByString: @""];
	landingPage = [[landingPage componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString: @""];
	
	MiniBrowserViewController *browserController = [[MiniBrowserViewController alloc] initWithNibName:@"MiniBrowserView" bundle:nil];
	browserController.contentUrl = landingPage;
	[self.navigationController pushViewController:browserController animated:YES];
	
	
}

#pragma mark -
#pragma mark XML Parser		 
- (void)parseXMLFileAtURL:(NSString *)URL
{			
	//you must then convert the path to a proper NSURL or it won't work
	NSURL *xmlURL = [NSURL URLWithString:URL];
	
	// here, for some reason you have to use NSClassFromString when trying to alloc NSXMLParser, otherwise you will get an object not found error
	// this may be necessary only for the toolchain
	rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
	
	// Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
	[rssParser setDelegate:self];
	
	// Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
	[rssParser setShouldProcessNamespaces:NO];
	[rssParser setShouldReportNamespacePrefixes:NO];
	[rssParser setShouldResolveExternalEntities:NO];
	
	[rssParser parse];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSString * errorString = [NSString stringWithFormat:@"Search failed (Error code %i )", [parseError code]];
	//NSLog(@"error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
	currentElement = [elementName copy];
	if ([elementName isEqualToString:@"result"]) {
		// clear out our story item caches...
		item = [[NSMutableDictionary alloc] init];
		currentTitle = [[NSMutableString alloc] init];
		currentSummary = [[NSMutableString alloc] init];
		currentLink = [[NSMutableString alloc] init];
		currentThumbnail = [[NSMutableString alloc] init];
		currentCategory = [[NSMutableString alloc] init];
		currentContentProvider = [[NSMutableString alloc] init];
		currentDate = [[NSMutableString alloc] init];
		
	}
	
	
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
	if ([elementName isEqualToString:@"result"]) {
		// save values to an item, then store that item into the array...
		[item setObject:currentTitle forKey:const_Title];
		[item setObject:currentLink forKey:const_SourceUrl];
		[item setObject:currentSummary forKey:const_Summary];
		[item setObject:currentThumbnail forKey:const_Thumbnail];
		[item setObject:currentContentProvider forKey:const_ContentProvider];
		[item setObject:currentCategory forKey:const_Category];
		[item setObject:currentDate forKey:const_Date];
		
		DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
		[globalDelegate.dataSource addObject:[item copy]];
		
		//NSLog(@"adding results: %@", currentTitle);
	}
	
}
// Xml parse found characters
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	
	// save the characters for the current item...
	if ([currentElement isEqualToString:const_Title]) {
		[currentTitle appendString:string];		
		
	} else if ([currentElement isEqualToString:const_SourceUrl]) {
		[currentLink appendString:string];
		
	} else if ([currentElement isEqualToString:const_Summary]) {
		[currentSummary appendString:string];
		
	} else if ([currentElement isEqualToString:const_Category]) {
		[currentCategory appendString:string];
		
	} else if ([currentElement isEqualToString:const_Thumbnail]) {
		[currentThumbnail appendString:string];
		
	} else if ([currentElement isEqualToString:const_ContentProvider]) {
		[currentContentProvider appendString:string];
		
	} else if ([currentElement isEqualToString:const_Date]){
		[currentDate appendString:string];
	} else if ([currentElement isEqualToString:const_ResultCount]) {
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] ];
		if ([(NSString *)string length] > 0)
		{
			totalResults = [string intValue];	
			totalResultString = string;
			[totalResultString retain];
		}		
	}
}
// Xml parsed at end of document
- (void)parserDidEndDocument:(NSXMLParser *)parser {	
	
	
	//[searchResultsTable reloadData];	
	
	DigitalNZAppDelegate *globalDelegate = [[UIApplication sharedApplication] delegate];	
	// used by the table - asks how many rows are in a section
	if ([globalDelegate.dataSource count] == 0) {
		UIAlertView * alert = [[UIAlertView alloc]
							   initWithTitle:@"Search Results" 
							   message:@"Sorry, no results from your search." 
							   delegate:self 
							   cancelButtonTitle:@"OK" 
							   otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
		
}

#pragma mark -
#pragma mark xcode specific
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		//self.title = @"Digital NZ Search";
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(orientationDidChange:) 
												 name:UIDeviceOrientationDidChangeNotification object:nil];
	
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
	// method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self 
											 selector: @selector(reachabilityChanged:)
												 name: kReachabilityChangedNotification object: nil];
	
	//Change the host name here to change the server your monitoring
    hostReach = [[Reachability reachabilityWithHostName: @"www.digitalnz.org"] retain];
	[hostReach startNotifier];
	[self updateConnectivityStatus: hostReach];
	
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier];
	[self updateConnectivityStatus: internetReach];
	
    wifiReach = [[Reachability reachabilityForLocalWiFi] retain];
	[wifiReach startNotifier];
	[self updateConnectivityStatus: wifiReach];	
	
	self.totalResults = 0;
	
	//change the navigation controller background color
	self.navigationController.navigationBar.tintColor = [UIColor lightGrayColor];
	//self.navigationController.navigationBar.tintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"NavBarBackground.png"]];
	
	
	searchResultsTable.backgroundColor = [UIColor clearColor];
	
	searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self setRotatingImages];	
	
	UIImage *headerImage = [UIImage imageNamed: @"DNZ_TRANSPARENT_BLACK_35.png"];
	UIImageView *headerImageView = [[UIImageView alloc] initWithImage: headerImage];
	
	self.navigationItem.titleView = headerImageView;
	[headerImageView release];
	
	
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(onInfoClicked:) 
		 forControlEvents:UIControlEventTouchUpInside]; 
	
	UIBarButtonItem *iButton = [[UIBarButtonItem alloc] initWithCustomView: infoButton];
	self.navigationItem.rightBarButtonItem = iButton;
	[iButton release];
	[search becomeFirstResponder];
	queue = [NSOperationQueue new];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}
- (void)viewDidUnload {
    [super viewDidUnload];
	
	hostReach = nil;
	wifiReach = nil;
	internetReach = nil;
}

- (void)dealloc {
	
	[rssParser release];
	[item release];
	[currentElement release];
	[currentTitle release];
	[currentSummary release];
	[currentLink release];
	[currentCategory release];
	[currentThumbnail release];
	[currentContentProvider release];
	[currentDate release];
	[imageView release];	
	[totalResultString release];
	[searchEntry release];
	[search release];
	[searchResultsTable release];
	[hostReach release];
	[wifiReach release];
	[internetReach release];
	
    [super dealloc];
}


@end
