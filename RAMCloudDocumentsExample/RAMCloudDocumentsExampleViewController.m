//
//  RAMCloudDocumentsExampleViewController.m
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/22/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "RAMCloudDocumentsExampleViewController.h"
#import "RAMCloudDocuments.h"


@interface RAMCloudDocumentsExampleViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *authButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *accountInfoButton;
@property (nonatomic, strong) RAMCloudDocumentsSession *cloudStorageSession;
@property (nonatomic, strong) NSString *cloudService;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSMutableArray *documents; //of RAMCloudDocuments

@end

@implementation RAMCloudDocumentsExampleViewController


- (RAMCloudDocumentsSession *)cloudStorageSession
{
    if (!_cloudStorageSession) {
        if ([self.cloudService isEqualToString:@"Google Drive"]) {
            _cloudStorageSession = [[RAMCloudDocumentsSession alloc] initWithKeyChainItem:kGoogleDriveKeychainItemName
                                                                                 clientId:kGoogleDriveClientId
                                                                             clientSecret:kGoogleDriveClientSecret];
        } else if ([self.cloudService isEqualToString:@"Dropbox"]) {
            _cloudStorageSession = [[RAMCloudDocumentsSession alloc] initWithAppKey:kDropboxAppKey
                                                                          appSecret:kDropboxAppSecret
                                                                               root:kDBRootDropbox];
        }
    }
    return _cloudStorageSession;
}

- (void)setDocuments:(NSMutableArray *)documents
{
    _documents = documents;
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cloudService = @"Dropbox";
    
    if (!_path) {
        self.path = @"/";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)updateUI
{
    BOOL accountIsLinked = [self.cloudStorageSession isLinked];
    self.authButton.title = accountIsLinked ? @"Sign out" : @"Sign in";
    self.accountInfoButton.enabled = accountIsLinked;
    if  (accountIsLinked) {
        [self.cloudStorageSession loadDocuments:self.path completion:^(NSArray *documents, NSError *error) {
            if (!error) {
                self.documents = [documents mutableCopy];
            } else {
                NSLog(@"Error: %@", [error description]);
            }
        }];
    } else {
        self.documents = nil;
    }
}

- (IBAction)authButtonTapped:(UIBarButtonItem *)sender
{
    if (![self.cloudStorageSession isLinked]) { // Sign in 
        
        [self.cloudStorageSession linkFromController:self completion:^(NSError *error) {
            [self dismissViewControllerAnimated:YES completion:nil];
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
        
    } else { //Sign off
        [self.cloudStorageSession unlink];
        [self updateUI];
    }
}

- (IBAction)accountButtonTapped:(UIBarButtonItem *)sender
{
    [self.cloudStorageSession loadAccountInfo:^(NSString *accountInfo, NSError *error) {
        if (!error) {
            NSString *title = [NSString stringWithFormat:@"%@ Account Linked:", self.cloudService];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:accountInfo delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else {
            NSLog(@"Error :%@", [error description]);
        }
    }];
}

- (RAMCloudDocument *)documentForRow:(NSUInteger)row
{
    if ([self.documents[row] isKindOfClass:[RAMCloudDocument class]]) {
        RAMCloudDocument *document = (RAMCloudDocument *)self.documents[row];
        return document;
    }
    return nil;
}

- (void)loadThumbnailForDocument:(RAMCloudDocument *)document atIndexPath:(NSIndexPath *)indexPath
{
    [self.cloudStorageSession loadThumbnailForDocument:document completion:^(RAMCloudDocument *newDocument) {
        if (newDocument) {
            [self.documents removeObjectAtIndex:indexPath.row];
            [self.documents insertObject:newDocument atIndex:indexPath.row];
            [self.tableView reloadData];
        }
    }];
}

- (void)loadThumbsForOnscreenRows
{
    if ([self.documents count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            RAMCloudDocument *document = [self.documents objectAtIndex:indexPath.row];
            if (!document.thumbnail && document.thumbnailExists) // avoid the app icon download if the app already has an icon
            {
                [self loadThumbnailForDocument:document atIndexPath:indexPath];
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = [self.documents count];
    
    if (count == 0) {
        return 1;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cloud Document" forIndexPath:indexPath];
    
    int nodeCount = [self.documents count];
	
	if (nodeCount == 0 && indexPath.row == 0)
	{
		cell.textLabel.text = @"Loading…";
		
		return cell;
    }

    
    RAMCloudDocument *document = [self documentForRow:indexPath.row];
    
    if (document) {
        cell.textLabel.text = document.title;
        if (document.isDirectory) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (document.thumbnail) {
            cell.imageView.image = document.thumbnail;
        } else if (document.thumbnailExists) {
            if (!self.tableView.dragging && !self.tableView.decelerating) {
                [self loadThumbnailForDocument:document atIndexPath:indexPath];
            }
            cell.imageView.image = nil;
        }
    }
    
    return cell;
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        [self loadThumbsForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadThumbsForOnscreenRows];
}


#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Push Directory"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setPath:)]) {
                    RAMCloudDocument *document = [self documentForRow:indexPath.row];
                    [segue.destinationViewController performSelector:@selector(setPath:) withObject:document.path];
                    [segue.destinationViewController setTitle:document.title];
                }
            }
        }
    }
}


@end
