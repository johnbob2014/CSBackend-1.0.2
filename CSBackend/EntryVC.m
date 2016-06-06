//
//  EntryVC.m
//  CSBackend
//
//  Created by 张保国 on 16/1/24.
//  Copyright © 2016年 ZhangBaoGuo. All rights reserved.
//

#import "EntryVC.h"
#import "SceneryModel.h"

@interface EntryVC ()

@end

@implementation EntryVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
}

- (IBAction)editMainBtn:(NSButton *)sender {
    [self performSegueWithIdentifier:@"showEditMain" sender:nil];
}

- (IBAction)addNewCSceneryBtn:(NSButton *)sender {
    [self performSegueWithIdentifier:@"showAddNewCScenery" sender:nil];
}

@end
