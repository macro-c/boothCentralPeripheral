//
//  peripheralTableViewController.m
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/2.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "peripheralTableViewController.h"
#import "deviceCell.h"

@interface peripheralTableViewController()

@property (nonatomic, strong) id<UITableViewDelegate,UITableViewDataSource> tableDelegate;

@end



@implementation peripheralTableViewController

-(instancetype) initWithTableDelegate :(id<UITableViewDelegate,UITableViewDataSource>)delegate{
    
    self = [super init];
    self.tableDelegate = delegate;
    return self;
}

- (void)initProperties {
    
    self.autoScanTimer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if([self.tableDelegate respondsToSelector:@selector(timerTick)]) {
            [self.tableDelegate performSelector:@selector(timerTick)];
        }
    }];
    self.refreshTimes = 0;
    [[NSRunLoop currentRunLoop] addTimer:self.autoScanTimer forMode:NSRunLoopCommonModes];
}

- (void)loadView {
    
    [super loadView];
    [self initProperties];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.navigationItem setTitle:@"可连接的外设列表"];
    self.navigationController.navigationBar.backgroundColor = [UIColor brownColor];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.peripheralTable = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.peripheralTable.delegate = self.tableDelegate;
    self.peripheralTable.dataSource = self.tableDelegate;
    [self.view addSubview:self.peripheralTable];
    
    [self.peripheralTable registerClass:[deviceCell class] forCellReuseIdentifier:@"deviceCell"];
}


@end



