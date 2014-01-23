//
//  PDFPageViewController.m
//  preview
//
//  Created by craigspi on 1/15/14.
//  Copyright (c) 2014 Scholastic Corporation. All rights reserved.
//

#import "PDFPageViewController.h"
#import "ReaderContentView.h"
#import "ReaderDocument.h"
#import "PreviewPageMessage.h"
#import "MBProgressHUD.h"
#import "PreviewPageMessage.h"
#import "SessionManager.h"
#import <QuickLook/QuickLook.h>

@interface PDFPageViewController () <MCNearbyServiceBrowserDelegate, UIAlertViewDelegate, ReaderContentViewDelegate>

@property (weak, nonatomic) IBOutlet UIToolbar *toobar;
- (IBAction)previousPagePressed:(id)sender;
- (IBAction)nextPagePressed:(id)sender;
- (IBAction)exitPressed:(id)sender;

-(void) showPage:(NSInteger)page;

@property (nonatomic, strong) ReaderContentView* currentPageView;
@property (nonatomic, assign) NSInteger currentPage;
//@property (nonatomic, strong) ReaderDocument* document;
@property (nonatomic, strong) NSMutableArray* currentPageViewConstraints;


@property (nonatomic, strong) MCNearbyServiceBrowser* serviceBrowser;

@property (nonatomic, assign) BOOL receivedPage;

@end

@implementation PDFPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) setPdfURL:(NSURL *)pdfURL
{
    _pdfURL = pdfURL;
    //self.document = [[ReaderDocument alloc] initWithFilePath:[pdfURL path] password:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self showPage:1];
    
    if ([SessionManager shared].sessionOwner) {
        
        self.serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:[[SessionManager shared] peer] serviceType:@"sch-preview"];
        self.serviceBrowser.delegate = self;

        [[[SessionManager shared] session] setDelegate:self];
        
        [self.serviceBrowser startBrowsingForPeers];

    }
    else
    {
        [self.toobar setHidden:YES];
    }
}

-(void) showPage:(NSInteger)page
{
    self.currentPage = page;
    
    if(nil == self.pdfURL)
        return;
    
    if(self.currentPageView)
    {
        [self.currentPageView removeFromSuperview];
        [self.view removeConstraints:self.currentPageViewConstraints];
    }
    
    self.currentPageView = [[ReaderContentView alloc] initWithFrame:self.view.bounds
                                                                     fileURL:self.pdfURL
                                                                        page:page password:nil];
    self.currentPageView.message = self;
    
    self.currentPageViewConstraints = [NSMutableArray array];
    
    // add constraints to the reader so it resizes correctly
    [self.currentPageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    [self.view addSubview:self.currentPageView];
    [self.view bringSubviewToFront:self.toobar ];
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(self.view, _currentPageView);
    
    [self.currentPageViewConstraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_currentPageView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [self.currentPageViewConstraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_currentPageView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];

    
    [self.view addConstraints:self.currentPageViewConstraints];
    
    if ([[SessionManager shared] sessionOwner]) {
        
        [self tellPeersToOpenPage:self.currentPage];
    }


}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self showPage:self.currentPage];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)previousPagePressed:(id)sender {
    [self showPage:self.currentPage - 1];
}

- (IBAction)nextPagePressed:(id)sender {
    [self showPage:self.currentPage + 1];
}

- (IBAction)exitPressed:(id)sender {
    
    [[[SessionManager shared] session] disconnect];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) tellPeersToOpenPage:(NSInteger)page
{
    [self tellPeers:[[SessionManager shared] session].connectedPeers toOpenPage:page];
}

-(void) tellPeers:(NSArray*)peers toOpenPage:(NSInteger)page
{
    PreviewPageMessage* message = [[PreviewPageMessage alloc] initWithPage:page];
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:message];

    NSError* error = nil;
    
    if(![[[SessionManager shared] session] sendData:data toPeers:peers withMode:MCSessionSendDataReliable error:&error])
    {
        NSLog(@"Error sending data to peer: %@", error);
    }
}

#pragma mark - MCNearbyServiceBrowserDelegate
// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    if (peerID != [[SessionManager shared] peer]) {
        NSLog(@"Found peer: %@, %@", peerID, peerID.displayName);

        // invite the peer
        dispatch_async(dispatch_get_main_queue(), ^{
            [browser invitePeer:peerID toSession:[[SessionManager shared] session] withContext:nil timeout:3000];
        });
    }
    

}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost peer: %@", peerID);
}

// Browsing did not start due to an error
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Did not start browsing for peers: %@", error);
}

#pragma mark - MCSessionDelegate
// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if ([SessionManager shared].sessionOwner) {
        
        // send the PDF to the device. Once its complete, tell the device what page to open.
        if (state == MCSessionStateConnected) {
            NSLog(@"Session Owner received connection");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [session sendResourceAtURL:self.pdfURL withName:@"peer.pdf" toPeer:peerID withCompletionHandler:^(NSError *error) {
                    if (error) {
                        [[[UIAlertView alloc] initWithTitle:@"Error Sending PDF"
                                                    message:@"There was an error sending the PDF to a connected device. Please have the controller of that device try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    }
                    else
                    {
                        [self tellPeers:@[peerID] toOpenPage:self.currentPage];
                    }
                }];
                 
            
            });
            
        }
        
    }
    else
    {
        if (state == MCSessionStateNotConnected && peerID == [SessionManager shared].peer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
    }
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([obj isKindOfClass:[PreviewPageMessage class]]) {
            self.receivedPage = YES;
            PreviewPageMessage* pageMessage = (PreviewPageMessage*)obj;
            [self showPage:pageMessage.pageNumber];
        }
    });

    
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setDetailsLabelText:@"Loading PDF from Peer"];
    });

}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSURL* fileURL = nil;
    
    if(!error)
    {
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.pdf"];
        
        fileURL = [NSURL fileURLWithPath:filePath];
        NSError* error = nil;
        
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        if(![[NSFileManager defaultManager] moveItemAtURL:localURL toURL:fileURL error:&error])
        {
            NSLog(@"Error moving PDF file: %@", error);
        }
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error Loading PDF" message:@"There was an error loading the PDF from the remote peer" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
        else
        {
            self.pdfURL = fileURL;

            if (self.receivedPage) {
                [self showPage:self.currentPage];
            }
        }

    });

    
}
#pragma mark - ReaderContentViewDelegate
- (void)contentView:(ReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
    if (![[SessionManager shared] sessionOwner]) {
        [self showToolbar];
    }
}

-(void) showToolbar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToolbar) object:nil];
    
    if (self.toobar.hidden) {
        self.toobar.alpha = 0;
        self.toobar.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.toobar.alpha = 1;
        }];
    }
    
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:3];
}

-(void) hideToolbar
{
    if(!self.toobar.hidden)
    {
        self.toobar.alpha = 1;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.toobar.alpha = 0;
                         } completion:^(BOOL finished) {
                             self.toobar.hidden = YES;
                         }];
        
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
