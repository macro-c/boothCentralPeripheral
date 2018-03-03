//
//  peripheralPart.m
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/1.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "peripheralPart.h"

@interface peripheralPart()

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@end



@implementation peripheralPart

+ (instancetype) sharePeripheralWithDelegate:(id<CBPeripheralManagerDelegate>)delegate {
    static peripheralPart *shareInstance;
    if(shareInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            shareInstance = [[peripheralPart alloc] initByPrivateWithDelegate:delegate];
        });
    }
    return shareInstance;
}

- (instancetype) initByPrivateWithDelegate:(id<CBPeripheralManagerDelegate>)delegate {
    
    self = [super init];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:delegate queue:dispatch_get_main_queue()];
    
    return self;
}

- (void)startAdvertisingWithTitle:(NSString *)title service:(CBService *)service{
    
    if(self.peripheralManager == nil || service == nil) {
        return;
    }
    
    //需要先去掉原services 否则重复添加service导致崩溃
    [self.peripheralManager removeAllServices];
    
    [self.peripheralManager addService:service];
    
    //开启广播的时候设置了当前外设的名字  peripheral.name 属性
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:title}];
}

- (void)stopAdvertising {
    
    [self.peripheralManager stopAdvertising];
}

@end
