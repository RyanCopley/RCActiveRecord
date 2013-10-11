//
//  RCActiveRecord.m
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation RCActiveRecord
@synthesize isNewRecord, isSavedRecord;

static FMDatabaseQueue* RCActiveRecordQueue;
static NSMutableDictionary* RCActiveRecordSchemas;

#pragma mark Active Record functions
-(id)init{
    self = [super init];
    if (self){
        pkName = @"id"; /* default */
        
        isNewRecord = YES;
        isSavedRecord = NO;
        if (!RCActiveRecordQueue){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString* dbPath =  [NSString stringWithFormat:@"%@/RCActiveRecord/db.sqlite",documentsDirectory];
            RCActiveRecordQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            
            RCActiveRecordSchemas = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

+(id) model{
    // TODO: Perhaps make it initModel instead of init ? Think about this
    return [[[self class] alloc] init];
}

-(void)setCriteria:(RCCriteria*) _criteria{
    criteria = _criteria;
}

-(RCActiveRecordResultSet*)recordByPK:(NSNumber*) pk{
    
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
        [criteria addCondition:pkName is:RCEqualTo to: [NSString stringWithFormat:@"%@",pk]];
    }
    [criteria setLimit:1];

    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self recordIdentifier], [criteria generateWhereClause] ];
    
    return [[RCActiveRecordResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}

-(RCActiveRecordResultSet*)recordsByAttribute:(NSString*) attributeName value:(id) value{
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
        [criteria addCondition:attributeName is:RCEqualTo to: [NSString stringWithFormat:@"%@",value]];
    }
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self recordIdentifier], [criteria generateWhereClause] ];
    
    return [[RCActiveRecordResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


-(RCActiveRecordResultSet*)allRecords{
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@;", [self recordIdentifier] ];
    return [[RCActiveRecordResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


-(BOOL)saveRecord{
    
}

-(BOOL)deleteRecord{
    if (!isNewRecord && isSavedRecord){
        
    }
}

-(void)generateSchema{
    
    if ([RCActiveRecordSchemas objectForKey:[self recordIdentifier]] == nil) {
        
        [RCActiveRecordSchemas setObject: [self schemaProfile] forKey: [self recordIdentifier]];
        
        NSMutableString* columnData = [[NSMutableString alloc] init];
        [columnData appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT", pkName];
        
        
        for (NSString* keys in schemaData){
            [columnData appendFormat:@", %@ TEXT", keys];
        }
        
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            NSString* query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", [self recordIdentifier], columnData];
            NSLog(@"Query: %@", query);
            if (![db executeUpdate: query]){
                if ([db lastErrorCode] != 0){
                    NSLog(@"(0xd34d4) Error %d: %@ %@", [db lastErrorCode], [db lastErrorMessage], query);
                }
            }
        }];
    }
}

-(NSDictionary*)schemaProfile{
    return @{@"primaryKey" : pkName, @"columns" : schemaData };
}

-(void)updateSchema{
    
}

-(void)dropTable{
    
}

-(BOOL)isNewRecord{
    return isNewRecord;
}

-(BOOL)registerPrimaryKey:(NSString*) title{
    pkName = title;
    return YES;
}

-(BOOL)registerVariable:(NSString*) title{
    
}

-(NSString*)recordIdentifier{
    return [NSStringFromClass([self class]) lowercaseString];
}

-(FMDatabaseQueue*) getFMDBQueue{
    return RCActiveRecordQueue;
}

/*
-(NSString*)dataTypeOfVariable:(NSString*)variableName{
    NSString* dataType = NSStringFromClass([[AR performSelector:NSSelectorFromString(variableName)] class]);
    return dataType;
}
*/
@end

#pragma clang diagnostic pop
