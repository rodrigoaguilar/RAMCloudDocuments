//
//  RAMCloudDocument.m
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/26/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "RAMCloudDocument.h"

@implementation RAMCloudDocument

- (NSString *)description
{
    return [NSString stringWithFormat:@"title: %@, thumb: %@", self.title, self.thumbnail];
}

@end
