//
//  RAMOAuth2ViewControllerTouch.h
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/25/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "GTMOAuth2ViewControllerTouch.h"
#import "RAMCloudDocumentsSession.h"

@interface RAMOAuth2ViewControllerTouch : GTMOAuth2ViewControllerTouch

@property (nonatomic, copy) linkFromControllerCompletion cancelCompletionBlock;

@end
