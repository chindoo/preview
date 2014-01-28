//
//  SessionManager.h
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface SessionManager : NSObject

+(instancetype) shared;

@property (nonatomic, strong, readonly) MCPeerID* peer;
@property (nonatomic, strong, readonly) MCPeerID* advertisingPeer;

@property (nonatomic, strong, readonly) MCSession* session;
@property (nonatomic, strong, readonly) MCSession* advertisingSession;

/** Flag indicating this VC is the owner of the multipeer session **/
@property (nonatomic, assign) BOOL sessionOwner;

@end
