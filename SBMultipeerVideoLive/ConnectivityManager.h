//
//  ConnectivityManager.h
//  MCDemo
//
//  Created by Pandara on 16/6/21.
//  Copyright © 2016年 Pandara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppConstant.h"
@import MultipeerConnectivity;

@class ConnectivityManager;
@protocol ConnectivityManagerDelegate <NSObject>

@optional
- (void)manager:(ConnectivityManager *)manager connectedDevicesChanged:(NSArray <NSString *>*)connectedDevices;
- (void)manager:(ConnectivityManager *)manager receiveData:(NSData *)data;

@end

@interface ConnectivityManager : NSObject

@property (nonatomic, weak) id <ConnectivityManagerDelegate> delegate;

- (void)setLogLevel:(NSInteger)level;
- (void)sendData:(NSData *)data;

@end
