//
//  PDFPageViewController.h
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface PDFPageViewController : UIViewController <MCSessionDelegate>

@property (nonatomic, strong) NSURL* pdfURL;

@end
