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

-(id) decodeDataFromSQLITE: (NSString*)stringRepresentation expectedType: (Class) class{
    NSError* err;
    
    if ([class isSubclassOfClass:[NSArray class]] || [class isSubclassOfClass:[NSDictionary class]]){
        return [NSJSONSerialization JSONObjectWithData: [stringRepresentation dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
    }
    
    if ([class isSubclassOfClass:[NSString class]]){
        return stringRepresentation;
    }
    
    if ([class isSubclassOfClass:[NSNumber class]]){
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        return [f numberFromString:stringRepresentation];
    }
    
    if ([class isSubclassOfClass:[NSDate class]]){
        
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        return [formatter dateFromString: stringRepresentation];
        
    }
    
    
    return stringRepresentation;
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
                id AR = [[ARClass alloc] initModelValues];
                [(RCActiveRecord*)AR setIsNewRecord:NO];
                [(RCActiveRecord*)AR setIsSavedRecord:YES];
                
                for (int i=0; i < [s columnCount]; i++){
                    
                    NSString* varName = [s columnNameForIndex: i];
                   // NSLog(@"Warr: %@",[AR performSelector:NSSelectorFromString(varName)]);
                    
                    NSString* dataType = NSStringFromClass([[AR performSelector:NSSelectorFromString(varName)] class]);
                    //NSLog(@"Data type: %@", dataType);
                    //^ Is showing up as NULL.
                    
                    // TODO: Data type comparison would be nice here
                    
                    NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
                    NSString* value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
                    
                    id convertedValue = [self decodeDataFromSQLITE:value expectedType: [[AR performSelector:NSSelectorFromString(varName)] class]];
                    @try {
                        [AR performSelector: NSSelectorFromString(setConversion) withObject: convertedValue];
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
@end

#pragma clang diagnostic pop