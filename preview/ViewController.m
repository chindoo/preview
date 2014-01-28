//
//  ViewController.m
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "PDFPageViewController.h"
#import "SessionManager.h"
#import "MBProgressHUD.h"


@interface ViewController () <MCNearbyServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCNearbyServiceBrowser* serviceBrowser;


@property (nonatomic, strong) NSMutableArray* advertisers;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

-(void) viewDidAppear:(BOOL)animated
{
    self.advertisers = [NSMutableArray array];
    [self.tableView reloadData];
    
    [SessionManager shared].session.delegate = self;
    
    if(nil == self.serviceBrowser)
    {
        NSLog(@"Starting browse for services");
        self.serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:[[SessionManager shared] peer] serviceType:@"sch-preview"];
        self.serviceBrowser.delegate = self;
        [self.serviceBrowser startBrowsingForPeers];
    }
    
}

-(void) viewWillDisappear:(BOOL)animated
{
    if ([SessionManager shared].sessionOwner) {
        [self.serviceBrowser stopBrowsingForPeers];
        self.serviceBrowser = nil;
    }

}

#pragma mark - MCNearbyServiceBrowserDelegate
// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    
    NSLog(@"Found adevertiser");
    dispatch_async(    dispatch_get_main_queue(), ^{
        [self.advertisers addObject:peerID];
        [self.tableView reloadData];
    });
    
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
 
    NSLog(@"Lost adevertiser");
    dispatch_async(    dispatch_get_main_queue(), ^{
        [self.advertisers removeObject:peerID];
        [self.tableView reloadData];
    });
}

// Browsing did not start due to an error
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    dispatch_async(    dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Error Joining Session" message:@"Could not join sessions. Please ensure WiFi and Bluetooth are turned on" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    });
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.advertisers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell"];
    MCPeerID* peer = [self.advertisers objectAtIndex:[indexPath row]];
    cell.textLabel.text = peer.displayName;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCPeerID* peer = [self.advertisers objectAtIndex:[indexPath row]];
    [self.serviceBrowser invitePeer:peer toSession:[SessionManager shared].session withContext:nil timeout:30];
    

    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.detailsLabelText = @"Joining Session";
    
}

#pragma mark - MCSessionDelegate

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            PDFPageViewController* pdfController = [[PDFPageViewController alloc] initWithNibName:@"PDFPageViewController" bundle:nil];
            
            [[[SessionManager shared] session] setDelegate:pdfController];
            
            [self.navigationController pushViewController:pdfController animated:YES];
        });

        
    }
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"Started receiving resource in wrong View controller");
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"Received resource in wrong View controller");
}
@end
