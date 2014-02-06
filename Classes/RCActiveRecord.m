//
//  RCActiveRecord.m
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"
#import "FMDatabaseAdditions.h"

#define RCACTIVERECORDLOGGING 0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation RCActiveRecord
@synthesize isNewRecord, isSavedRecord, _id, creationDate, updatedDate, savedDate, criteria;


static FMDatabaseQueue* RCActiveRecordQueue;
static NSMutableDictionary* RCActiveRecordSchemas;

static NSMutableDictionary* pkName;
static NSMutableDictionary* schemaData;
static NSMutableDictionary* foreignKeyData;
static NSDateFormatter *formatter;
static NSMutableDictionary* RCActiveRecordPreload;


static BOOL inTransaction;

#pragma mark Active Record functions
-(id) initModel{ return self; }
-(id) initDefaultValues{ return self; }

-(id)init{
    self = [super init];
    if (self){
        
        if (pkName == nil){
            pkName = [[NSMutableDictionary alloc] init];
            schemaData = [[NSMutableDictionary alloc] init];
            foreignKeyData = [[NSMutableDictionary alloc] init];
            RCActiveRecordPreload = [[NSMutableDictionary alloc] init];
            inTransaction = NO;
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        }
        
        
        _id = @(-1);
        NSString *key = NSStringFromClass( [self class] );
        if ([pkName objectForKey:key] == nil ){
            [pkName setObject:@"_id" forKey:key]; /* default */
            [schemaData setObject: [@{} mutableCopy] forKey:key]; /* empty */
            [foreignKeyData setObject: [@{} mutableCopy] forKey:key]; /* empty */
            [RCActiveRecordPreload setObject: @(1) forKey:key]; /* preload */
            [[self class] registerColumn:@"creationDate"];
            [[self class] registerColumn:@"savedDate"];
            [[self class] registerColumn:@"updatedDate"];
        }
        
        
        creationDate = [[NSDate alloc] init];
        savedDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
        updatedDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
        
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
    return [[[[self class] alloc] initDefaultValues] initModel];
}

-(int)recordCount{
    
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
    }
    
    NSString* query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause] ];
    if (RCACTIVERECORDLOGGING){
        NSLog(@"Query: %@", query);
    }
    __block int recordCount;
    [RCActiveRecordQueue inDatabase:^(FMDatabase *db) {
        recordCount = [db intForQuery:query];
    }];
    return recordCount;
    
}


-(RCResultSet*)customQuery:(NSString*) query{
    
    return [[RCResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


-(RCResultSet*)recordByPK:(NSNumber*) pk{
    
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
        [criteria addCondition: [self primaryKeyName] is:RCEqualTo to: [NSString stringWithFormat:@"%@",pk]];
    }
    [criteria setLimit:1];
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause] ];
    
    return [[RCResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}

-(RCResultSet*)recordsByAttribute:(NSString*) attributeName value:(id) value{
    if (!criteria){
        criteria = [[RCCriteria alloc] init];
        [criteria addCondition:attributeName is:RCEqualTo to: [NSString stringWithFormat:@"%@",value]];
    }
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause] ];
    
    return [[RCResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


+(RCResultSet*)allRecords{
    
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@;", [[self model] tableName] ];
    
    return [[RCResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}

+(RCResultSet*)allRecordsWithCriteria:(RCCriteria*)criteria{
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", [[self model] tableName], [criteria generateWhereClause] ];
    
    return [[RCResultSet alloc] initWithFMDatabaseQueue:RCActiveRecordQueue andQuery:query andActiveRecordClass: [self class]];
}


-(NSDictionary*) toJSON{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[self primaryKeyValue] forKey:[self primaryKeyName]];
    
    NSString *key = NSStringFromClass( [self class] );
    
    NSMutableDictionary* columnData = [schemaData objectForKey:key];
    
    for (NSString* key in columnData) {
        id value = [self performSelector:NSSelectorFromString(key)];
        if ([value isKindOfClass:[RCActiveRecord class]] == NO){
            [dict setValue: value forKey: key];
        }else{
            RCActiveRecord* tmp = value;
            [dict setValue: [tmp primaryKeyValue] forKey: key];
            
        }
    }
    
    return dict;
}

+(id) fromJSON:(id)json{
    if ([json isKindOfClass:[NSArray class]]){
        NSMutableArray* array = [[NSMutableArray alloc] init];
        id tmp = nil;
        for (NSDictionary* obj in json) {
            tmp = [[self class] fromJSON:obj];
            if (tmp != nil){
                [array addObject:tmp];
            }
        }
        return [NSArray arrayWithArray:array];
    }
    
    if ([json isKindOfClass:[NSDictionary class]]){
        id model = [[[[self class] alloc] initDefaultValues] initModel];
        
        
        for( NSString *aKey in json ){
            
            NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[aKey substringToIndex:1] uppercaseString],[aKey substringFromIndex:1]];
            id value = [json objectForKey:aKey];
            @try {
                [model performSelector: NSSelectorFromString(setConversion) withObject: value];
            }
            @catch (NSException* e){
                NSLog(@"[Error in RCActiveRecord] This object (%@) is not properly synthesized for the JSON Dictionary provided (Invalid setter). Unable to set: %@. Dictionary provided: %@", NSStringFromClass([model class]), aKey, json);
            }
            
            
        }
        
        NSString* aKey = [model primaryKeyName];
        NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[aKey substringToIndex:1] uppercaseString],[aKey substringFromIndex:1]];
        NSString* value = [json objectForKey:aKey];
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * myNumber = [f numberFromString:value];
        
        @try {
            [model performSelector: NSSelectorFromString(setConversion) withObject: myNumber];
        }
        @catch (NSException* e){
            NSLog(@"[Error in RCActiveRecord] This object (%@) is not properly synthesized for the JSON Dictionary provided (Invalid setter). Unable to set: %@. Dictionary provided: %@", NSStringFromClass([model class]), aKey, json);
        }
        
        
        
        return model;
    }
    
    return nil;
}


+(void)beginTransaction{
    if (!inTransaction){
        inTransaction = YES;
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            [db beginTransaction];
        }];
    }
}

+(void)commit{
    [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
        [db commit];
        inTransaction = NO;
    }];
}

+(void)rollback{
    [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
        [db rollback];
        inTransaction = NO;
    }];
}


-(NSString*) sanitize: (NSString*) value{
    value = [NSString stringWithFormat:@"%@",value];
    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    return value;
}

-(NSString*) encodeValueForSQLITE:(id) value {
    
    NSError* err;
    
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]){
        NSData* data = [NSJSONSerialization dataWithJSONObject:value options:kNilOptions error:&err];
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        return [self sanitize:str];
    }
    if ([value isKindOfClass:[NSDate class]]){
        return [self sanitize: [formatter stringFromDate: value]];
    }
    
    if ([value isKindOfClass:[RCActiveRecord class]]){
        return [self sanitize: [NSString stringWithFormat:@"%@",[((RCActiveRecord*)value) primaryKeyValue]]];
    }
    
    //Most other data types work well enough not to bother with any conversion.
    return [self sanitize:value];
}

-(BOOL) insertRecord{
    __block BOOL success = NO;
    @autoreleasepool {
        
        isNewRecord = NO;
        isSavedRecord = YES;
        
        self.savedDate = [NSDate date];
        
        NSString *key = NSStringFromClass( [self class] );
        NSDictionary* schema = [schemaData objectForKey:key];
        
        NSMutableString* columns = [[NSMutableString alloc] init];
        NSMutableString* data = [[NSMutableString alloc] init];
         
        for (NSString* columnName in [schema copy]){
            [columns appendFormat:@"%@, ", columnName];
            [data appendFormat:@"\"%@\", ", [self encodeValueForSQLITE: [self performSelector: NSSelectorFromString(columnName)]] ];
        }
        
        if ([columns isEqualToString:@""] == FALSE && [data isEqualToString:@""] == FALSE){
            
            columns = [[columns substringToIndex:columns.length-2] mutableCopy];
            data = [[data substringToIndex:data.length-2] mutableCopy];
            
            NSString* aux1=@"";
            NSString* aux2=@"";
            
            __block NSString* query = [NSString stringWithFormat:@"INSERT INTO %@ (%@%@) VALUES (%@%@)", [self tableName], columns, aux1, data,aux2];
            if (RCACTIVERECORDLOGGING){
                NSLog(@"Query: %@", query);
            }
            [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
                
                success = [db executeUpdate: query];
                NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[[self primaryKeyName] substringToIndex:1] uppercaseString],[[self primaryKeyName] substringFromIndex:1]];
                @try {
                    [self performSelector: NSSelectorFromString(setConversion) withObject: @([db lastInsertRowId])];
                }
                @catch (NSException* e){
                    NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to set: %@", [self primaryKeyName]);
                }
                
                
            }];
        }
    }
    return success;
}

-(BOOL) updateRecord{
    @autoreleasepool {
        
        if (isNewRecord == NO){
            isNewRecord = NO;
            isSavedRecord = YES;
            id obj = self;
            self.updatedDate = [NSDate date];
            
            NSString *key = NSStringFromClass( [self class] );
            NSDictionary* schema = [schemaData objectForKey:key];
            
            NSMutableString* updateData = [[NSMutableString alloc] init];
            
            for (NSString* columnName in schema){
                
                [updateData appendFormat:@"`%@`=\"%@\", ", columnName,[self encodeValueForSQLITE: [self performSelector: NSSelectorFromString(columnName)]] ];
            }
            
            if ([updateData isEqualToString:@""] == FALSE){
                
                updateData = [[updateData substringToIndex:updateData.length-2] mutableCopy];
                
                __block NSString* query = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE `%@`=\"%@\";", [obj tableName], updateData,[self primaryKeyName], [self primaryKeyValue]];
                if (RCACTIVERECORDLOGGING){
                    NSLog(@"Query: %@", query);
                }
                
                [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
                    
                    [db executeUpdate: query];
                    
                }];
            }
            return YES;
        }
    }
    return NO;
}


-(BOOL)saveRecord{
    if (RCACTIVERECORDLOGGING){
        NSLog(@"Saving record...");
    }
    
    if (isNewRecord){
        return [self insertRecord];
    }else if (isSavedRecord){
        return [self updateRecord];
    }
    
    return YES;
}

-(BOOL)deleteRecord{
    if (!isNewRecord && isSavedRecord){
        __block NSString* query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE `%@`='%@';", [self tableName], [self primaryKeyName], [self primaryKeyValue]];
        if (RCACTIVERECORDLOGGING){
            NSLog(@"Query: %@", query);
        }
        
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            
            [db executeUpdate: query];
            
        }];
    }
    return YES;
}


+(void) preloadModels:(BOOL)preload{
    NSString *key = NSStringFromClass( [self class] );
    return [RCActiveRecordPreload setObject:@(preload) forKey:key];
}

+(BOOL) preloadEnabled{
    NSString *key = NSStringFromClass( [self class] );
    return [[RCActiveRecordPreload objectForKey:key] boolValue];
}

+(BOOL) hasSchemaDeclared{
    NSString *key = NSStringFromClass( [self class] );
    return [[schemaData objectForKey:key] count] > 3;
}


+(BOOL) registerColumn:(NSString*) columnName{
    @autoreleasepool {
        
        NSString *key = NSStringFromClass( [self class] );
        
        NSMutableDictionary* columnData = [schemaData objectForKey:key];
        id obj = [[self alloc] initDefaultValues];
        
        [columnData setObject:@{
                                @"columnName" : columnName,
                                @"type" : NSStringFromClass([[obj performSelector:NSSelectorFromString(columnName)] class])
                                }
                       forKey: columnName];
        
        [schemaData setObject:columnData forKey:key];
    }
    return YES;
}


+(BOOL) generateSchema: (BOOL)force{
    @autoreleasepool {
        
        NSString *key = NSStringFromClass( [self class] );
        if (RCACTIVERECORDLOGGING){
            NSLog(@"Generating schema for table: %@",[[self alloc] tableName]);
        }
        id obj = [[self alloc] initDefaultValues];
        
        NSDictionary* schema = [schemaData objectForKey:key];
        if ([RCActiveRecordSchemas objectForKey: [obj tableName]] == nil) {
            
            [RCActiveRecordSchemas setObject: @"Defined" forKey: [obj tableName]];
            
            
            NSMutableString* columnData = [[NSMutableString alloc] init];
            [columnData appendFormat:@"%@ INTEGER PRIMARY KEY %@", [obj primaryKeyName], ([[obj primaryKeyName] isEqualToString:@"_id"] ? @"AUTOINCREMENT" : @"")];
            
            
            for (NSString* columnName in schema){
                NSDictionary* columnSchema = [schema objectForKey:columnName];
                
                [columnData appendFormat:@", %@ %@", columnName, [obj objCDataTypeToSQLiteDataType: [columnSchema objectForKey:@"type"] ] ];
            }
            if (force){
                [[self class] dropTable];
            }
            
            [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
                
                
                NSString* query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);", [obj tableName], columnData];
                if (RCACTIVERECORDLOGGING){
                    NSLog(@"Running: %@",query);
                }
                
                if (![db executeUpdate: query]){
                    if ([db lastErrorCode] != 0){
                        NSLog(@"RCActiveRecord Error %d: %@ Query: %@", [db lastErrorCode], [db lastErrorMessage], query);
                    }
                }
            }];
            
        }
    }
    return YES;
}

+(BOOL)updateSchema{
    [[self class] generateSchema:YES];
    return YES;
}

+(BOOL)trunctuate{
    
    [[self class] dropTable];
    
    [[self class] generateSchema:YES];
    return YES;
}

+(BOOL)dropTable{
    
    id obj = [self alloc];
    [RCActiveRecordSchemas removeObjectForKey:[obj tableName]];
    
    
    [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
        NSString* dropQuery = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", [obj tableName]];
        if (RCACTIVERECORDLOGGING){
            NSLog(@"Running: %@",dropQuery);
        }
        [db executeUpdate: dropQuery];
    }];
    return YES;
}


-(NSString*) primaryKeyName{
    NSString *key = NSStringFromClass( [self class] );
    
    return [pkName valueForKey:key];
}

-(NSNumber*) primaryKeyValue {
    return [self performSelector:NSSelectorFromString([self primaryKeyName])];
}


-(NSString*) tableName{
    return [NSStringFromClass([self class]) lowercaseString];
}

-(FMDatabaseQueue*) getFMDBQueue{
    return RCActiveRecordQueue;
}


//Internal
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

@end

#pragma clang diagnostic pop