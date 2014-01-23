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


@interface ViewController () <MCNearbyServiceAdvertiserDelegate, UITableViewDataSource, UITableViewDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCNearbyServiceAdvertiser* serviceAdvertiser;


@property (nonatomic, strong) NSMutableArray* invitations;

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
    self.invitations = [NSMutableArray array];
    [self.tableView reloadData];
    
    [SessionManager shared].session.delegate = self;
    
    if(nil == self.serviceAdvertiser)
    {
        self.serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:[[SessionManager shared] peer] discoveryInfo:nil serviceType:@"sch-preview"];
        self.serviceAdvertiser.delegate = self;
        [self.serviceAdvertiser startAdvertisingPeer];
    }
    
}

-(void) viewWillDisappear:(BOOL)animated
{
    if ([SessionManager shared].sessionOwner) {
        [self.serviceAdvertiser stopAdvertisingPeer];
        self.serviceAdvertiser = nil;
    }

}


#pragma mark - MCNearbyServiceAdvertiserDelegate
// Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSDictionary* invitation = @{@"handler": [invitationHandler copy], @"name":peerID.displayName};
    [self.invitations addObject:invitation];
    
    [self.tableView reloadData];
}

// Advertising did not start due to an error
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
   [[[UIAlertView alloc] initWithTitle:@"Error Joining Session" message:@"Could not join sessions. Please ensure WiFi and Bluetooth are turned on" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.invitations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell"];
    NSDictionary* invitation = [self.invitations objectAtIndex:[indexPath row]];
    cell.textLabel.text = [invitation objectForKey:@"name"];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* invitation = [self.invitations objectAtIndex:[indexPath row]];
    void (^invitationHandler)(BOOL accept, MCSession *session) = [invitation objectForKey:@"handler"];
    invitationHandler(YES, [[SessionManager shared] session]);
}

#pragma mark - MCSessionDelegate

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        
        //[self.serviceAdvertiser stopAdvertisingPeer];
        //self.serviceAdvertiser = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
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
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}
@end
