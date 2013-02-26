//
//  RAMCloudDocumentsExampleViewController.m
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/22/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "RAMCloudDocumentsExampleViewController.h"
#import "RAMCloudDocuments.h"

static NSString *const kGoogleDriveKeychainItemName = @"RAMCloudDocumentsExample";  //delete
static NSString *const kGoogleDriveClientId = @"514956818484.apps.googleusercontent.com";  //delete
static NSString *const kGoogleDriveClientSecret = @"dLw4nQcCdIknXAvWPRzHH4lf"; //delete

static NSString *const kDropboxAppKey = @"hg89ipjoqkuucld";  //delete
static NSString *const kDropboxAppSecret = @"042o4h0q6ntshr4";  //delete

@interface RAMCloudDocumentsExampleViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *authButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *accountInfoButton;
@property (nonatomic, strong) RAMCloudDocumentsSession *cloudStorageSession;
@property (nonatomic, strong) NSString *cloudService;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cloudService = @"Dropbox";
    
    [self updateUI];
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
}

- (IBAction)authButtonTapped:(UIBarButtonItem *)sender
{
    if (![self.cloudStorageSession isLinked]) {
        
        [self.cloudStorageSession linkFromController:self completion:^(NSError *error) {
            [self dismissViewControllerAnimated:YES completion:nil];
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
        
    } else {
        [self.cloudStorageSession unlink];
        [self updateUI];
    }
}

- (IBAction)accountButtonTapped:(UIBarButtonItem *)sender
{
    [self.cloudStorageSession loadAccountInfoWithCompletion:^(NSString *accountInfo) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Account Linked:" message:accountInfo delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }];
}

@end
