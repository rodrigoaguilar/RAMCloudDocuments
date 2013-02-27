//
//  RAMCloudDocument.h
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/26/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RAMCloudDocument : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic) BOOL thumbnailExists;
@property (nonatomic) BOOL isDirectory;

@end
