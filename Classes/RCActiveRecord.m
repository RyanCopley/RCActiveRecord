//
//  RCActiveRecord.m
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation RCActiveRecord
@synthesize isNewRecord, isSavedRecord, _id;


static FMDatabaseQueue* RCActiveRecordQueue;
static NSMutableDictionary* RCActiveRecordSchemas;

static NSMutableDictionary* pkName;
static NSMutableDictionary* schemaData;
static NSMutableDictionary* foreignKeyData;

#pragma mark Active Record functions
-(id)init{
    self = [super init];
    if (self){
        if (pkName == nil){
            pkName = [[NSMutableDictionary alloc] init];
            schemaData = [[NSMutableDictionary alloc] init];
            foreignKeyData = [[NSMutableDictionary alloc] init];
        }
        
        NSString *key = NSStringFromClass( [self class] );
        [pkName setObject:@"_id" forKey:key]; /* default */
        [schemaData setObject: [@{} mutableCopy] forKey:key]; /* empty */
        [foreignKeyData setObject: [@{} mutableCopy] forKey:key]; /* empty */
        
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
    return [[[[self class] alloc] initModelValues] initModel];
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
    NSString *key = NSStringFromClass( [self class] );
    return [[schemaData objectForKey:key] count] > 0;
}


+(BOOL) registerPrimaryKey:(NSString*) columnName{
    NSString *key = NSStringFromClass( [self class] );
    [pkName setObject:columnName forKey:key];
    return YES;
}


+(BOOL) registerColumn:(NSString*) columnName{
    
    NSString *key = NSStringFromClass( [self class] );
    
    NSMutableDictionary* columnData = [schemaData objectForKey:key];
    // TODO: Test for this function to exist perhaps?
    id obj = [[self alloc] initModelValues];
    
    [columnData setObject:@{
                            @"columnName" : columnName,
                            @"type" : NSStringFromClass([[obj performSelector:NSSelectorFromString(columnName)] class])
                            }
                   forKey: columnName];
    
    [schemaData setObject:columnData forKey:key];
    return YES;
}

+(BOOL) registerForeignKey:(Class*) activeRecord forColumn:(NSString*) column{
    return YES;
}


-(NSString*) objCDataTypeToSQLiteDataType:(NSString*)dataTypeStrRepresentation {
    if ([dataTypeStrRepresentation isEqualToString:@"__NSCFConstantString"]){
        return @"TEXT";
    }else if ([dataTypeStrRepresentation isEqualToString:@"__NSCFString"]){
        return @"TEXT";
    }else if ([dataTypeStrRepresentation isEqualToString:@"__NSCFNumber"]){
        return @"REAL";
    }
    
    return @"INTEGER";
}

+(BOOL) generateSchema: (BOOL)force{
    
    NSString *key = NSStringFromClass( [self class] );
    
    NSLog(@"Generating schema for table: %@",[[[self class] alloc] tableName]);
    id obj = [[self class] alloc];
    
    NSDictionary* schema = [schemaData objectForKey:key];
    
    if ([RCActiveRecordSchemas objectForKey: [[[self class] alloc] tableName]] == nil) {
        
        [RCActiveRecordSchemas setObject: @"Defined" forKey: [obj tableName]];
        
        
        NSMutableString* columnData = [[NSMutableString alloc] init];
        [columnData appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT", [obj primaryKey]];
        
        
        for (NSString* columnName in schema){
            NSDictionary* columnSchema = [schema objectForKey:columnName];
            
            [columnData appendFormat:@", %@ %@", columnName, [obj objCDataTypeToSQLiteDataType: [columnSchema objectForKey:@"type"] ] ];
        }
        
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            if (force){
                NSString* dropQuery = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", [obj tableName]];
                NSLog(@"Running: %@",dropQuery);
                [db executeUpdate: dropQuery];
            }
            
            NSString* query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);", [obj tableName], columnData];
            NSLog(@"Running: %@",query);
            
            if (![db executeUpdate: query]){
                if ([db lastErrorCode] != 0){
                    NSLog(@"RCActiveRecord Error %d: %@ Query: %@", [db lastErrorCode], [db lastErrorMessage], query);
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



@end

#pragma clang diagnostic pop
