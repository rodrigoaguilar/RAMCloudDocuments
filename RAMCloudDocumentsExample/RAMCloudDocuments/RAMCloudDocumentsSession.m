//
//  RAMCloudDocumentsSession.m
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/22/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "RAMCloudDocumentsSession.h"
#import "RAMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

typedef enum {
    RAMCloudDocumentsServiceTypeGoogleDrive,
    RAMCloudDocumentsServiceTypeDropbox
} RAMCloudDocumentsServiceType;

@interface RAMCloudDocumentsSession () <DBRestClientDelegate>

@property (nonatomic) RAMCloudDocumentsServiceType serviceType;
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, copy) loadAccountInfoCompletion loadAccountInfoBlock;
@property (nonatomic, copy) NSString *userInfo;

@end

@implementation RAMCloudDocumentsSession

- (DBRestClient *)restClient
{
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (id)initWithKeyChainItem:(NSString *)keychainItemName clientId:(NSString *)clientId clientSecret:(NSString *)secret
{
    self = [super init];
    
    if (self) {
        _serviceType = RAMCloudDocumentsServiceTypeGoogleDrive;
        if (!keychainItemName || !clientId || !secret) return nil;
        _keychainItemName = keychainItemName;
        _clientId = clientId;
        _secret = secret;
    }
    
    return self;
}

- (id)initWithAppKey:(NSString *)key appSecret:(NSString *)secret root:(NSString *)accessType
{
    self = [super init];
    
    if (self) {
        _serviceType = RAMCloudDocumentsServiceTypeDropbox;
        if (!key || !secret || !accessType) return nil;
        _key = key;
        _secret = secret;
        _accessType = accessType;
        
        DBSession *dropboxSession = [[DBSession alloc] initWithAppKey:_key appSecret:_secret root:_accessType];
        [DBSession setSharedSession:dropboxSession];
    }
    
    return self;
}

- (BOOL)isLinked
{
    if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
        GTMOAuth2Authentication *auth =
        [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:self.keychainItemName
                                                              clientID:self.clientId
                                                          clientSecret:self.secret];
        
        if ([auth canAuthorize]) {
            self.userInfo = auth.userEmail;
            return YES;
        }
        return NO;
        
    } else if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
        
        if ([[DBSession sharedSession] isLinked]) {
            [self.restClient loadAccountInfo];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            return YES;
        }
        return  NO;
    }
    return NO;
}

- (void)unlink
{
    if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:self.keychainItemName];
    } else if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
        [[DBSession sharedSession] unlinkAll];
    }
}


- (void)linkFromController:(UIViewController *)rootController completion:(linkFromControllerCompletion)completion;
{
    if (rootController) {
        if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
            
            RAMOAuth2ViewControllerTouch *authViewController =
            [[RAMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDrive
                                                       clientID:self.clientId
                                                   clientSecret:self.secret
                                               keychainItemName:self.keychainItemName
                                              completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
                if (completion) {
                    completion(error);
                }
            }];
            
            authViewController.showsInitialActivityIndicator = NO;
            authViewController.cancelCompletionBlock = completion;
            [rootController presentViewController:authViewController animated:YES completion:nil];
            
        } else if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
            [[DBSession sharedSession] linkFromController:rootController];
        }
    }
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
        return [[DBSession sharedSession] handleOpenURL:url];
    }
    return NO;
}

- (void)loadAccountInfoWithCompletion:(loadAccountInfoCompletion)completion;
{
    if (completion) {
        self.loadAccountInfoBlock = completion;
    }
    
    if (self.userInfo) {
        self.loadAccountInfoBlock(self.userInfo);
        self.loadAccountInfoBlock = nil;
    } else {
    
        if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
            
            [self.restClient loadAccountInfo];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
        } else if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
            
            GTMOAuth2Authentication *auth =
            [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:self.keychainItemName
                                                                  clientID:self.clientId
                                                              clientSecret:self.secret];
            self.userInfo = auth.userEmail;
            self.loadAccountInfoBlock(self.userInfo);
            self.loadAccountInfoBlock = nil;
        }
    }
}

#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.userInfo = info.displayName;
    if (self.loadAccountInfoBlock) {
        self.loadAccountInfoBlock(self.userInfo);
        self.loadAccountInfoBlock = nil;
    }
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (self.loadAccountInfoBlock) {
        self.loadAccountInfoBlock([error localizedDescription]);
        self.loadAccountInfoBlock = nil;
    }
}


@end
