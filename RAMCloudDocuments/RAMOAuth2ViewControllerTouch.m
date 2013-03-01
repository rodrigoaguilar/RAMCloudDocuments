//
//  RAMOAuth2ViewControllerTouch.m
//  RAMCloudDocumentsExample
//
//  Created by Rodrigo Aguilar on 2/25/13.
//  Copyright (c) 2013 bNapkin. All rights reserved.
//

#import "RAMOAuth2ViewControllerTouch.h"

@interface RAMOAuth2ViewControllerTouch ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation RAMOAuth2ViewControllerTouch

+ (NSString *)authNibName
{
    return @"RAMOAuth2ViewControllerTouch";
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self cancelSigningIn];
    if (self.cancelCompletionBlock) {
        self.cancelCompletionBlock(nil);
    }
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [super webViewDidStartLoad:webView];
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [super webViewDidFinishLoad:webView];
    [self.activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [super webView:webView didFailLoadWithError:error];
    [self.activityIndicator stopAnimating];
}


@end
