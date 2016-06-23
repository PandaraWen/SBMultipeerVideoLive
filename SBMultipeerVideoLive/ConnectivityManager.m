//
//  ConnectivityManager.m
//  MCDemo
//
//  Created by Pandara on 16/6/21.
//  Copyright © 2016年 Pandara. All rights reserved.
//

#import "ConnectivityManager.h"

@interface ConnectivityManager () <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate> {
    NSInteger _logLevel;
}

@property (nonatomic, strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *serviceBrowser;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;

@end

@implementation ConnectivityManager

- (id)init
{
    if (self = [super init]) {
        _logLevel = 0;
        
        self.peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        //All devices will advertise the service and scan for the service at the same time
        //On iOS 8 this is supported
        //you can invite any peer you detect while browsing and the framework will handle simultaneous invites
        self.serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:ServiceType];
        self.serviceAdvertiser.delegate = self;
        [self.serviceAdvertiser startAdvertisingPeer];
        
        self.serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:ServiceType];
        self.serviceBrowser.delegate = self;
        [self.serviceBrowser startBrowsingForPeers];
    }
    return self;
}

- (void)dealloc
{
    [self.serviceAdvertiser stopAdvertisingPeer];
    [self.serviceBrowser stopBrowsingForPeers];
}

#pragma mark - Methods
- (void)sendData:(NSData *)data
{
    if (_logLevel <= 0) {
        NSLog(@"will send %lu byte data", (unsigned long)data.length);
    }

    if (self.session.connectedPeers.count > 0) {
        NSError *error = nil;
        if (![self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataUnreliable error:&error]) {
            NSLog(@"send data errort:%@", error);
        }
    } else {
        NSLog(@"No connected peers");
    }
}

- (void)setLogLevel:(NSInteger)level
{
    _logLevel = level;
}

#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"🔴did not start advertising peer:%@", error);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nonnull))invitationHandler
{
    for (MCPeerID *connectedPeerID in self.session.connectedPeers) {
        if ([connectedPeerID isEqual:peerID]) {
            NSLog(@"the peer(%@) is already connected, I not accepting the invitation.", peerID);
            invitationHandler(NO, self.session);
            return;
        }
    }
    NSLog(@"receive and accept invitation from peer:%@", peerID);
    invitationHandler(YES, self.session);
}

#pragma mark - MCNearbyServiceBrowserDelegate
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"🔴did not start browsing for peer:%@", error);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info
{
    for (MCPeerID *connectedPeerID in self.session.connectedPeers) {
        if ([connectedPeerID isEqual:peerID]) {
            NSLog(@"the peer(%@) is already connected, I not inviting it", peerID);
            return;
        }
    }
    
    NSLog(@"found and invite peer:%@", peerID);
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:10];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"⚪️lost peer:%@", peerID);
}

#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"session: peer did change state:  %@", [self stringFromSessionState:state]);
    if ([self.delegate respondsToSelector:@selector(manager:connectedDevicesChanged:)]) {
        NSMutableArray *connectedPeerNames = [NSMutableArray new];
        for (MCPeerID *connectedPeer in session.connectedPeers) {
            [connectedPeerNames addObject:connectedPeer.displayName];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate manager:self connectedDevicesChanged:connectedPeerNames];
        });
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    if (_logLevel <= 0) {
        NSLog(@"receive %lu byte data", (unsigned long)data.length);
    }
    
    if ([self.delegate respondsToSelector:@selector(manager:receiveData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate manager:self receiveData:data];
        });
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"session: did receive stream");
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"session: did start receiving resource with name:%@", resourceName);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"session: did finish receiving resource with name:%@", resourceName);
}

#pragma mark - Utilities
- (NSString *)stringFromSessionState:(MCSessionState)sessionState
{
    NSString *stateStr = nil;
    switch (sessionState) {
        case MCSessionStateConnected:
            stateStr = @"connected";
            break;
        case MCSessionStateConnecting:
            stateStr = @"connecting";
            break;
        case MCSessionStateNotConnected:
            stateStr = @"not connected";
            break;
    }
    
    return stateStr;
}

#pragma mark - Setter Getter
- (MCSession *)session
{
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        _session.delegate = self;
    }
    
    return _session;
}

@end






