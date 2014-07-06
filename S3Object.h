//
//  S3Object.h
//  SurveyTool
//
//  Created by Matthew Shultz on 7/6/14.
//  Copyright (c) 2014 David Whiteman Enterprises LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface S3Object : NSManagedObject

@property (nonatomic, retain) NSString * etag;
@property (nonatomic, retain) NSString * key;

@end
