//
//  PreviewPageMessage.h
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreviewPageMessage : NSObject <NSCoding>

-(instancetype) initWithPage:(NSInteger)page;

@property (nonatomic, assign) NSInteger pageNumber;

@end
