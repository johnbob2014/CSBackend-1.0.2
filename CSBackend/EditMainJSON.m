//
//  EditMainJSON.m
//  CSBackend
//
//  Created by 张保国 on 16/1/24.
//  Copyright © 2016年 ZhangBaoGuo. All rights reserved.
//

#import "EditMainJSON.h"
#import "SceneryModel.h"
#import "AppDelegate.h"
#import <QNUploadManager.h>
#import "CSCoreDataConfig.h"

@interface EditMainJSON ()

@property (weak) IBOutlet NSPopUpButton *provincePopUp;
@property (weak) IBOutlet NSPopUpButton *sceneryPopUp;

@property (weak) IBOutlet NSButton *deleteJSONBtn;

@property (weak) IBOutlet NSTextField *currentInfoTF;

@property (strong) IBOutlet NSTextView *infoTV;
@property (strong,nonatomic) NSString *info;

@property (nonatomic) BOOL hasRenamedJSON;
@property (strong,nonatomic) NSString *lastMenuJSONPath;
@property (strong,nonatomic) NSString *lastDeleteCSceneryJSONName;

@property (nonatomic,strong) CProvince *currentCProvince;
@property (nonatomic,strong) CScenery *currentCScenery;

@end

@implementation EditMainJSON

-(void)setInfo:(NSString *)info{
    _info=info;
    self.infoTV.string=[NSString stringWithFormat:@"%@\n%@",info,self.infoTV.string];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self refreshPopUp];
}

-(void)refreshPopUp{
    NSMenu *provinceMenu=[self.provincePopUp menu];
    [provinceMenu removeAllItems];
    
    NSArray *cProvinceArray=[CProvince cProvinceArrayInManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
    
    for (int i=0; i<[cProvinceArray count]; i++) {
        CProvince *cProvince=cProvinceArray[i];
        NSMenuItem *item=[[NSMenuItem alloc]initWithTitle:cProvince.name action:@selector(provincePopUpSelectedMenuItemChanged:) keyEquivalent:@""];
        //item.tag=i;
        [provinceMenu addItem:item];
    }
}

-(void)provincePopUpSelectedMenuItemChanged:(NSMenuItem *)sender{
    //NSLog(@"%@",sender);
    NSArray *cProvinceArray=[CProvince cProvinceArrayInManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
    NSMenu *provinceMenu=[self.provincePopUp menu];
    NSInteger selectedIndex=[provinceMenu indexOfItem:sender];
    self.currentCProvince=cProvinceArray[selectedIndex];

    NSSortDescriptor *aSort=[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSArray *cSceneryArray=[self.currentCProvince.sceneries sortedArrayUsingDescriptors:@[aSort]];
    NSMenu *sceneryMenu=[self.sceneryPopUp menu];
    [sceneryMenu removeAllItems];
    for (int i=0;i<[cSceneryArray count];i++) {
        CScenery *cScenery=cSceneryArray[i];
        NSMenuItem *item=[[NSMenuItem alloc]initWithTitle:cScenery.name action:@selector(sceneryPopUpSelectedMenuItemChanged:) keyEquivalent:@""];
        [sceneryMenu addItem:item];
    }
}

-(void)sceneryPopUpSelectedMenuItemChanged:(NSMenuItem *)sender{
    NSSortDescriptor *aSort=[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSArray *cSceneryArray=[self.currentCProvince.sceneries sortedArrayUsingDescriptors:@[aSort]];
    NSMenu *sceneryMenu=[self.sceneryPopUp menu];
    NSInteger selectedIndex=[sceneryMenu indexOfItem:sender];
    self.currentCScenery=cSceneryArray[selectedIndex];
    self.currentInfoTF.stringValue=[NSString stringWithFormat:@"%@-%@",self.currentCScenery.name,self.currentCProvince.name];
}

- (IBAction)deleteCSceneryBtn:(NSButton *)sender {
    
    NSString *temp=self.currentInfoTF.stringValue;
    self.lastDeleteCSceneryJSONName=[self.currentCScenery.name stringByAppendingString:@".json"];
    
    [[SceneryModel sharedModel].managedObjectContext deleteObject:self.currentCScenery];
    
    NSError *error;
    [[SceneryModel sharedModel].managedObjectContext save:&error];
    if (!error) {
        self.currentCScenery=nil;
        
        self.info=[temp stringByAppendingString:@" 删除完毕."];
        
        NSMenu *sceneryMenu=[self.sceneryPopUp menu];
        [sceneryMenu removeAllItems];
        self.currentInfoTF.stringValue=@"";

    }else{
        NSLog(@"%@",error);
        self.info=[error localizedDescription];
    }
}

- (IBAction)deleteCSceneryJSONBtn:(NSButton *)sender {
    if (self.lastDeleteCSceneryJSONName) {
        BOOL succeeded=[[Qiniu sharedQN]syncDeleteFile:self.lastDeleteCSceneryJSONName];
        if (succeeded) {
            self.info=[NSString stringWithFormat:@"%@ 删除完毕",self.lastDeleteCSceneryJSONName];
        }else{
            self.info=[NSString stringWithFormat:@"%@ 删除失败,服务器不存在该文件!",self.lastDeleteCSceneryJSONName];
        }
    }
}


#define ChinaSceneryDataFileName @"China-s-Scenery-Pro.json"
//- (void)sceneryModelRefreshed:(NSNotification *)noti{
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        self.info=@"数据刷新完成.";
//        self.deleteJSONBtn.enabled=YES;
//    });
//}

- (IBAction)deleteMenuJSONBtn:(NSButton *)sender {
    NSTimeInterval timeStamp=[[NSDate date] timeIntervalSince1970];
    NSString *oldFileName=[NSString stringWithFormat:@"%@-%0.f",ChinaSceneryDataFileName,timeStamp];
    [[Qiniu sharedQN] syncMoveFromFile:ChinaSceneryDataFileName toFile:oldFileName];
    self.hasRenamedJSON=YES;
    self.info=@"JSON文件已重命名.";
}

- (IBAction)createMenuJSONBtn:(NSButton *)sender {
    self.lastMenuJSONPath=[[SceneryModel sharedModel] createMainJSONFile];
    if (self.lastMenuJSONPath) {
        self.info=[NSString stringWithFormat:@"新JOSN文件已生成:%@",self.lastMenuJSONPath];
    }
}

- (IBAction)uploadMenuJSONBtn:(NSButton *)sender {
    if (self.hasRenamedJSON) {
        if (self.lastMenuJSONPath!=nil) {
            QNUploadManager *um=[[QNUploadManager alloc]init];
            NSString *upToken=[[Qiniu sharedQN] upToken];
            
            [um putFile:self.lastMenuJSONPath key:[self.lastMenuJSONPath lastPathComponent] token:upToken complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                self.info=[NSString stringWithFormat:@"JSON文件上传完成:%@",key];
                self.hasRenamedJSON=NO;
                NSLog(@"JSON文件上传完成:%@",key);
                self.hasRenamedJSON=NO;
            } option:nil];
        }else{
            self.info=@"尚未生成新JSON文件!";
        }
    }else{
        self.info=@"尚未重命名JSON文件!";
    }
    
}

- (IBAction)updateMenuJSONBtn:(NSButton *)sender {
    [self deleteMenuJSONBtn:nil];
    [self createMenuJSONBtn:nil];
    [self uploadMenuJSONBtn:nil];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

@end
