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
    
    Class* ARClass;
}


-(void) execute: (void (^) (id recordResult)) resultCallback;
-(void) execute: (void (^) (id recordResult)) resultCallback finished: (void (^) ()) finishedCallback;


//Internal
-(void) initWithFMDatabaseQueue:(FMDatabaseQueue*) _queue andQuery:(NSString*) query andActiveRecordClass:(Class*) _ARClass;

@end
