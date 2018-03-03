//
//  peripheralPart.h
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/1.
//  Copyright © 2018年 macro-c. All rights reserved.
//

// 蓝牙peripheral模块
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface peripheralPart : NSObject

//@property (nonatomic, strong) NSMutableArray<CBCentral *> *centrals; //应该在delegate对象中持有

+ (instancetype) sharePeripheralWithDelegate :(id<CBPeripheralManagerDelegate>)delegate;

- (void) startAdvertisingWithTitle :(NSString *)title service:(CBService *)service;

- (void) stopAdvertising;

- (void) addService :(CBService *) service;

@end
