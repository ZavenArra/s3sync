//
//  S3Sync.m
//  SurveyTool
//
//  Created by Matthew Shultz on 7/6/14.
//  Copyright (c) 2014 David Whiteman Enterprises LLC. All rights reserved.
//

#import "S3Sync.h"
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import "VCCoreData.h"
#import "S3Object.h"

static S3Sync * s3sync;

@interface S3Sync ()

@property (nonatomic, strong) AmazonS3Client *s3;

@end

@implementation S3Sync

+ (S3Sync *) instance {
    if( s3sync == nil){
        s3sync = [[S3Sync alloc] init];
        
    }
    return s3sync;
}

- (S3Sync *) init {
    self = [super init];
    if(self != nil){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _storageDirectory = [paths objectAtIndex:0];
    }
    return self;
}

- (void) initalizeWithAccessKey:(NSString*) accessKey withSecretKey:(NSString*) secretKey {
    _s3 = [[AmazonS3Client alloc] initWithAccessKey:accessKey withSecretKey:secretKey];
}


- (void) syncObjectsInBucket: (NSString*) bucketName
                  completion: (void ( ^ ) () )success
                     failure:(void ( ^ ) () )failure {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Code in this part is run on a background thread
        NSArray * objects = [_s3 listObjectsInBucket:bucketName];
        if(objects != nil) {
            for(S3ObjectSummary * objectSummary in objects){
                
                NSManagedObjectContext *tmpContext = [[NSManagedObjectContext alloc] init];
                tmpContext.persistentStoreCoordinator = [VCCoreData persistentStoreCoordinator];
                
                NSLog(@"%@", objectSummary.key);
                NSLog(@"%@", objectSummary.etag);
                NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"S3Object"];
                NSPredicate * predicate = [NSPredicate predicateWithFormat:@"key = %@", objectSummary.key];
                [fetch setPredicate:predicate];
                NSError * error;
                NSArray * results = [tmpContext executeFetchRequest:fetch error:&error];
                if(results == nil){
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [WRUtilities criticalError:error];
                    });
                    NSLog(@"%@", error);
                    continue;
                }
                S3Object * storedObject = results.firstObject;
                if(storedObject!= nil){
                    if([storedObject.etag isEqualToString:objectSummary.etag]){
                        // Don't need to re-download this file
                        continue;
                    }
                } else {
                    storedObject = [NSEntityDescription insertNewObjectForEntityForName:@"S3Object" inManagedObjectContext:tmpContext];
                    storedObject.key = objectSummary.key;
                }
                
                NSString * filename = [objectSummary.key lastPathComponent];
                if(_delegate != nil){
                    [_delegate s3SyncStartedFileDownload:filename];
                }
                NSString * filePath = [NSString stringWithFormat:@"%@/%@", _storageDirectory, filename];
                NSOutputStream *stream = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];
                [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                [stream open];
                S3GetObjectRequest * request = [[S3GetObjectRequest alloc] initWithKey:objectSummary.key withBucket:bucketName];
                [_s3 getObject:request];
                [stream close];
                
                
                storedObject.etag = objectSummary.etag;
                [tmpContext save:&error];
                if(error != nil){
                    NSLog(@"%@", [error description]);
                }
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                success();
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                failure();
            });
        }
    });
}

- (void) reset {
    NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[NSEntityDescription entityForName:@"S3Object" inManagedObjectContext:[VCCoreData managedObjectContext]]];
    [fetch setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * objects = [[VCCoreData managedObjectContext] executeFetchRequest:fetch error:&error];
    //error handling goes here
    for (NSManagedObject * object in objects) {
        [[VCCoreData managedObjectContext] deleteObject:object];
    }
    NSError *saveError = nil;
    [[VCCoreData managedObjectContext] save:&saveError];
}

@end
