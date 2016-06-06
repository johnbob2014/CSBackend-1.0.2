//
//  ViewController.m
//  CSBackend
//
//  Created by 张保国 on 15/12/27.
//  Copyright © 2015年 ZhangBaoGuo. All rights reserved.
//

#import "ViewController.h"
#import "PictureInfoVC.h"
#import "SceneryModel.h"
#import "AppDelegate.h"
#import <QNUploadManager.h>

@interface ViewController()

@property (strong,nonatomic) NSArray *filePathArray;
@property (weak) IBOutlet NSPopUpButton *provincePopUpButton;
@property (weak) IBOutlet NSPopUpButton *sceneryPopUpButton;

@property (weak) IBOutlet NSButton *deleteJSONBtn;

@property (weak) IBOutlet NSTextField *infoTF;
@property (strong,nonatomic) NSString *info;

@property (nonatomic) BOOL hasRenamedJSON;
@property (strong,nonatomic) NSString *lastJSONPath;

@end

@implementation ViewController

#pragma mark - Getter
-(NSManagedObjectContext *)managedObjectContext{
    AppDelegate *ad=[NSApplication sharedApplication].delegate;
    return ad.managedObjectContext;
}

-(void)setInfo:(NSString *)info{
    _info=info;
    self.infoTF.stringValue=[NSString stringWithFormat:@"%@\n%@",info,self.infoTF.stringValue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.deleteJSONBtn.enabled=NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sceneryModelRefreshed:) name:kSceneryModelRefreshedNotification object:nil];

}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showPictureInfo"]) {
        PictureInfoVC *plvc=segue.destinationController;
        plvc.filePathArray=self.filePathArray;
    }
}

#define ChinaSceneryDataFileName @"China-s-Scenery.json"

- (IBAction)refreshCoreDataBtn:(NSButton *)sender {
    //[[SceneryModel sharedModel] startRefresh];
}

- (void)sceneryModelRefreshed:(NSNotification *)noti{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.info=@"数据刷新完成.";
        self.deleteJSONBtn.enabled=YES;
    });
}

- (IBAction)deleteJSONBtn:(NSButton *)sender {
    NSTimeInterval timeStamp=[[NSDate date] timeIntervalSince1970];
    NSString *oldFileName=[NSString stringWithFormat:@"%@-%0.f",ChinaSceneryDataFileName,timeStamp];
    [[Qiniu sharedQN] syncMoveFromFile:ChinaSceneryDataFileName toFile:oldFileName];
    self.hasRenamedJSON=YES;
    self.info=@"JSON文件已重命名.";
}

- (IBAction)createJSONBtn:(NSButton *)sender {
    //self.lastJSONPath=[[SceneryModel sharedModel] createJSONFile];
    if (self.lastJSONPath) {
        self.info=[NSString stringWithFormat:@"新JOSN文件已生成:%@",self.lastJSONPath];
    }
}

- (IBAction)uploadJSONBtn:(NSButton *)sender {
    if (self.hasRenamedJSON) {
        if (self.lastJSONPath!=nil) {
            QNUploadManager *um=[[QNUploadManager alloc]init];
            NSString *upToken=[[Qiniu sharedQN] upToken];
            
            [um putFile:self.lastJSONPath key:[self.lastJSONPath lastPathComponent] token:upToken complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
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

- (IBAction)updateJSONBtn:(NSButton *)sender {
    [self deleteJSONBtn:nil];
    [self createJSONBtn:nil];
    [self uploadJSONBtn:nil];
}

- (IBAction)addPicturesBtnPressed:(id)sender {
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    
    [openPanel setTitle:@"Choose a File or Folder"];//setTitle为NSWindow的方法，它是openPanel 的父类
    
    [openPanel setAllowsMultipleSelection:YES];//允许多选
    
    [openPanel setCanChooseDirectories:NO];//默认不可以选文件夹，可选任何格式文件
    
    [openPanel setCanChooseFiles:YES];
    NSInteger i=[openPanel runModal];//显示openPanel
    
    if(i==NSModalResponseOK){
        
       
        
        //给outlets（filePathDisplay）赋值：[filePathDisplay setStringValue:theFilePath]
        
        //NSFileManager *theManager=[NSFileManager defaultManager];
        
        //NSString *theFileName=[theManager displayNameAtPath:theFilePath];
        
        NSMutableArray *array=[NSMutableArray new];
        
        for (NSURL *aURL in [openPanel URLs]) {
            [array addObject:[aURL path]];
        }
        
        if ([array count]>=1) {
            self.filePathArray=[NSArray arrayWithArray:array];
            
            [self performSegueWithIdentifier:@"showPictureInfo" sender:self];
        }
       
        
        /*
         if( [theManager fileExistsAtPath:theFilePath isDirectory:YES] ){
         
         //表示选中的是一个目录（文件夹）
         
         }
         
         NSDictionary *theFileAttributes=[theManager fileAttributesAtPath:theFilePath traverseLink:YES];
         
         //NSDictionary是一个数据结构，其中包括：文件大小，创建日期，修改日期
         
         //由于只是读数据，则不用可变的NSMutableDictionary
         
         NSNumber *theFileSize=[theFileAttributes objectForKey:NSFileSize];
         
         NSDate *theModificationDate=[theFileAttributes objectForKey:NSFileModificationDate];
         
         NSDate *theCreationDate=[theFileAttributes objectForKey:NSFileCreationDate];
         
         
         
         
         //查看文件图标（要先用NSFileWrapper把文件数据放入内存）
         
         NSFileWrapper *theFileWrapper=[[NSFileWrapper alloc] initWithPath:theFilePath];
         
         NSImage *theIcon=[theFileWrapper icon];
         
         //fileIconDisplay为Interface上的NSImageView对象(Library中的Image well)
         
         //[fileIconDisplay setImageScaling:NSScaleToFit];
         
         //[fileIconDisplay setImage:theIcon];
         
         
         
         //可以实现对对文档（Text），图片，以及多媒体文件的操作
         
         //复制文件
         
         NSString *theDestination=[[NSHomeDirectory()		//NSHomeDirectory是Foundation的方法
         
         stringByAppendingPathComponent:@"Desktop"]		//文件保存的目录
         
         stringByAppendingPathComponent:theFileName];
         
         [theManager copyPath:theFilePath toPath:theDestination handler:nil];
         
         //移动（剪切）文件
         
         [theManager movePath:theFilePath toPath:theDestination handler:nil];
         
         //删除文件
         //
         //        NSInteger n=NSRunAlertPanel([NSLocalizedString(@"Are you sure you want to delete the file?",nil),
         //
         //                                     [NSLocalizedString(@"You cannot undo this deletion.",nil),
         //
         //                                      [NSLocalizedString(@"Yes",nil),
         //
         //                                       [NSLocalizedString(@"No",nil),
         //
         //                                        nil);
         //        if(n==NSAlertDefaultReturn){
         //
         //            [theManager removeFileAtPath:theFilePath handler:nil];
         //
         //        }
         
         //创建文件夹
         
         NSString *theDestination2=[[NSHomeDirectory()
         
         stringByAppendingPathComponent:@"Desktop"]
         
         stringByAppendingPathComponent:@"MyNewFolder"];
         
         [theManager createDirectoryAtPath:theDestination2 withIntermediateDirectories:YES attributes:nil error:NULL];	//第二个参数设置文件夹的属性
         */
        
        
    }else if (i==NSModalResponseCancel){
        //[self.textField setTitleWithMnemonic:@"取消选择"];
    }
}

- (IBAction)clearInfoTFBtn:(NSButton *)sender {
    self.infoTF.stringValue=@"";
}

@end
