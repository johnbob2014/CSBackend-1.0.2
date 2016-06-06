//
//  PictureInfoVC.h
//  JSONCreater
//
//  Created by 张保国 on 15/12/27.
//  Copyright © 2015年 ZhangBaoGuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSCoreDataConfig.h"

@interface PictureInfoVC : NSViewController
@property (strong,nonatomic) NSArray *filePathArray;
@property (strong,nonatomic) CScenery *cScenery;
@end
