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
#import "MFCache.h"
#import "AFImageRequestOperation.h"

typedef enum {
    RAMCloudDocumentsServiceTypeGoogleDrive,
    RAMCloudDocumentsServiceTypeDropbox
} RAMCloudDocumentsServiceType;

typedef void (^LoadMetadataCallback)(DBMetadata*, NSError*);
typedef void (^LoadAccountInfoCallback)(NSString*, NSError*);
typedef void (^LoadThumbnailCallback)(NSError*);
typedef void (^LoadFileCallback)(NSString*, NSError*);

@interface RAMCloudDocumentsSession () <DBRestClientDelegate>

@property (nonatomic) RAMCloudDocumentsServiceType serviceType;
@property (nonatomic, strong) DBRestClient *restClient;
@property(nonatomic, copy) id callback;

@property (weak, readonly) GTLServiceDrive *driveService;

//For Google Drive
@property (nonatomic, copy) NSString *keychainItemName;
@property (nonatomic, copy) NSString *clientId;
//For Dropbox
@property (nonatomic, copy) NSString *accessType;
@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) NSString *secret;

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

- (GTLServiceDrive *)driveService
{
    static GTLServiceDrive *service = nil;
    
    if (!service) {
        service = [[GTLServiceDrive alloc] init];
        
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    }
    return service;
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
            self.driveService.authorizer = auth;
            return YES;
        }
        return NO;
        
    } else if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
        return  [[DBSession sharedSession] isLinked];
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
                                                  if (!error) {
                                                       NSLog(@"App linked successfully!");
                                                      self.driveService.authorizer = auth;
                                                  }
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

#pragma mark Account Info
- (void)loadAccountInfo:(void (^)(NSString *accountInfo, NSError *error))completion
{
    if (completion) {
        if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
            
            [self dropboxLoadAccountInfo:^(NSString *accountInfo, NSError *error) {
                completion(accountInfo, error);
            }];
            
        } else if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
            
            GTMOAuth2Authentication *auth =
            [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:self.keychainItemName
                                                                  clientID:self.clientId
                                                              clientSecret:self.secret];
            completion(auth.userEmail, nil);
        }
    }
}

- (void)dropboxLoadAccountInfo:(LoadAccountInfoCallback)completionBlock
{
    self.callback = completionBlock;
	[self.restClient loadAccountInfo];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark Load Documents

- (void)loadDocuments:(NSString *)path completion:(void (^)(NSArray *documents, NSError *error))completion; 
{
    if (path && completion) {
        NSMutableArray *documents = [[NSMutableArray alloc] init];
        if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
            [self dropboxLoadMetadata:path completionBlock:^(DBMetadata *metadata, NSError *error) {
                if (!error) {
                    for (DBMetadata *child in metadata.contents) {
                        RAMCloudDocument *document = [[RAMCloudDocument alloc] init];
                        document.title = [child.path lastPathComponent];
                        document.isDirectory = child.isDirectory;
                        document.path = child.path;
                        document.thumbnailExists = child.thumbnailExists;
                        [documents addObject:document];
                    }
                }
                completion(documents, error);
            }];
        } else if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

            GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
            query.maxResults = 1000;
            query.q = @"'root' in parents and trashed=false";            
            [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                                      GTLDriveFileList *files,
                                                                      NSError *error) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (!error) {
                    for (GTLDriveFile *file in files) {
                        RAMCloudDocument *document = [[RAMCloudDocument alloc] init];
                        document.title = file.title;
                        if (file.downloadUrl) {
                            document.path = file.downloadUrl;
                        }
                        if ([file.mimeType isEqualToString:@"application/vnd.google-apps.folder"]) {
                            document.isDirectory = YES;
                            document.path = file.identifier;
                        }
                        if ([file.mimeType hasPrefix:@"image"]) {
                            document.thumbnailExists = YES;
                            document.thumbnailLink = file.thumbnailLink;
                        }
                        [documents addObject:document];
                    }
                }
                completion(documents, error);
            }];
        }
    }
}

- (void)dropboxLoadMetadata:(NSString*)path completionBlock:(LoadMetadataCallback)completionBlock
{
    self.callback = completionBlock;
    [self.restClient loadMetadata:path];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark thumbnails

- (void)loadThumbnailForDocument:(RAMCloudDocument *)document completion:(void (^)(RAMCloudDocument *document))completion
{
    if (document) {
        if (document.thumbnailExists) {
            NSString *thumbPrefix = kTHUMB_PREFIX;
            NSString *thumbKey = [NSString stringWithFormat:@"%@%@",thumbPrefix,document.title];
            UIImage *cachedThumb = (UIImage *)[MFCache valueForKey:thumbKey];
            if (cachedThumb){
                document.thumbnail = cachedThumb;
                completion(document);
            } else {
                if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
                    NSString *destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:thumbKey];
                    [self dropboxLoadThumbnail:document.path ofSize:@"m" intoPath:destinationPath completionBlock:^(NSError *error) {
                        if (!error) {
                            document.thumbnail = [UIImage imageWithContentsOfFile:destinationPath];
                            [MFCache setValue:document.thumbnail forKey:thumbKey expiration:kCACHE_EXPIRATION_TIME];
                        }
                        completion(document);
                    }];
                } else if (self.serviceType == RAMCloudDocumentsServiceTypeGoogleDrive) {
                    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:document.thumbnailLink]];
                    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:theRequest success:^(UIImage *image) {
                        if (image) {
                            document.thumbnail = image;
                            [MFCache setValue:document.thumbnail forKey:thumbKey expiration:kCACHE_EXPIRATION_TIME];
                        }
                        completion(document);
                    }];
                    [operation start];
                }
            }
        }
    }
}

- (void)dropboxLoadThumbnail:(NSString *)path ofSize:(NSString *)size intoPath:(NSString *)destinationPath completionBlock:(LoadThumbnailCallback)completionBlock
{
    self.callback = completionBlock;
    [self.restClient loadThumbnail:path ofSize:size intoPath:destinationPath];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark Downloads

- (void)loadDocument:(RAMCloudDocument *)document completion:(void (^)(RAMCloudDocument *newDocument))completion
{
    if (document) {
        NSString *destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:document.title];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
            document.localPath = destinationPath;
            completion(document);
        } else {
            if (self.serviceType == RAMCloudDocumentsServiceTypeDropbox) {
                [self dropboxLoadFile:document.path intoPath:destinationPath completionBlock:^(NSString *destPath, NSError *error) {
                    if (!error) {
                        document.localPath = destPath;
                    }
                    completion(document);
                }];
            }
        }
    }
}


- (void)dropboxLoadFile:(NSString *)path intoPath:(NSString *)destinationPath completionBlock:(LoadFileCallback)completionBlock
{
    self.callback = completionBlock;
    [self.restClient loadFile:path intoPath:destinationPath];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}


#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadAccountInfoCallback handler = self.callback;
    handler(info.displayName, nil);
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadAccountInfoCallback handler = self.callback;
    handler(nil, error);
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadMetadataCallback handler = self.callback;
    handler(metadata,nil);
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadMetadataCallback handler = self.callback;
    handler(nil,error);
}

- (void)restClient:(DBRestClient *)client loadedThumbnail:(NSString *)destPath metadata:(DBMetadata *)metadata
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadThumbnailCallback handler = self.callback;
    handler(nil);
}

- (void)restClient:(DBRestClient *)client loadThumbnailFailedWithError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadThumbnailCallback handler = self.callback;
    handler(error);
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadFileCallback handler = self.callback;
    handler(destPath, nil);
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    LoadFileCallback handler = self.callback;
    handler(nil, error);
}


@end
