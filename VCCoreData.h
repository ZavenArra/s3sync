//
//  VCCoreData.h
//  Voco
//
//  Created by Matthew Shultz on 6/2/14.
//  Copyright (c) 2014 Voco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>

@interface VCCoreData : NSObject

+ (NSManagedObjectContext *) managedObjectContext;
+ (NSManagedObjectModel *) managedObjectModel;
+ (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
+ (RKManagedObjectStore *) managedObjectStore;

+ (void) clearUserData;
+ (void) saveContext;


@end
