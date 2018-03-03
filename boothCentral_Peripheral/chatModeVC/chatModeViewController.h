//
//  chatModeViewController.h
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/2.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface chatModeViewController : UIViewController

// 聊天窗体需要对方名字
- (instancetype) initWithPeerName :(NSString *)peerName;

@end
