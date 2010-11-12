//
//  NewsBlurViewController.m
//  NewsBlur
//
//  Created by Samuel Clay on 6/16/10.
//  Copyright NewsBlur 2010. All rights reserved.
//

#import "NewsBlurViewController.h"
#import "NewsBlurAppDelegate.h"
#import "JSON.h"
#import "Three20/Three20.h"

@implementation NewsBlurViewController

@synthesize appDelegate;

@synthesize viewTableFeedTitles;
@synthesize feedViewToolbar;
@synthesize feedScoreSlider;
@synthesize logoutButton;

@synthesize feedTitleList;
@synthesize dictFolders;
@synthesize dictFoldersArray;

#pragma mark -
#pragma	mark Globals

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[appDelegate hideNavigationBar:NO];
    }
    return self;
}

- (void)viewDidLoad {
	self.feedTitleList = [[NSMutableArray alloc] init];
	self.dictFolders = [[NSDictionary alloc] init];
	self.dictFoldersArray = [[NSMutableArray alloc] init];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:nil action:nil];
	[appDelegate hideNavigationBar:NO];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[viewTableFeedTitles deselectRowAtIndexPath:[viewTableFeedTitles indexPathForSelectedRow] animated:animated];
	
    [appDelegate hideNavigationBar:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	appDelegate.activeFeed = nil; 
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    //[appDelegate showNavigationBar:YES];
    [super viewWillDisappear:animated];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[feedTitleList release];
	[dictFolders release];
	[dictFoldersArray release];
	[appDelegate release];
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (void)fetchFeedList {
	NSURL *urlFeedList = [NSURL URLWithString:[NSString 
											   stringWithFormat:@"http://nb.local.host:8000/reader/load_feeds_iphone/"]];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL: urlFeedList];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection release];
	[request release];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	NSLog(@"didReceiveData");
	
	NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary *results = [[NSDictionary alloc] initWithDictionary:[jsonString JSONValue]];
	self.dictFolders = [results objectForKey:@"flat_folders"];
	NSLog(@"Received Feeds: %@", dictFolders);
	NSSortDescriptor *sortDescriptor;
	sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"feed_title"
												  ascending:YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	NSMutableDictionary *sortedFolders = [[NSMutableDictionary alloc] init];
	NSArray *sortedArray;
	
	for (id f in self.dictFolders) {
		[self.dictFoldersArray addObject:f];
		
		sortedArray = [[self.dictFolders objectForKey:f] sortedArrayUsingDescriptors:sortDescriptors];
		[sortedFolders setValue:sortedArray forKey:f];
	}
	
	self.dictFolders = sortedFolders;
	[self.dictFoldersArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[[self viewTableFeedTitles] reloadData];
	
	[sortedFolders release];
	[results release];
	[jsonString release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"didReceiveResponse: %@", response);
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	int responseStatusCode = [httpResponse statusCode];
	if (responseStatusCode == 403) {
		[appDelegate showLogin];
	}
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	
		// inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}


- (IBAction)doLogoutButton {
	NSLog(@"Logout");
	NSString *url = @"http://nb.local.host:8000/reader/logout?api=1";
    [[NSHTTPCookieStorage sharedHTTPCookieStorage]
     setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    TTURLRequest *theRequest = [[TTURLRequest alloc] initWithURL:url delegate:self];
    [theRequest.parameters setValue:@"1" forKey:@"api"]; 
    theRequest.response = [[[TTURLDataResponse alloc] init] autorelease];
    [theRequest send];
    
    [theRequest release];
	
}//
//
//- (void)requestDidStartLoad:(TTURLRequest*)request {
//    NSLog(@"Starting");
//}
//
//- (void)requestDidFinishLoad:(TTURLRequest *)request {
//	[appDelegate reloadFeedsView];
//}
//
//- (void)request:(TTURLRequest *)request didFailLoadWithError:(NSError *)error {
//    NSLog(@"Error: %@", error);
//    NSLog(@"%@", error );
//    
//}

#pragma mark -
#pragma mark Table View - Feed List

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//	NSInteger count = [self.dictFolders count];
//	NSLog(@"Folders: %d: %@", count, self.dictFolders);
	return [self.dictFoldersArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	int index = 0;
	for (id f in self.dictFoldersArray) {
		if (index == section) {
			// NSLog(@"Computing Table view header: %i: %@", index, f);
			return f;
		}
		index++;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int index = 0;
	for (id f in self.dictFoldersArray) {
		if (index == section) {
			// NSLog(@"Computing Table view rows: %i: %@", index, f);	
			NSArray *feeds = [self.dictFolders objectForKey:f];
			//NSLog(@"Table view items: %i: %@", [feeds count], f);
			return [feeds count];
		}
		index++;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] 
				 initWithStyle:UITableViewCellStyleDefault
				 reuseIdentifier:SimpleTableIdentifier] autorelease];
	}
	
	int section_index = 0;
	for (id f in self.dictFoldersArray) {
		// NSLog(@"Cell: %i: %@", section_index, f);
		if (section_index == indexPath.section) {
			NSArray *feeds = [self.dictFolders objectForKey:f];
			// NSLog(@"Cell: %i: %@: %@", section_index, f, [feeds objectAtIndex:indexPath.row]);
			cell.textLabel.text = [[feeds objectAtIndex:indexPath.row] 
								   objectForKey:@"feed_title"];
			return cell;
		}
		section_index++;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int section_index = 0;
	for (id f in self.dictFoldersArray) {
		// NSLog(@"Cell: %i: %@", section_index, f);
		if (section_index == indexPath.section) {
			NSArray *feeds = [[NSArray alloc] initWithArray:[self.dictFolders objectForKey:f]];
			[appDelegate setActiveFeed:[feeds objectAtIndex:indexPath.row]];
			[feeds release];
			NSLog(@"Active feed: %@", [appDelegate activeFeed]);
			break;
		}
		section_index++;
	}
	//NSLog(@"App Delegate: %@", self.appDelegate);
	
    appDelegate.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.16f green:0.36f blue:0.46 alpha:0.8];
	
	[appDelegate loadFeedDetailView];
}

@end
