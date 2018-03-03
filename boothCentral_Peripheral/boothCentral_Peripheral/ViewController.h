//
//  ViewController.h
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/1.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate,CBPeripheralManagerDelegate,UITableViewDelegate,UITableViewDataSource>

// 调试模式，YES时一对多，被调试对象是真正意义central；NO时一对一聊天模式
@property (nonatomic, assign) BOOL debugMode;
// 在debugMode为YES时，当前设备是否是真正意义上中心，debugMode为NO时无效
@property (nonatomic, assign) BOOL isRealCentral;

- (void) timerTick;

@end

