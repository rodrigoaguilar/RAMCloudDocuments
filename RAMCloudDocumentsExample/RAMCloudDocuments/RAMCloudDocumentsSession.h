//
//  RAMCloudDocumentsSession.h
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/22/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

typedef void (^linkFromControllerCompletion)(NSError *error);

@interface RAMCloudDocumentsSession : NSObject

//For Google Drive
- (id)initWithKeyChainItem:(NSString *)keychainItemName clientId:(NSString *)clientId clientSecret:(NSString *)secret;
//For Dropbox 
- (id)initWithAppKey:(NSString *)key appSecret:(NSString *)secret root:(NSString *)accessType;

- (BOOL)isLinked; // Session must be linked before creating any client objects
- (void)unlink;

- (void)linkFromController:(UIViewController *)rootController completion:(void (^)(NSError *error))completion;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)loadAccountInfo:(void (^)(NSString *accountInfo, NSError *error))completion;

- (void)loadDocuments:(NSString *)path completion:(void (^)(NSArray *documents, NSError *error))completion; // Returns array with RAMCloudDocuments

@end
