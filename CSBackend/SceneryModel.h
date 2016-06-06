//
//  SceneryModel.h
//  China's Scenery
//
//  Created by 张保国 on 15/12/19.
//  Copyright © 2015年 ZhangBaoGuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class CScenery;
#import "Qiniu.h"

@class Qiniu;

extern const NSString * kStatus;
extern const NSString * kProvinces;
extern const NSString * kProvinceName;
extern const NSString * kProvinceDetail;
extern const NSString * kProvinceThumbnailName;
extern const NSString * kSceneries;
extern const NSString * kSceneryName;
extern const NSString * kSceneryDetail;
extern const NSString * kSceneryThumbnailName;
extern const NSString * kSceneryPictures;
extern const NSString * kPictureName;
extern const NSString * kPictureThumbnailName;
extern const NSString * kPictureDetail;
extern const NSString * kPictureWidth;
extern const NSString * kPictureHeight;
extern const NSString * kSceneryUpdateUnix;

#define kSavedPicturePathArray @"kSavedPicturePathArray"
#define kSceneryModelRefreshedNotification @"kSceneryModelRefreshedNotification"

typedef void(^SceneryModelRefreshCompletionBlock)(NSDate *date);
typedef void(^CompletionBlock)();

@interface SceneryModel : NSObject

@property (nonatomic,assign) NSTimeInterval refreshInterval;

@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,assign) BOOL canUseCellularData;

+(instancetype)sharedModel;

-(void)refreshCProvince;

//-(NSURL *)fileURLWithName:(NSString *)fileName fromQiniu:(Qiniu *)qn;


//+(BOOL)checkFileExistsInDocumentDirectory:(NSString *)fileName;
//+(NSString *)filePathInDocumentDirectory:(NSString *)fileName;
//
////+(NSString *)getImageNameFromURL:(NSURL *)url;
//+(void)csSaveImageToDocumentDirectory:(UIImage *)image forName:(NSString *)aName;
//

-(BOOL)clearCoreData;

-(BOOL)checkNetWork;

-(void)sizeOfSavedImage;

-(void)asyncClearSavedImageWithCompletionBlock:(CompletionBlock)block;

-(NSString *)createMainJSONFile;
-(NSString *)createCSceneryJSONFile:(CScenery *)cScenery;

//-(NSString *)createJSONFile;

@end
