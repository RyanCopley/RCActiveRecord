//
//  RCActiveRecordResultSet.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/10/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "RCActiveRecordResultSet.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


@implementation RCActiveRecordResultSet

-(void) execute: (void (^) (id recordResult)) recordCallback{
    [self execute:recordCallback finished:^(BOOL error){}];
}

-(void) execute: (void (^) (id recordResult)) recordCallback finished: (void (^) (BOOL error)) finishedCallback{
    error = NO;
    
    dispatch_queue_t fetchQ = dispatch_queue_create("__RCACTIVERECORDCALLBACK", NULL);
    __block int recordTally = 1;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet* s = [db executeQuery: internalQuery];
            while ([s next]){
                recordTally++;
                id AR = [[ARClass alloc] init];
                [(RCActiveRecord*)AR setIsNewRecord:NO];
                [(RCActiveRecord*)AR setIsSavedRecord:YES];
                
                for (int i=0; i < [s columnCount]; i++){
                    
                    NSString* varName = [s columnNameForIndex: i];
                    NSString* dataType = NSStringFromClass([[AR performSelector:NSSelectorFromString(varName)] class]);
                    //^ Is showing up as NULL.
                    
                    // TODO: Data type comparison would be nice here
                    
                    NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
                    id value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
                    
                    @try {
                        [AR performSelector: NSSelectorFromString(setConversion) withObject: value];
                    }
                    @catch (NSException* e){
                        error = YES;
                        NSLog(@"[Error in RCActiveRecord] This object (%@) is not properly synthesized (Invalid setter). Unable to set: %@", NSStringFromClass([AR class]), varName);
                    }
                    
                }
                dispatch_async(fetchQ, ^{
                    recordCallback(AR);
                    recordTally--;
                });
            }
            
            recordTally--;
            
            dispatch_queue_t finishQueue = dispatch_queue_create("__RCACTIVERECORDFINISHCALLBACK", NULL);
            
            dispatch_async(finishQueue, ^{
                while (recordTally > 0){
                    //Burn CPU... not finished...
                }
                //I do this because the finish callback is often used to update the UI, and as any competent iOS developer knows you shouldn't update the UI on any non-main thread.
                dispatch_sync(dispatch_get_main_queue(), ^{
                    finishedCallback(error);
                });
                
            });
        }];
    });
}

//Internal
-(RCActiveRecordResultSet*) initWithFMDatabaseQueue:(FMDatabaseQueue*) _queue andQuery:(NSString*) query andActiveRecordClass:(Class) _ARClass{
    self = [super init];
    if (self){
        internalQuery = query;
        queue = _queue;
        ARClass = _ARClass;
    }
    return self;
}


/*
 
 -(id) rowToModel:(FMResultSet*)resultSet{
 id AR = [[[self class] alloc] init];
 [(RCActiveRecord*)AR setIsNewRecord:NO];
 
 for (int i=0; i < [resultSet columnCount]; i++){
 //Some type checking for some basic classes...
 
 NSString* varName = [resultSet columnNameForIndex: i];
 
 id value = [NSString stringWithFormat:@"%s",[resultSet UTF8StringForColumnIndex:i]];
 
 
 NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
 @try {
 [AR performSelector: NSSelectorFromString(setConversion) withObject: value];
 }
 @catch (NSException* e){
 NSLog(@"[RCActiveRecord] Error thrown! This object is not properly synthesized. Unable to set: %@", varName);
 }
 }
 return AR;
 }
 
 */

@end

#pragma clang diagnostic pop