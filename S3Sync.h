//
//  S3Sync.h
//  SurveyTool
//
//  Created by Matthew Shultz on 7/6/14.
//  Copyright (c) 2014 David Whiteman Enterprises LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol S3SyncDelegate <NSObject>

@optional
- (void) s3SyncStartedFileDownload: (NSString *) filename;

@end

@interface S3Sync : NSObject

@property (nonatomic, weak) id<S3SyncDelegate> delegate;
@property (nonatomic, strong) NSString * storageDirectory;

+ (S3Sync *) instance;
- (void) initalizeWithAccessKey:(NSString*) accessKey withSecretKey:(NSString*) secretKey;
- (void) syncObjectsInBucket: (NSString*) bucketName
                  completion: (void ( ^ ) () )success
                     failure:(void ( ^ ) () )failure;
- (void) reset;

@end
