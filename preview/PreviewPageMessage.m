//
//  PreviewPageMessage.m
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import "PreviewPageMessage.h"

@implementation PreviewPageMessage

-(instancetype) initWithPage:(NSInteger)page
{
    self = [super init];
    if(self)
    {
        _pageNumber = page;
    }
    return self;
}

#pragma mark - NSCoding Protocol
-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInteger:self.pageNumber] forKey:@"pageNumber"];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _pageNumber = [[aDecoder decodeObjectForKey:@"pageNumber"] integerValue];
    }
    return self;
}

@end
