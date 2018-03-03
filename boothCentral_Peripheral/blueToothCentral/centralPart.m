//
//  centralPart.m
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/1.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "centralPart.h"

@interface centralPart()

@property (nonatomic, strong) CBPeripheral *per;
@property (nonatomic, strong) CBCharacteristic *cha;
@property (nonatomic, strong) CBCentralManager *centralManager;

@end



@implementation centralPart

+ (instancetype) shareCentralWithDelegate :(id<CBCentralManagerDelegate>)delegate {
    static centralPart *shareInstance;
    if(shareInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            shareInstance = [[centralPart alloc] initByPrivateWithDelegate:delegate];
        });
    }
    return shareInstance;
}

- (instancetype) initByPrivateWithDelegate :(id<CBCentralManagerDelegate>)delegate {
    
    self = [super init];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:delegate queue:dispatch_get_main_queue()];
    
    return self;
}

- (void) cancelConnection :(NSArray<CBPeripheral*> *) peripherals {
    
    if(peripherals.count && peripherals.count!=0 &&self.centralStatus)
    {
        for (CBPeripheral *peripheralCancel in peripherals) {
            
            [self.centralManager cancelPeripheralConnection:peripheralCancel];
        }
    }
}

- (void) connectPeripheral:(CBPeripheral *)peripheral withOption:(NSDictionary *)option {
    
    [self.centralManager connectPeripheral:peripheral options:option];
}

- (void) stopCentralManager :(NSArray<CBPeripheral*> *) peripherals {
    
    if(self.centralManager) {
        if(peripherals && peripherals.count!=0)
        {
            [self cancelConnection:peripherals];
        }
        [self.centralManager stopScan];
    }
}

- (void) startScanPeripheral {
    
    if(self.centralStatus) {
        
        // 表示不筛选service 进行扫描
        [self.centralManager scanForPeripheralsWithServices:nil
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)}];
    }
}

// 属性读方法，central是否可用状态
- (BOOL) centralStatus {
    
    if(self.centralManager && self.centralManager.state == CBManagerStatePoweredOn)
    {
        return YES;
    }
    return NO;
}


@end






