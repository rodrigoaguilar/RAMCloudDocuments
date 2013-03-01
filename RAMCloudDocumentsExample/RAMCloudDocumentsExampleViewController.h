//
//  RAMCloudDocumentsExampleViewController.h
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/22/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *const kGoogleDriveKeychainItemName = @"RAMCloudDocumentsExample";  
static NSString *const kGoogleDriveClientId = @"CLIENTID";
static NSString *const kGoogleDriveClientSecret = @"CLIENTSECRET"; 

static NSString *const kDropboxAppKey = @"KEY";  
static NSString *const kDropboxAppSecret = @"SECRET";  

@interface RAMCloudDocumentsExampleViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>



@end
