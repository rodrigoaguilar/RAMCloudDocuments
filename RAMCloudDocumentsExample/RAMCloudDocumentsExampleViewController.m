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
@property (nonatomic, strong) NSArray *documents; //of RAMCloudDocuments

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

- (void)setDocuments:(NSArray *)documents
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
                self.documents = documents;
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
    }
    
    return cell;
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
