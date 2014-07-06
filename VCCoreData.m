//
//  VCCoreData.m
//
//
//  Created by Matthew Shultz on 6/2/14.
//  Copyright (c) 2014 Voco. All rights reserved.
//

#import "VCCoreData.h"
#import <CoreData.h>

static VCCoreData * sharedInstance;

@interface VCCoreData ()

@property(strong, nonatomic) RKManagedObjectStore * managedObjectStore;
@property(strong, nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@end

@implementation VCCoreData


+ (VCCoreData *) instance {
    if(sharedInstance == nil){
        sharedInstance = [[VCCoreData alloc] init];
    }
    return sharedInstance;
}



// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
+ (NSManagedObjectContext *)managedObjectContext
{
    return [self instance].managedObjectStore.persistentStoreManagedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
+ (NSManagedObjectModel *)managedObjectModel
{
    if ([self instance].managedObjectModel != nil) {
        return [self instance].managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"S3Sync" withExtension:@"momd"];
    [self instance].managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return [self instance].managedObjectModel;
}



// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
+ (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if ([self instance].persistentStoreCoordinator != nil) {
        return [self instance].persistentStoreCoordinator;
    }
    
    
    [self instance].persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [self createPersistentStore];
    
    return [self instance].persistentStoreCoordinator;
}


+ (RKManagedObjectStore *) managedObjectStore {
    if ([self instance].managedObjectStore != nil) {
        return [self instance].managedObjectStore;
    }
    [self instance].managedObjectStore = [[RKManagedObjectStore alloc] initWithPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    [[self instance].managedObjectStore createManagedObjectContexts];
    
    return [self instance].managedObjectStore;
}



+ (void) createPersistentStore {
    NSError *error = nil;
    NSDictionary *options = @{
                            NSMigratePersistentStoresAutomaticallyOption : @YES,
                            NSInferMappingModelAutomaticallyOption : @YES
                            };
    if (![[self instance].persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self storeURL] options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error in core data persistent store setup %@, %@", error, [error userInfo]);
        
    }

}

+ (void) clearUserData {
    NSError * error = nil;
    NSPersistentStore * store = [[self instance].persistentStoreCoordinator.persistentStores objectAtIndex:0];
    [[self persistentStoreCoordinator] removePersistentStore:store error:&error];
    if(error != nil) {
        [WRUtilities criticalError:error];
        return;
    }
    [[NSFileManager defaultManager] removeItemAtPath:[self storeURL].path error:&error];
    if(error != nil){
        [WRUtilities criticalError:error];
        return;
    }
    [self createPersistentStore];
}

+ (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [WRUtilities criticalError:error];
        }
    }
}


#pragma mark - Paths
// Returns the URL to the application's Documents directory.
+ (NSURL *) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL *) storeURL {
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Voco.sqlite"];
}

@end
