//
//  peripheralTableViewController.h
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/2.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface peripheralTableViewController : UIViewController

@property (nonatomic, strong) UITableView *peripheralTable;
@property (nonatomic, strong) NSTimer *autoScanTimer;
@property (nonatomic, assign) NSInteger refreshTimes;

-(instancetype) initWithTableDelegate :(id<UITableViewDelegate,UITableViewDataSource>)delegate;

@end
