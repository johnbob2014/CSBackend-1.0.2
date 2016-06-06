//
//  AppDelegate.h
//  CSBackend
//
//  Created by 张保国 on 15/12/27.
//  Copyright © 2015年 ZhangBaoGuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SceneryModel;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

