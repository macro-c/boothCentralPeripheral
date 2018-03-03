//
//  centralPart.h
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/1.
//  Copyright © 2018年 macro-c. All rights reserved.
//

// 蓝牙的central模块

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface centralPart : NSObject

@property (nonatomic, assign, readonly) BOOL centralStatus;

+ (instancetype) shareCentralWithDelegate : (id<CBCentralManagerDelegate>)delegate;

- (void) connectPeripheral :(CBPeripheral *)peripheral withOption :(NSDictionary *)option;

- (void) cancelConnection :(NSArray<CBPeripheral *> *) peripherals;

- (void) stopCentralManager :(NSArray<CBPeripheral*> *) peripherals;

- (void) startScanPeripheral;

@end


