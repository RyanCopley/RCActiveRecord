//
//  RCActiveRecordResultSet.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/10/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

@interface RCActiveRecordResultSet : NSObject{
    FMDatabaseQueue* queue;
    FMResultSet* resultSet;
    NSString* internalQuery;
    Class ARClass;
    BOOL error;
    NSDateFormatter* formatter;
    NSMutableArray* processQueues;
    
    int queueCounter;
}


-(void) execute: (void (^) (id recordResult)) recordCallback;
-(void) execute: (void (^) (id recordResult)) recordCallback finished: (void (^) (BOOL error)) finishedCallback;


//Internal
-(RCActiveRecordResultSet*) initWithFMDatabaseQueue:(FMDatabaseQueue*) _queue andQuery:(NSString*) query andActiveRecordClass:(Class) _ARClass;

-(RCActiveRecordResultSet*) setProcessQueueCount: (int) count;

@end
