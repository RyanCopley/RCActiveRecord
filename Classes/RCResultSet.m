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
#import "RCResultSet.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


@implementation RCResultSet

static NSDateFormatter *formatter;
static NSNumberFormatter *numFormatter;


-(void) execute: (void (^) (id recordResult)) recordCallback{
    [self execute:recordCallback finished:^(BOOL error){}];
}

-(id) decodeDataFromSQLITE: (NSString*)stringRepresentation expectedType: (Class) class fromDB: (FMDatabase*) db{
    
    NSError* err;
    
    if ([class isSubclassOfClass:[NSArray class]] || [class isSubclassOfClass:[NSDictionary class]]){
        return [NSJSONSerialization JSONObjectWithData: [stringRepresentation dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
    }
    
    if ([class isSubclassOfClass:[NSString class]]){
        return stringRepresentation;
    }
    
    if ([class isSubclassOfClass:[NSNumber class]]){
        return [numFormatter numberFromString:stringRepresentation];
        
    }
    
    if ([class isSubclassOfClass:[NSDate class]]){
        return [formatter dateFromString: stringRepresentation];
    }
    
    BOOL preload = [ARClass preloadEnabled];
    if (preload && [class isSubclassOfClass:[RCActiveRecord class]]){
        //To do this shit still D:
        
        __block RCActiveRecord* model = [class model];
        
        NSNumber* pk = [numFormatter numberFromString:stringRepresentation];
        __block id _record;
        [[model recordByPK: pk] execute:^(id record){
            _record = record;
        }];
        return _record;
        
    }
    
    return stringRepresentation;
}


-(void) execute: (void (^) (id recordResult)) recordCallback finished: (void (^) (BOOL error)) finishedCallback{
    dispatch_async(processQueue, ^{
        error = NO;
        [queue inDatabase:^(FMDatabase *db) {
            
            FMResultSet* s = [db executeQuery: internalQuery];
            
            
            while ([s next]){
                id AR = [[ARClass alloc] initModelValues];
                [(RCActiveRecord*)AR setIsNewRecord:NO];
                [(RCActiveRecord*)AR setIsSavedRecord:YES];
                
                @autoreleasepool {
                    for (int i=0; i < [s columnCount]; i++){
                        
                        NSString* varName = [s columnNameForIndex: i];
                        
                        NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
                        NSString* value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
                        
                        id convertedValue = [self decodeDataFromSQLITE:value expectedType: [[AR performSelector:NSSelectorFromString(varName)] class] fromDB: db];
                        @try {
                            
                            [AR performSelector: NSSelectorFromString(setConversion) withObject: convertedValue];
                        }
                        @catch (NSException* e){
                            error = YES;
                            NSLog(@"[Error in RCActiveRecord] This object (%@) is not properly synthesized (Invalid setter). Unable to set: %@", NSStringFromClass([AR class]), varName);
                        }
                    }
                }
                recordCallback(AR);
                
            }
            dispatch_async(dispatch_queue_create("", NULL), ^{
                finishedCallback(error);
            });
        }];
    });

    
}

//Internal
-(RCResultSet*) initWithFMDatabaseQueue:(FMDatabaseQueue*) _queue andQuery:(NSString*) query andActiveRecordClass:(Class) _ARClass{
    self = [super init];
    if (self){
        
        
        
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        numFormatter = [[NSNumberFormatter alloc] init];
        [numFormatter setNumberStyle:NSNumberFormatterNoStyle];
        
        
        processQueue = dispatch_queue_create("", NULL);
        
        internalQuery = query;
        queue = _queue;
        ARClass = _ARClass;
    }
    return self;
}
@end

#pragma clang diagnostic pop