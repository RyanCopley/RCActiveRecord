//
//  RCActiveRecordResultSet.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/10/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

@interface RCResultSet : NSObject{
    FMDatabaseQueue* queue;
    FMResultSet* resultSet;
    NSString* internalQuery;
    Class ARClass;
    BOOL error;
    NSDateFormatter* formatter;
    dispatch_queue_t processQueue;
    
    dispatch_queue_t finishQueue;
    
}


-(void) execute: (void (^) (id recordResult)) recordCallback;
-(void) execute: (void (^) (id recordResult)) recordCallback finished: (void (^) (BOOL error)) finishedCallback;


//Internal
-(RCResultSet*) initWithFMDatabaseQueue:(FMDatabaseQueue*) _queue andQuery:(NSString*) query andActiveRecordClass:(Class) _ARClass;

@end
