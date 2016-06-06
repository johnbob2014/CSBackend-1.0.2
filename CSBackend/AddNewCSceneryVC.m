//
//  AddNewCSceneryVC.m
//  CSBackend
//
//  Created by 张保国 on 16/1/24.
//  Copyright © 2016年 ZhangBaoGuo. All rights reserved.
//

#import "AddNewCSceneryVC.h"
#import "PictureInfoVC.h"
#import "SceneryModel.h"
#import "CSCoreDataConfig.h"
#import "AppDelegate.h"
#import <QNUploadManager.h>

@interface AddNewCSceneryVC ()
@property (weak) IBOutlet NSPopUpButton *provincePopUp;

@property (strong,nonatomic) NSArray *filePathArray;

@property (weak) IBOutlet NSButton *addPicturesBtn;

@property (strong) IBOutlet NSTextView *infoTV;
@property (strong,nonatomic) NSString *info;

//@property (nonatomic) BOOL hasRenamedJSON;
@property (strong,nonatomic) NSString *addedSceneryJSONPath;
@property (strong,nonatomic) NSString *addedSceneryThumbnailPicturePath;

@property (nonatomic,strong) CProvince *currentCProvince;
@property (nonatomic,strong) CScenery *addedCScenery;
@property (weak) IBOutlet NSTextField *provinceNameTF;
@property (weak) IBOutlet NSTextField *sceneryNameTF;


@property (weak) IBOutlet NSTextField *addedProvinceNameTF;

@end

@implementation AddNewCSceneryVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.addPicturesBtn.enabled=NO;
    [self refreshPopUP];
    //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sceneryModelRefreshed:) name:kSceneryModelRefreshedNotification object:nil];
    
}

-(void)refreshPopUP{
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
    self.provinceNameTF.stringValue=self.currentCProvince.name;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)addNewSceneryBtn:(NSButton *)sender {
    NSString *sceneryName=self.sceneryNameTF.stringValue;
    if (self.currentCProvince) {
        if (sceneryName && ![sceneryName isEqualToString:@""]) {
            self.addedCScenery=[CScenery initWithName:sceneryName inProvince:self.currentCProvince inManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
            
            self.addedCScenery.updateUnix=[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
            
            self.addedCScenery.provinceName=self.currentCProvince.name;
            
            NSError *saveError;
            [[SceneryModel sharedModel].managedObjectContext save:&saveError];
            if (!saveError) {
                self.addPicturesBtn.enabled=YES;
                
                self.info=[NSString stringWithFormat:@"新风景 %@-%@ 添加成功.请添加照片！",self.addedCScenery.name,self.currentCProvince.name];
            }else{
                self.info=@"添加失败!!!";
            }
            
            
        }else{
            self.info=@"新风景添加失败,风景名称不能为空！";
        }
    }else{
        self.info=@"新风景添加失败,请选择所在省份！";
    }
}

- (IBAction)addPicturesBtn:(NSButton *)sender {
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    
    [openPanel setTitle:@"Choose a File or Folder"];//setTitle为NSWindow的方法，它是openPanel 的父类
    
    [openPanel setAllowsMultipleSelection:YES];//允许多选
    
    [openPanel setCanChooseDirectories:NO];//默认不可以选文件夹，可选任何格式文件
    
    [openPanel setCanChooseFiles:YES];
    NSInteger i=[openPanel runModal];//显示openPanel
    
    if(i==NSModalResponseOK){
        NSMutableArray *array=[NSMutableArray new];
        
        for (NSURL *aURL in [openPanel URLs]) {
            [array addObject:[aURL path]];
        }
        
        if ([array count]>=1) {
            self.filePathArray=[NSArray arrayWithArray:array];
            
            [self performSegueWithIdentifier:@"showPictureInfo" sender:self];
        }
    }else if (i==NSModalResponseCancel){
        
    }
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showPictureInfo"]) {
        PictureInfoVC *plvc=segue.destinationController;
        plvc.filePathArray=self.filePathArray;
        plvc.cScenery=self.addedCScenery;
    }
}




- (IBAction)deleteJSONBtn:(NSButton *)sender {
    NSString *jsonName=[self.addedSceneryJSONPath lastPathComponent];
    if (jsonName) {
        NSTimeInterval timeStamp=[[NSDate date] timeIntervalSince1970];
        NSString *oldFileName=[NSString stringWithFormat:@"%@-%0.f",jsonName,timeStamp];
        [[Qiniu sharedQN] syncMoveFromFile:jsonName toFile:oldFileName];
        self.info=@"景点JSON文件已重命名.";
    }
    
}

- (IBAction)createJSONBtn:(NSButton *)sender {
    self.addedSceneryJSONPath=[[SceneryModel sharedModel] createCSceneryJSONFile:self.addedCScenery];
    if (self.addedSceneryJSONPath) {
        self.info=[NSString stringWithFormat:@"新JOSN文件已生成:%@",self.addedSceneryJSONPath];
        
        NSString *lastPathComponent=[self.addedSceneryJSONPath lastPathComponent];
        NSString *thumbnailPictureName=[self.addedCScenery.name stringByAppendingString:@".JPG"];
        self.addedSceneryThumbnailPicturePath=[self.addedSceneryJSONPath stringByReplacingOccurrencesOfString:lastPathComponent withString:thumbnailPictureName];
        self.info=self.addedSceneryThumbnailPicturePath;
        self.info=@"请确认图片存在！";
    }
}

- (IBAction)uploadJSONBtn:(NSButton *)sender {
    if (self.addedSceneryJSONPath!=nil) {
        QNUploadManager *um=[[QNUploadManager alloc]init];
        NSString *upToken=[[Qiniu sharedQN] upToken];
        
        [um putFile:self.addedSceneryJSONPath key:[self.addedSceneryJSONPath lastPathComponent] token:upToken complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            self.info=[NSString stringWithFormat:@"景点JSON文件上传完成:%@",key];
            
            NSLog(@"景点JSON文件上传完成:%@",key);
            
        } option:nil];
        
        [um putFile:self.addedSceneryThumbnailPicturePath key:[self.addedSceneryThumbnailPicturePath lastPathComponent] token:upToken complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            self.info=[NSString stringWithFormat:@"景点图片上传完成:%@",key];
            
            NSLog(@"景点图片上传完成:%@",key);
            
        } option:nil];
        
    }else{
        self.info=@"尚未生成新JSON文件!";
    }

    
}

- (IBAction)addNewCProvinceBtn:(NSButton *)sender {
    NSString *provinceName=self.addedProvinceNameTF.stringValue;
    if (provinceName && ![provinceName isEqualToString:@""]) {
        CProvince *cProvince=[CProvince initWithName:provinceName inManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
        
        NSError *saveError;
        [[SceneryModel sharedModel].managedObjectContext save:&saveError];
        if (!saveError) {
            self.info=[NSString stringWithFormat:@"新省份 %@ 添加成功.请重新选择省份！",cProvince.name];
            self.currentCProvince=nil;
            [self refreshPopUP];
        }else{
            self.info=@"添加失败!!!";
        }

        
    }else{
        self.info=@"新省份添加失败！";
    }
}


-(void)setInfo:(NSString *)info{
    _info=info;
    self.infoTV.string=[NSString stringWithFormat:@"%@\n%@",info,self.infoTV.string];
}

- (IBAction)clearinfoTVBtn:(NSButton *)sender {
    self.infoTV.string=@"";
}


@end
