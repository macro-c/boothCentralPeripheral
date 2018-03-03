//
//  ViewController.m
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/1.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import "ViewController.h"
#import "peripheralPart.h"
#import "centralPart.h"
#import "peripheralTableViewController.h"
#import "deviceCell.h"
#import "chatModeViewController.h"
#import "debugModeViewController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGTH [UIScreen mainScreen].bounds.size.height

@interface ViewController ()

@property (nonatomic, assign) BOOL isWorking;

@property (nonatomic, strong) chatModeViewController *chatVC;
@property (nonatomic, strong) debugModeViewController *debugVC;

@property (nonatomic, assign) BOOL blueToothAvailable;
@property (nonatomic, strong) UILabel *debugModeLabel;
@property (nonatomic, strong) UILabel *debugRoleLabel;
@property (nonatomic, strong) UIButton *changeRoleBtn;
@property (nonatomic, strong) UIButton *changeModeBtn;
@property (nonatomic, strong) UIButton *startAdvBtn;
@property (nonatomic, strong) UIButton *stopAdvBtn;
//@property (nonatomic, strong) NSTimer *autoScanTimer;

//调试模式  设置挑事者名称
@property (nonatomic, strong) UITextField *debugerName;
@property (nonatomic, strong) UILabel *debugerNameLabel;

//聊天模式  设置自己名称
@property (nonatomic, strong) UITextField *userName;
@property (nonatomic, strong) UILabel *userNameLabel;

//以下两者同时 ok的话，优先central
//聊天模式，central已订阅
@property (nonatomic, assign) BOOL centralIsOK;
//peripheral 已经被订阅
@property (nonatomic, assign) BOOL peripheralIsOK;


@property (nonatomic, strong) peripheralPart *peripheralManagerPart;
// peripheral使用，保存被收听的centrals
@property (nonatomic, strong) NSMutableArray<CBCentral *> *centrals;
// 保存每个central对应消息最长值，为NSNumber类型
@property (nonatomic, strong) NSMutableArray *centralsMaxMessageLength;
// 记录central标识，BOOL值，记录当前central是真正意义上的“中心”，协商central首条信息

@property (nonatomic, strong) centralPart *centralManagerPart;
// centralManager使用，保存收听的peripherals
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *peripherals;

// 广播信息,外设属性
@property (nonatomic, assign) BOOL advertisingIsOn;
@property (nonatomic, strong) NSString *serviceUUID;
@property (nonatomic, strong) NSString *characterUUID;
@property (nonatomic, strong) NSString *advertisingTitle;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) CBMutableService *service;
@property (nonatomic, strong) UILabel *advStatusLabel;

//central 属性
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *deviceArray;
@property (nonatomic, strong) peripheralTableViewController *peripheralTableViewVC;

@end

@implementation ViewController

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self.centralManagerPart && self.peripherals && self.peripherals.count !=0) {
        [self.centralManagerPart cancelConnection:self.peripherals];
    }
}

//初始化变量，放在viewDidLoad最后
- (void) initProperties {
    
    //默认模式为聊天
    self.debugMode = NO;
    //默认debug模式下为 非中心
    self.isRealCentral = NO;
    //默认聊天用户名
    self.userName.text = @"你大哥";
    
    //默认debuger用户名
    self.debugerName.text = @"你二哥";
    
    self.centralIsOK = NO;
    self.peripheralIsOK = NO;
    
    self.isWorking = NO;
}

- (void)loadView {
    [super loadView];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.backgroundColor = [UIColor brownColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
//    [self.navigationController.navigationItem setTitle:@"呵呵"];
    [self.navigationItem setTitle:@"呵呵呵哒"];
    // 初始化外设管理中心
    [self initPeripheralStatus];
    
    // 初始化central管理中心
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.debugModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 180, 30)];
//    debugModeLabel.layer.borderWidth = 2;
//    debugModeLabel.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:self.debugModeLabel];
    
    self.changeModeBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 10, 150, 30)];
    self.changeModeBtn.backgroundColor = [UIColor greenColor];
    [self.changeModeBtn setTitle:@"点击切换mode" forState:UIControlStateNormal];
    [self.view addSubview:self.changeModeBtn];
    [self.changeModeBtn addTarget:self action:@selector(changeModeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    //role
    self.debugRoleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 45, 180, 30)];
    [self.view addSubview:self.debugRoleLabel];

    //role按钮
    self.changeRoleBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 45, 150, 30)];
    self.changeRoleBtn.backgroundColor = [UIColor greenColor];
    [self.changeRoleBtn setTitle:@"点击切换role" forState:UIControlStateNormal];
    [self.view addSubview:self.changeRoleBtn];
    [self.changeRoleBtn addTarget:self action:@selector(changeRoleBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    //user name
    self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 45, 120, 30)];
    self.userNameLabel.text = @"聊天名称：";
    [self.view addSubview:self.userNameLabel];
    
    self.userName = [[UITextField alloc] initWithFrame:CGRectMake(140, 45, 180, 30)];
    self.userName.backgroundColor = [UIColor blueColor];
    self.userName.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.userName];
    
    self.debugerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 80, 150, 30)];
    self.debugerNameLabel.text = @"debuger名称：";
    [self.view addSubview:self.debugerNameLabel];
    
    self.debugerName = [[UITextField alloc] initWithFrame:CGRectMake(170, 80, 150, 30)];
    [self.view addSubview:self.debugerName];
    self.debugerName.textAlignment = NSTextAlignmentCenter;
    self.debugerName.backgroundColor = [UIColor blueColor];
    
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 115, 70, 30)];
    [statusLabel setText:@"状态："];
    [self.view addSubview:statusLabel];
    
    self.advStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(150, 115, 100, 30)];
    self.advStatusLabel.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.advStatusLabel];
    self.advStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.advertisingIsOn = NO;
    
    self.startAdvBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 160, 150, 80)];
    self.startAdvBtn.backgroundColor = [UIColor redColor];
    self.startAdvBtn.layer.borderWidth = 2;
    self.startAdvBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [self.startAdvBtn addTarget:self action:@selector(startBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.startAdvBtn setTitle:@"点击开始工作" forState:UIControlStateNormal];
    [self.view addSubview:self.startAdvBtn];
    
    self.stopAdvBtn = [[UIButton alloc] initWithFrame:CGRectMake(180, 160, 150, 80)];
    self.stopAdvBtn.backgroundColor = [UIColor redColor];
    self.stopAdvBtn.layer.borderWidth = 2;
    self.stopAdvBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [self.stopAdvBtn addTarget:self action:@selector(stopBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.stopAdvBtn setTitle:@"点击停止工作" forState:UIControlStateNormal];
    [self.view addSubview:self.stopAdvBtn];
    
    UITapGestureRecognizer *backgroundTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTouch)];
    [self.view addGestureRecognizer:backgroundTouch];
    //初始化变量
    [self initProperties];
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - 属性写方法
// 切换debug mode并显示
- (void) setDebugMode:(BOOL)debugMode {
    
    _debugMode = debugMode;
    if(_debugMode) {
        
        if(self.debugModeLabel) {
            [self.debugModeLabel setText:@"当前mode：调试模式"];
            //显示 debug模式下的 role选项
            self.changeRoleBtn.hidden = NO;
            self.debugRoleLabel.hidden = NO;
            //不显示聊天昵称
            self.userNameLabel.hidden = YES;
            self.userName.hidden = YES;
        }
    }
    else {
        if(self.debugModeLabel) {
            
            [self.debugModeLabel setText:@"当前mode：聊天模式"];
            
            //不显示 debug模式下的 role选项
            self.changeRoleBtn.hidden = YES;
            self.debugRoleLabel.hidden = YES;
            //显示聊天昵称
            self.userNameLabel.hidden = NO;
            self.userName.hidden = NO;
        }
    }
}

// 切换 debug mode下role并显示
- (void) setIsRealCentral:(BOOL)isRealCentral {
    
    _isRealCentral = isRealCentral;
    if(isRealCentral) {
        
        [self.debugRoleLabel setText:@"当前role：被调试"];
    }
    else {
        
        [self.debugRoleLabel setText:@"当前role：调试者"];
    }
}

- (void)setAdvertisingIsOn:(BOOL)advertisingIsOn {
    
    _advertisingIsOn = advertisingIsOn;
    if(advertisingIsOn) {
        [self.advStatusLabel setText: @"开始广播"];
    }
    else {
        [self.advStatusLabel setText: @"广播关闭"];
    }
}

// 针对工作状态  调整开始/停止按钮状态
- (void) setIsWorking:(BOOL)isWorking {
    
    _isWorking = isWorking;
    if(isWorking) {
        
        self.startAdvBtn.alpha = 0.3;
        self.startAdvBtn.enabled = NO;
        
        self.stopAdvBtn.alpha = 1;
        self.stopAdvBtn.enabled = YES;
        
        self.changeRoleBtn.alpha = 0.3;
        self.changeRoleBtn.enabled = NO;
        
        self.changeModeBtn.alpha = 0.3;
        self.changeModeBtn.enabled = NO;
        
        self.userName.enabled = NO;
        self.debugerName.enabled = NO;
    }
    else {
        
        self.startAdvBtn.alpha = 1;
        self.startAdvBtn.enabled = YES;
        
        self.stopAdvBtn.alpha = 0.3;
        self.stopAdvBtn.enabled = NO;
        
        self.changeRoleBtn.alpha = 1;
        self.changeRoleBtn.enabled = YES;
        
        self.changeModeBtn.alpha = 1;
        self.changeModeBtn.enabled = YES;
        
        self.userName.enabled = YES;
        self.debugerName.enabled = YES;
    }
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - click action 点击事件
//背景点击
- (void) bgViewTouch {
    
    [self.view endEditing:YES];
}

// 开始工作按钮
- (void) startBtnClick {
    
    if(self.debugMode) {
        
        //调试模式广播内容前缀
        NSString *debugModeAdvPrifix = @"debug";
        
        // 调试模式--被调试者
        if(self.isRealCentral) {
            //开始广播
            if(self.advertisingTitle && self.advertisingTitle.length){
                
                //debug模式的peripheral，广播前缀--debug
                NSString *debugAdvString = [debugModeAdvPrifix stringByAppendingString:self.advertisingTitle];
                [self.peripheralManagerPart startAdvertisingWithTitle:debugAdvString service:self.service];
            }
            //中心关闭
//            if(self.centralManagerPart)
            [self.centralManagerPart stopCentralManager:self.peripherals];
            [self.peripherals removeAllObjects];
        }
        //调试模式--调试者
        else {
            //调试者 开启central
            [self initCentralStatus];
            if(!self.debugerName.text || self.debugerName.text.length==0) {
                
                UILabel *alertLabel = [[UILabel alloc] init];
                alertLabel.text = @"名字不能空！";
                [self.view addSubview:alertLabel];
                [alertLabel setFrame:CGRectMake(SCREEN_WIDTH/2 -75, SCREEN_HEIGTH/2 -50, 150, 100)];
                [UIView animateWithDuration:0.9 animations:^{
                    alertLabel.alpha = 0;
                } completion:^(BOOL finished) {
                    [alertLabel removeFromSuperview];
                }];
                return;
            }
            //关闭广播 ？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？外设端主动关闭
            if(self.peripheralManagerPart && self.centralManagerPart.centralStatus)
            {
                [self.peripheralManagerPart stopAdvertising];
                [self.centrals removeAllObjects];
            }
            //central开始工作
            [self.centralManagerPart startScanPeripheral];
        }
    }
    
    //聊天模式
    else {
        
        //聊天模式 都开启central
        [self initCentralStatus];
        if(!self.userName.text || self.userName.text.length==0) {
            
            UILabel *alertLabel = [[UILabel alloc] init];
            alertLabel.text = @"名字不能空！";
            [self.view addSubview:alertLabel];
            [alertLabel setFrame:CGRectMake(SCREEN_WIDTH/2 -75, SCREEN_HEIGTH/2 -50, 150, 100)];
            [UIView animateWithDuration:0.9 animations:^{
                alertLabel.alpha = 0;
            } completion:^(BOOL finished) {
                [alertLabel removeFromSuperview];
            }];
            return;
        }
        
        //聊天模式central
        //central开始工作
        [self.centralManagerPart startScanPeripheral];
        
        self.peripheralTableViewVC = [[peripheralTableViewController alloc]initWithTableDelegate:self];
        [self.navigationController pushViewController:self.peripheralTableViewVC animated:YES];
        
        //聊天模式peripheral
        //peripheral，广播前缀--chat
        NSString *chatModePrifix = @"chat";
        NSString *debugAdvString = [chatModePrifix stringByAppendingString:self.userName.text];
        [self.peripheralManagerPart startAdvertisingWithTitle:debugAdvString service:self.service];
    }
    
    self.isWorking = YES;
}

- (void) stopBtnClick {
    
    [self.centralManagerPart stopCentralManager:self.peripherals];
    
    [self.peripheralManagerPart stopAdvertising];
    
    self.isWorking = NO;
}

// 切换mode按钮
- (void) changeModeBtnClick {
    
    BOOL temp = self.debugMode;
    self.debugMode = !temp;
}

// 切换角色按钮
- (void) changeRoleBtnClick {
    
    BOOL temp = self.isRealCentral;
    self.isRealCentral = !temp;
}

#pragma mark - 初始化操作

- (void) initPeripheralStatus {
    
    self.serviceUUID = @"68753A44-4D6F-1226-9C60-0050E4C00067";
    self.characterUUID = @"68753A44-4D6F-1226-9C60-0050E4C00068";
    self.advertisingTitle = @"呵呵哒的debug外设";
    self.advertisingIsOn = NO;
    self.peripheralManagerPart = [peripheralPart sharePeripheralWithDelegate:self];
    self.centrals = [[NSMutableArray alloc] init];
    self.centralsMaxMessageLength = [[NSMutableArray alloc] init];
    
    [self setService];
}

- (void) initCentralStatus {
    
    self.centralManagerPart = [centralPart shareCentralWithDelegate:self];
    self.peripherals = [[NSMutableArray alloc] init];
}

// 外设支持的服务，以及服务中的特征值
- (void) setService {
    
    if(!self.service) {
        self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:self.serviceUUID] primary:YES];//作为外设的主要服务
    }
    if(!self.characteristic) {
        self.characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:self.characterUUID] properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];//设为通知
    }
    
    //保存当前自定义的特征值  以便往里写数据
    [self.service setCharacteristics: @[self.characteristic]];
    
}

#pragma mark - CBPeripheralManagerDelegate

// 初次调用--在初始化 peripheralManager变量时时即调用，所以可以在判断状态之后进行 peripheral manager相关初始化
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    /**
     CBManagerStateUnknown = 0,
     CBManagerStateResetting,
     CBManagerStateUnsupported,
     CBManagerStateUnauthorized,
     CBManagerStatePoweredOff,
     CBManagerStatePoweredOn,
     */
    if (@available(iOS 10.0, *)) {
        //呵呵
    }
    else
    {
        return;
    }
    
    switch (peripheral.state) {
        case CBManagerStatePoweredOff:
            
            NSLog(@" 蓝牙关闭 ");
            break;
        case CBManagerStatePoweredOn:
            
            NSLog(@" 蓝牙状态正常 ");
            // 设置service和characteristic
            break;
        case CBManagerStateUnauthorized:
            
            break;
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(nonnull CBService *)service error:(nullable NSError *)error {
    
    if(error)
    {
        NSLog(@" 遇到麻烦了 ");
        return;
    }
    
    NSLog(@" 添加服务成功  可以随时开启广播 ");
    NSLog(@" 添加的服务是：%@",service);
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    
    if(error)
    {
        NSLog(@" 开始广播, 但遇到错误 ");
        NSLog(@" 错误内容是: %@ ", [error localizedDescription]);
        return;
    }
    
    NSLog(@" 开始广告成功 ");
    self.advertisingIsOn = YES;
}

// 记录订阅的 centrals
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    // 记录已订阅当前特征值的manager
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString: @"68753A44-4D6F-1226-9C60-0050E4C00068"]]) {
        [self.centrals addObject:central];
    }
    
    if(self.debugMode) {
        //debug模式 为外设时 central默认关闭
    }
    else {
        //聊天模式，只保留一个peripheral或central保持连接
        [self.centralManagerPart stopCentralManager:self.centrals];
    }
    
    // 表示当前连接的central 一次通知，能传送的最大长度 182 bytes ,cbperipheral没有此属性
    NSInteger maxLengthToSend = central.maximumUpdateValueLength;
    [self.centralsMaxMessageLength addObject:[NSNumber numberWithInteger:maxLengthToSend]];
    
    NSLog(@"当前连接manager端限制长度是：%ld",maxLengthToSend);
}

// 在central 关闭对当前特征的监听--在断开连接时候--调用！！！
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    
    for(NSInteger i=0; i<self.centrals.count; ++i)
    {
        if([central isEqual:[self.centrals objectAtIndex:i]])
        {
            [self.centrals removeObjectAtIndex:i];
            [self.centralsMaxMessageLength removeObjectAtIndex:i];
            break;
        }
    }
    NSLog(@" 对方取消订阅或者 主动断开 ");
}

// 表示收到读取请求  --调用时机不明确！！！！！！！！！！！！！！！！！！！！！
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    
    // 针对读请求，必须进行回复。----若实现了当前代理方法，则必须调用 如下方法进行回复。
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

// 外设收到写入数据----外设端实现双向通信
- (void) peripheralManager: (CBPeripheralManager *) peripheral didReceiveWriteRequests:(NSArray *) requests {
    
    // 测试 收到数据的长度最大值限制 --512 bytes
    //    NSData *recvData = ((CBATTRequest *)requests.lastObject).value;
    //    NSInteger length = recvData.length;
    
    
    // ？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？request参数数组
    CBATTRequest  *requestRecv = requests.lastObject;
    
    //测试 根据不同的central实现消息分类,进行有目标的通信--对方限制在订阅了特定characterictic
    CBCentral *centralRecv = requestRecv.central;
    NSInteger index = [self.centrals indexOfObject:centralRecv];
    
    NSString *response = [[ NSString alloc] initWithData:requestRecv.value encoding:NSUTF8StringEncoding];
    NSLog(@"回复内容：%@ ",response);
    
    switch (index) {
        case 0:
//            self.textReceived.text = [NSString stringWithFormat:@"收到manager1：%@ ",response];
            break;
        case 1:
//            self.textReceived2.text = [NSString stringWithFormat:@"收到manager2：%@ ",response];
            break;
    }
    
    // 表示当前外设  收到请求  并回复请求状态为成功
    // 根据当前值符合约定与否，返回相应的result error值，返回时间最迟10秒
    [peripheral respondToRequest:requestRecv withResult:CBATTErrorSuccess];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@" our center is %@",central);
    switch (central.state) {
        case CBManagerStatePoweredOn:
            
            NSLog(@"蓝牙当前可用");
            self.blueToothAvailable = YES;
            break;
        case CBManagerStatePoweredOff:
        {
            self.blueToothAvailable = NO;
            NSLog(@"蓝牙未打开");
            break;
        }
        case CBManagerStateUnsupported:
            NSLog(@"SDK不支持");
            self.blueToothAvailable = NO;
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"程序未授权");
            self.blueToothAvailable = NO;
            break;
        case CBManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            self.blueToothAvailable = NO;
            break;
        case CBManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            self.blueToothAvailable = NO;
            break;
        default:
            break;
    }
}

//扫描到设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    //开启广播时给出的当前外设名称
    if (peripheral.name.length <= 0) {
        return ;
    }
    
    NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
    
//    第一步筛选是根据外设名称，一定是debug模式或chat模式 ---放在点击设备时进行
//    if ([peripheral.name hasPrefix:@"debug"]|| ![peripheral.name hasPrefix:@"chat"]) {
//
//        return;
//    }
    if (self.deviceArray.count == 0) {
        
        //RSSI 表示信号响度参数
        [self.deviceArray addObject:dict];
    } else {
        BOOL isExist = NO;
        for (int i = 0; i < self.deviceArray.count; i++) {
            NSDictionary *dict = [self.deviceArray objectAtIndex:i];
            CBPeripheral *per = dict[@"peripheral"];
            if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                isExist = YES;
                NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
                [_deviceArray replaceObjectAtIndex:i withObject:dict];
            }
        }
        if( !isExist ) {
            [self.deviceArray addObject:dict];
        }
    }
    
    [self sortDeviceArray];
    [self.peripheralTableViewVC.peripheralTable reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@" 连接设备成功 ");
    
    //查找设备支持的服务 在其代理
    [peripheral discoverServices:nil];
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@" 连接设备失败了，因为内容是 ");
    NSLog(@"%@",error);
    //恢复点击
//    self.deviceTable.userInteractionEnabled = YES;
    
    //聊天模式，对方断开则自己也断开
    if(!self.debugMode && [self.navigationController.topViewController isKindOfClass:[chatModeViewController class]]) {
        
        [self.navigationController popToViewController:self animated:YES];
    }
}

// 当前连接的外设不是由--cancelPeripheralConnection--主动断开连接而断开。 具体原因会显示在 error中!!!!!!!!!!!!!!!!!
// 查看error内容!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    // 连接需要配对的设备，取消配对请求之后，---对方主动关闭连接?????如何做到的????????????????????????????????????????
    if(error)
    {
        NSLog(@"断开连接的原因是%@",error);
    }
    NSLog(@" 当前连接关闭--不管主动非主动都走此方法。。。 ");
    
    //聊天模式，对方断开则自己也断开
    if(!self.debugMode && [self.navigationController.topViewController isKindOfClass:[chatModeViewController class]]) {
        
        [self.navigationController popToViewController:self animated:YES];
    }
}

#pragma mark - CBPeripheralDelegate

// 查找peripheral 设备支持的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    
    if (error) {
        NSLog(@"出错");
        return;
    }
    NSString *UUID = [peripheral.identifier UUIDString];
    NSLog(@"外设的UUID--:%@",UUID);
    
    CBUUID *cbUUID = [CBUUID UUIDWithString:UUID];
    NSLog(@"外设的CBUUID--:%@",cbUUID);
    
    //self.servicesArray = peripheral.services;
    //[self.servicesTable reloadData];
    
    for (CBService *service in peripheral.services) {
        NSLog(@"service:%@",service.UUID);
        
        //如果我们知道要查询的特性的CBUUID，可以在参数一中传入CBUUID数组---我们特么当然知道，自己编的嘛
        NSString *str = [NSString stringWithFormat:@"UUID:%@",service.UUID];
        NSLog(@"%@",str);
        if([service.UUID isEqual:[CBUUID UUIDWithString: @"68753A44-4D6F-1226-9C60-0050E4C00067"]])
        {
            [peripheral discoverCharacteristics:nil forService:service];
            NSString *serviceText = [NSString stringWithFormat:@"连接服务ID：%@",service.UUID];
            NSLog(@"%@",serviceText);
        }
    }
    
}

/**
 函数中参数--服务 和上面代理方法中的服务有区别吗？？？
 ***/

//函数作用是发现并返回  外设中的某个服务的所有特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    
    if(error)
    {
        NSLog(@" 出错了 ");
        return;
    }
    for (CBCharacteristic *character in service.characteristics) {
        
        //筛选特征值  将特征值加入监听
        if([character.UUID isEqual:[CBUUID UUIDWithString: @"68753A44-4D6F-1226-9C60-0050E4C00068"]])
        {
            // 需要监听的特征值  一定要手动添加监听  之后收到特征值的改变，才会走相应代理方法
            // 相应的--外设会回调 - (void)peripheralManager: central: didSubscribeToCharacteristic: 方法记录此时的central
            [peripheral setNotifyValue:YES forCharacteristic:character];
            
            NSInteger nameIndex = 0;
            if([peripheral.name hasPrefix:@"chat"]) {
                nameIndex = 4;
            }
            else {
                nameIndex = 5;
            }
            NSString *peerName = [peripheral.name substringFromIndex:nameIndex];
            self.chatVC = [[chatModeViewController alloc] initWithPeerName:peerName];
            [self.navigationController pushViewController:self.chatVC animated:YES];
            
            //聊天模式--此时关闭peripheral部分
            if(!self.debugMode) {
                
                if(self.peripheralManagerPart) {
                    
                    //走不走相应状态改变回调？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？
                    [self.peripheralManagerPart stopAdvertising];
                }
            }
            
            return;
        }
        
        CBCharacteristicProperties property = character.properties;
        if(property & CBCharacteristicPropertyBroadcast)
        {
            // 理解广播特征
            NSLog(@" 特征是广播特征，特征内容是： %@ ",character);
        }
        if(property & CBCharacteristicPropertyRead) {
            
            // 特征可读 表示外设一开始就有数据
            NSLog(@" 表示当前外设可能发送了数据，特征内容是： %@ ",character);
            
            // 读取当前服务的特征内数据
            [peripheral readValueForCharacteristic:character];
        }
        if(property & CBCharacteristicPropertyWriteWithoutResponse) {
            
            // 表示当前服务的特征允许写入数据
        }
        if(property & CBCharacteristicPropertyWrite) {
            
            // 表示当前特征可写，且写入之后，需要对方回复--当前外设的属性是可读且需要回复，则写入数据之后，超时10秒等待外设做出回应
            // 否则didWriteValueForCharacteristic，状态为未知错误
        }
        else
        {
            
        }
        if(property & CBCharacteristicPropertyNotify) {
            
        }
        if(property & CBCharacteristicPropertyIndicate) {
            
        }
        if(property & CBCharacteristicPropertyAuthenticatedSignedWrites) {
            
        }
        if(property & CBCharacteristicPropertyExtendedProperties) {
            
        }
        if(property & CBCharacteristicPropertyNotifyEncryptionRequired) {
            
        }
        if(property & CBCharacteristicPropertyIndicateEncryptionRequired) {
            
        }
    }
}



//根据信号响度排序 peripherals
- (void)sortDeviceArray {
    
    if(self.deviceArray.count < 2)
    {
        return;
    }
    [self.deviceArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSDictionary *ob1 = (NSDictionary *)obj1;
        NSDictionary *ob2 = (NSDictionary *)obj2;
        
        NSNumber *RSSI1 = [ob1 objectForKey:@"RSSI"];
        NSNumber *RSSI2 = [ob2 objectForKey:@"RSSI"];
        
        if(RSSI1 >= RSSI2){
            return NSOrderedDescending;
        }
        else {
            return NSOrderedSame;
        }
    }];
}

#pragma mark - timer 定时刷新设备表

//timer 的回调函数
- (void) timerTick {
    
    if( !self.blueToothAvailable)
    {
        [self.peripheralTableViewVC.autoScanTimer invalidate];
        self.peripheralTableViewVC.autoScanTimer = nil;
        self.peripheralTableViewVC.refreshTimes = 0;
        NSString *text = [NSString stringWithFormat:@"%ld次",self.peripheralTableViewVC.refreshTimes];
        NSLog(@"%@",text);
//        [self.autoScanTimes setText:text];
        
//        [noBlueToothAlert shareAlertWithDelegate:self];
        NSLog(@" 当前蓝牙不可用 ");
        return;
    }
    
    if(!self.peripheralTableViewVC.view.window)
    {
        [self.peripheralTableViewVC.autoScanTimer invalidate];
        self.peripheralTableViewVC.autoScanTimer = nil;
    }
    
    //未提供 在未连接的情况下 检测外设是否存在的接口。所以定时清空列表
    self.peripheralTableViewVC.refreshTimes++;
    if(self.peripheralTableViewVC.refreshTimes % 4 == 0)
    {
        self.deviceArray = [[NSMutableArray alloc]init];
        [self.peripheralTableViewVC.peripheralTable reloadData];
    }
    NSString *text = [NSString stringWithFormat:@"%ld次",self.peripheralTableViewVC.refreshTimes];
    NSLog(@"%@",text);
//    [self.autoScanTimes setText:text];
    
    //需要手动调用!!!!!!!!!!!
    [self.centralManagerPart startScanPeripheral];
}

#pragma mark - tableViewDelegate  datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.deviceArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    deviceCell *retCell = [tableView dequeueReusableCellWithIdentifier:@"deviceCell" forIndexPath:indexPath];
    
    NSInteger index = indexPath.row;
    [retCell updateCellWithInfo:self.deviceArray[index]];
    
    return retCell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index = indexPath.row;
    CBPeripheral *selectedPeripheral = [self.deviceArray[index] objectForKey:@"peripheral"];
    
    if ([selectedPeripheral.name hasPrefix:@"debug"]|| ![selectedPeripheral.name hasPrefix:@"chat"]) {
        
        return;
    }
    
    //连接状态在回调中显示
    [self.centralManagerPart connectPeripheral:selectedPeripheral
                                    withOption:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}];
    
}



@end
