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
typedef void (^loadAccountInfoCompletion)(NSString *accountInfo);


@interface RAMCloudDocumentsSession : NSObject

//For Google Drive
@property (nonatomic, copy) NSString *keychainItemName;
@property (nonatomic, copy) NSString *clientId;
//For Dropbox
@property (nonatomic, copy) NSString *accessType;
@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) NSString *secret;

//Google Drive designated initializer
- (id)initWithKeyChainItem:(NSString *)keychainItemName clientId:(NSString *)clientId clientSecret:(NSString *)secret;
//Dropbox designated initializer
- (id)initWithAppKey:(NSString *)key appSecret:(NSString *)secret root:(NSString *)accessType;

- (BOOL)isLinked; // Session must be linked before creating any client objects
- (void)unlink;

- (void)linkFromController:(UIViewController *)rootController completion:(void (^)(NSError *error))completion;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)loadAccountInfoWithCompletion:(loadAccountInfoCompletion)completion;

@end
