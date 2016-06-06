//
//  PictureInfoVC.m
//  JSONCreater
//
//  Created by 张保国 on 15/12/27.
//  Copyright © 2015年 ZhangBaoGuo. All rights reserved.
//

#import "PictureInfoVC.h"
#import "AppDelegate.h"
#import "CSCoreDataConfig.h"
#import "SceneryModel.h"
#import <QiniuSDK.h>
#import "Qiniu.h"

@interface PictureInfoVC ()
@property (weak) IBOutlet NSTextField *nameTF;

@property (weak) IBOutlet NSTextField *widthTF;
@property (weak) IBOutlet NSTextField *heightTF;
@property (weak) IBOutlet NSTextField *detailTF;

@property (weak) IBOutlet NSImageView *imageView;

@property (weak) IBOutlet NSButton *nextButton;
@property (weak) IBOutlet NSTextField *indexTF;
@property (strong) IBOutlet NSTextView *infoTV;
@property (strong,nonatomic) NSString *info;

@property (assign,nonatomic) int currentIndex;
//@property (strong,nonatomic) NSString *lastJSONPath;
@property (assign,nonatomic) int addedPictureCount;

@end

@implementation PictureInfoVC

#pragma mark init
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.currentIndex=0;
    self.nextButton.hidden=YES;
    self.indexTF.editable=NO;
    self.addedPictureCount=0;
    
    //self.detailTF
    self.detailTF.stringValue=[NSString stringWithFormat:@"%@——",self.cScenery.name];
}

//-(void)initPopUp{
//    NSArray *cProvinceArray=[CProvince cProvinceArrayInManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
//    NSMenu *provinceMenu=[self.provincePopUp menu];
//    for (int i=0; i<[cProvinceArray count]; i++) {
//        CProvince *cProvince=cProvinceArray[i];
//        NSMenuItem *item=[[NSMenuItem alloc]initWithTitle:cProvince.name action:@selector(provincePopUpSelectedMenuItemChanged:) keyEquivalent:@""];
//        //item.tag=i;
//        [provinceMenu addItem:item];
//    }
//}
//
//-(void)provincePopUpSelectedMenuItemChanged:(NSMenuItem *)sender{
//    //NSLog(@"%@",sender);
//    NSArray *cProvinceArray=[CProvince cProvinceArrayInManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
//    NSMenu *provinceMenu=[self.provincePopUp menu];
//    NSInteger selectedIndex=[provinceMenu indexOfItem:sender];
//    self.currentCProvince=cProvinceArray[selectedIndex];
//    
//    NSSortDescriptor *aSort=[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
//    NSArray *cSceneryArray=[self.currentCProvince.sceneries sortedArrayUsingDescriptors:@[aSort]];
//    NSMenu *sceneryMenu=[self.sceneryPopUp menu];
//    [sceneryMenu removeAllItems];
//    for (int i=0;i<[cSceneryArray count];i++) {
//        CScenery *cScenery=cSceneryArray[i];
//        NSMenuItem *item=[[NSMenuItem alloc]initWithTitle:cScenery.name action:@selector(sceneryPopUpSelectedMenuItemChanged:) keyEquivalent:@""];
//        [sceneryMenu addItem:item];
//    }
//}
//
//-(void)sceneryPopUpSelectedMenuItemChanged:(NSMenuItem *)sender{
//    NSSortDescriptor *aSort=[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
//    NSArray *cSceneryArray=[self.currentCProvince.sceneries sortedArrayUsingDescriptors:@[aSort]];
//    NSMenu *sceneryMenu=[self.sceneryPopUp menu];
//    NSInteger selectedIndex=[sceneryMenu indexOfItem:sender];
//    self.currentCScenery=cSceneryArray[selectedIndex];
//    self.detailTF.stringValue=[NSString stringWithFormat:@"%@——",self.currentCScenery.name];
//}

#pragma mark Getter&Setter

-(void)setCurrentIndex:(int)currentIndex{
    if (currentIndex<=[self.filePathArray count]-1) {
        _currentIndex=currentIndex;
        [self showCurrentPictureInfo];
    }else{
        self.info=[NSString stringWithFormat:@"超出范围 currentIndex=%d",currentIndex];
        NSLog(@"超出范围 currentIndex=%d",currentIndex);
    }
}

-(void)setInfo:(NSString *)info{
    _info=info;
    self.infoTV.string=[NSString stringWithFormat:@"%@\n%@",info,self.infoTV.string];
}

#pragma mark - showCurrentPictureInfo
-(void)showCurrentPictureInfo{
    NSString *filePath=self.filePathArray[self.currentIndex];
    NSImage* img = [[NSImage alloc]initWithContentsOfFile:filePath];
    
    NSBitmapImageRep* raw_img = [NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]];
    
    self.nameTF.stringValue=[filePath lastPathComponent];
    self.widthTF.stringValue=[NSString stringWithFormat:@"%0.f",raw_img.size.width];
    self.heightTF.stringValue=[NSString stringWithFormat:@"%0.f",raw_img.size.height];
    self.detailTF.stringValue=[NSString stringWithFormat:@"%@——",self.cScenery.name];
    
    self.imageView.image=[[NSImage alloc]initWithContentsOfFile:filePath];
    self.indexTF.stringValue=[NSString stringWithFormat:@"%d/%lu 已保存CPictuer数:%d",self.currentIndex +1,(unsigned long)[self.filePathArray count],self.addedPictureCount];
}

#pragma mark - User Action
- (IBAction)saveBtn:(NSButton *)sender {
    [self addCPicture];
    [self nextBtn:nil];
}

- (IBAction)nextBtn:(NSButton *)sender {
    self.currentIndex+=1;
}

- (IBAction)previousBtn:(id)sender {
    self.currentIndex-=1;
}


- (IBAction)uploadPictureBtn:(NSButton *)sender {
    QNUploadManager *um=[[QNUploadManager alloc]init];
    NSString *upToken=[[Qiniu sharedQN] upToken];
    
    __block int hdIndex=0;
    __block int sdIndex=0;
    int total=(int)[self.filePathArray count];
    for (NSString *filePath in self.filePathArray) {
        
        [um putFile:filePath key:[filePath lastPathComponent] token:upToken complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            hdIndex++;
            self.info=[NSString stringWithFormat:@"Picture %d/%d Upload Complete: %@",hdIndex,total,key];
            NSLog(@"Picture %d/%d Upload Complete: %@",hdIndex,total,key);
        } option:nil];
        
        NSString *sdFilePath=[[filePath stringByDeletingLastPathComponent] stringByAppendingString:[NSString stringWithFormat:@"/SD-%@",[filePath lastPathComponent]]];
        
        [um putFile:sdFilePath key:[sdFilePath lastPathComponent] token:upToken complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            sdIndex++;
            self.info=[NSString stringWithFormat:@"SD-Picture %d/%d Upload Complete: %@",sdIndex,total,key];
            NSLog(@"SD-Picture %d/%d Upload Complete: %@",sdIndex,total,key);
        } option:nil];
        
    }

}

#pragma mark Save
- (void)addCPicture{
    CPictuer *cp=[CPictuer initWithName:self.nameTF.stringValue inScenery:self.cScenery inManagedObjectContext:[SceneryModel sharedModel].managedObjectContext];
    cp.width=[NSNumber numberWithInt:[self.widthTF.stringValue intValue]];
    cp.height=[NSNumber numberWithInt:[self.heightTF.stringValue intValue]];
    cp.detail=self.detailTF.stringValue;
    NSError *saveError;
    [[SceneryModel sharedModel].managedObjectContext save:&saveError];
    //NSLog(@"%@",[saveError localizedDescription]);
    self.info=cp.detail;
    self.info=[NSString stringWithFormat:@"%d has Saved!",self.currentIndex+1];
    self.addedPictureCount+=1;
    self.indexTF.stringValue=[NSString stringWithFormat:@"%d/%lu 已保存CPictuer数:%d",self.currentIndex +1,(unsigned long)[self.filePathArray count],self.addedPictureCount];
}


@end
