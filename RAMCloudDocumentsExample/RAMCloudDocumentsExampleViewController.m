//
//  RAMCloudDocumentsExampleViewController.m
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/22/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "RAMCloudDocumentsExampleViewController.h"
#import "RAMCloudDocuments.h"
#import "ImageViewController.h"

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
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cloud Document"];
    
    self.cloudService = @"Google Drive";
    
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
    return [self.documents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cloud Document" forIndexPath:indexPath];
    
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
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RAMCloudDocument *document = [self documentForRow:indexPath.row];
    if (!document.isDirectory) {
        [self.cloudStorageSession loadDocument:document completion:^(RAMCloudDocument *newDocument) {
            [self.documents removeObjectAtIndex:indexPath.row];
            [self.documents insertObject:newDocument atIndex:indexPath.row];
            [self performSegueWithIdentifier:@"Show Image" sender:document];
        }];
    } else {

        RAMCloudDocumentsExampleViewController *directory = [self.storyboard instantiateViewControllerWithIdentifier:@"FilesViewController"];
        directory.path = document.path;
        directory.title = document.title;
        [self.navigationController pushViewController:directory animated:YES];

        
    }
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[RAMCloudDocument class]]) {
        RAMCloudDocument *document = (RAMCloudDocument *)sender;
        if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
            if (document.localPath) {
                NSURL *url = [NSURL fileURLWithPath:document.localPath];
                [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
                [segue.destinationViewController setTitle:document.title];
            }
        }
    }
}


@end
