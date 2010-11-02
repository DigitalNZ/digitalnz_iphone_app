//
//  SearchViewController.h
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

#import <UIKit/UIKit.h>
#import "Reachability.h"

static const int constPageSize = 10;
static NSString * const constApiKey = @"";


@interface SearchViewController : UIViewController<UISearchBarDelegate>{

	NSXMLParser * rssParser;
	
	// a temporary item; added to the "stories" array one at a time, and cleared for the next one
	NSMutableDictionary * item;
	
	// it parses through the document, from top to bottom...
	// we collect and cache each sub-element value, and then save each item to our array.
	// we use these to track each current item, until it's ready to be added to the "stories" array
	NSString * currentElement;
	NSString * totalResultString;
	NSString * searchEntry;
	NSOperationQueue *queue;
	
	NSMutableString *currentTitle, *currentSummary, * currentLink, *currentCategory, *currentThumbnail, *currentContentProvider, *currentDate, *tempNumber;
	NSInteger totalResults, *pageOffset;
	
	IBOutlet UISearchBar *search;
	IBOutlet UITableView *searchResultsTable;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	
	BOOL IsConnected;
	
	IBOutlet UIImageView *imageView;
	
	/* Reachability taken from Reachability App from AppStore*/
	Reachability* hostReach;
    Reachability* internetReach;
    Reachability* wifiReach;
	
}
@property () BOOL IsConnected;
	//@property (nonatomic, retain) NSMutableArray *dataSource;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSString *totalResultString;
@property (nonatomic, retain) NSString *searchEntry;
@property (nonatomic, assign) NSInteger totalResults;
@property (nonatomic, assign) NSInteger *pageOffset;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, assign) IBOutlet UISearchBar *search;
@property (nonatomic, assign) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UITableView *searchResultsTable;

- (void) updateConnectivityStatus: (Reachability*) curReach;
- (void) doSearch:(NSString *)searchTerm;
- (void) onInfoClicked:(UIButton *)button;
- (void) performSearch:(NSString *)searchTerm;
- (BOOL) hasActiveOperations:(NSArray *)operations;
- (void) parseXMLFileAtURL:(NSString *)URL;
- (void) setRotatingImages;
- (void)refreshDisplay;

@end
