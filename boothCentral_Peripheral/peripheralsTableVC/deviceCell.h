//
//  deviceCell.h
//  boothCentral_Peripheral
//
//  Created by ChenHong on 2018/3/3.
//  Copyright © 2018年 macro-c. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface deviceCell : UITableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void) updateCellWithInfo :(NSDictionary *)info;

@end
