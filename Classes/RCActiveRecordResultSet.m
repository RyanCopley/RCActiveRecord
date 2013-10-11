//
//  RCActiveRecordResultSet.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/10/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecordResultSet.h"

@implementation RCActiveRecordResultSet

-(void) execute: (void (^) (id recordResult)) resultCallback{
    
}

-(void) execute: (void (^) (id recordResult)) resultCallback finished: (void (^) ()) finishedCallback{
    
}


//Internal
-(void) initWithFMDatabaseQueue:(FMDatabaseQueue*) _queue andQuery:(NSString*) query andActiveRecordClass:(Class*) _ARClass{
    queue = _queue;
    ARClass = _ARClass;
    
}



@end
