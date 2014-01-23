//
//  SessionManager.m
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

+(instancetype) shared
{
    static dispatch_once_t onceToken;
    static SessionManager* mgr = nil;
    dispatch_once(&onceToken, ^{
        mgr = [[SessionManager alloc] init];
    });
    
    return mgr;
}


-(instancetype) init
{
    self = [super init];
    if(self)
    {
        _peer = [[MCPeerID alloc] initWithDisplayName:@"Peer"];
        _session = [[MCSession alloc] initWithPeer:self.peer];
    }
    return self;
}

@end
