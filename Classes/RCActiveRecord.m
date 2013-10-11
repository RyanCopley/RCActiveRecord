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
@synthesize isNewRecord, isSavedRecord, _id;


static FMDatabaseQueue* RCActiveRecordQueue;
static NSMutableDictionary* RCActiveRecordSchemas;

static NSMutableDictionary* pkName;
static NSMutableDictionary* schemaData;

#pragma mark Active Record functions
-(id)init{
    self = [super init];
    if (self){
        if (pkName == nil){
            pkName = [[NSMutableDictionary alloc] init];
            schemaData = [[NSMutableDictionary alloc] init];
        }
        
        NSString *key = NSStringFromClass( [self class] );
        [pkName setObject:@"_id" forKey:key]; /* default */
        [schemaData setObject: @[] forKey:key]; /* empty */
        
        isNewRecord = YES;
        isSavedRecord = NO;
        
        if (!RCActiveRecordQueue){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString* dbPath =  [NSString stringWithFormat:@"%@/db.sqlite",documentsDirectory];
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
        [criteria addCondition: [self primaryKey] is:RCEqualTo to: [NSString stringWithFormat:@"%@",pk]];
    }
    [criteria setLimit:1];

    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause] ];
    
    return [[RCActiveRecordResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}

-(RCActiveRecordResultSet*)recordsByAttribute:(NSString*) attributeName value:(id) value{
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
        [criteria addCondition:attributeName is:RCEqualTo to: [NSString stringWithFormat:@"%@",value]];
    }
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause] ];
    
    return [[RCActiveRecordResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


-(RCActiveRecordResultSet*)allRecords{
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
    }
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause] ];
    
    return [[RCActiveRecordResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


-(BOOL)saveRecord{
    return YES;
}

-(BOOL)deleteRecord{
    if (!isNewRecord && isSavedRecord){
        
    }
    return YES;
}


+(BOOL) hasSchemaDeclared{
    return NO;
}


+(BOOL) registerPrimaryKey:(NSString*) columnName{
    NSString *key = NSStringFromClass( [self class] );
    [pkName setObject:columnName forKey:key];
    return YES;
}

+(BOOL) registerColumn:(NSString*) columnName{
    NSLog(@"Registering %@", columnName);
    return YES;
}

+(BOOL) registerForeignKey:(Class*) activeRecord forColumn:(NSString*) column{
    return YES;
}



+(BOOL) generateSchema: (BOOL)force{
    NSLog(@"Generating schema for table: %@",[[[self class] alloc] tableName]);
    NSLog(@"GPK: %@",[[[self class] alloc] primaryKey]);
    
    if ([RCActiveRecordSchemas objectForKey: [[[self class] alloc] tableName]] == nil) {
        
        [RCActiveRecordSchemas setObject: @"" forKey: [[[self class] alloc] tableName]];
        /*
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
        }];*/
        
    }
}

-(NSDictionary*)schemaProfile{
    return @{@"primaryKey" : pkName, @"columns" : schemaData };
}

-(void)updateSchema{
    
}

-(void)dropTable{
    
}


-(NSString*) primaryKey{
    NSString *key = NSStringFromClass( [self class] );
    return [pkName valueForKey:key];
}

-(BOOL)isNewRecord{
    return isNewRecord;
}

-(NSString*) tableName{
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
