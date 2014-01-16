//
//  RCActiveRecord.m
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"

#define RCACTIVERECORDLOGGING 0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation RCActiveRecord
@synthesize isNewRecord, isSavedRecord, _id, creationDate, updatedDate, savedDate;


static FMDatabaseQueue* RCActiveRecordQueue;
static NSMutableDictionary* RCActiveRecordSchemas;

static NSMutableDictionary* pkName;
static NSMutableDictionary* schemaData;
static NSMutableDictionary* foreignKeyData;
static NSDateFormatter *formatter;
static NSMutableDictionary* RCActiveRecordPreload;


static BOOL inTransaction;

#pragma mark Active Record functions
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
        @synchronized (@"elementTypesSynchronization"){
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


-(NSDictionary*) toJSON{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[self primaryKeyValue] forKey:[self primaryKey]];
    
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
        id model = [[[[self class] alloc] initModelValues] initModel];
        
        
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
        
        NSString* aKey = [model primaryKey];
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


-(void)beginTransaction{
    if (!inTransaction){
        inTransaction = YES;
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            [db beginTransaction];
        }];
    }
}

-(void)commit{
    [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
        [db commit];
        inTransaction = NO;
    }];
}

-(void)rollback{
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
    isNewRecord = NO;
    isSavedRecord = YES;
    
    self.savedDate = [NSDate date];
    id obj = self;
    
    NSString *key = NSStringFromClass( [self class] );
    NSDictionary* schema = [schemaData objectForKey:key];
    
    NSMutableString* columns = [[NSMutableString alloc] init];
    NSMutableString* data = [[NSMutableString alloc] init];
    
    for (NSString* columnName in schema){
        [columns appendFormat:@"%@, ", columnName];
        [data appendFormat:@"\"%@\", ", [self encodeValueForSQLITE: [self performSelector: NSSelectorFromString(columnName)]] ];
    }
    
    if ([columns isEqualToString:@""] == FALSE && [data isEqualToString:@""] == FALSE){
        
        columns = [[columns substringToIndex:columns.length-2] mutableCopy];
        data = [[data substringToIndex:data.length-2] mutableCopy];
        
        NSString* aux1=@"";
        NSString* aux2=@"";
        //        if ([[obj primaryKey] isEqualToString:@"_id"] == FALSE){
        //            aux1=[NSString stringWithFormat:@",%@",[obj primaryKey]];
        //            aux2=[NSString stringWithFormat:@",'%@'",[obj primaryKeyValue]];
        //        }
        
        __block NSString* query = [NSString stringWithFormat:@"INSERT INTO %@ (%@%@) VALUES (%@%@)", [obj tableName], columns, aux1, data,aux2];
        if (RCACTIVERECORDLOGGING){
            NSLog(@"Query: %@", query);
        }
        
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            
            [db executeUpdate: query];
            NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[[self primaryKey] substringToIndex:1] uppercaseString],[[self primaryKey] substringFromIndex:1]];
            @try {
                [self performSelector: NSSelectorFromString(setConversion) withObject: @([db lastInsertRowId])];
            }
            @catch (NSException* e){
                NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to set: %@", [self primaryKey]);
            }
            
        }];
    }
    return YES;
}

-(BOOL) updateRecord{
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
            
            __block NSString* query = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE `%@`=\"%@\";", [obj tableName], updateData,[self primaryKey], [self primaryKeyValue]];
            if (RCACTIVERECORDLOGGING){
                NSLog(@"Query: %@", query);
            }
            
            [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
                
                [db executeUpdate: query];
                
            }];
        }
        return YES;
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
        __block NSString* query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE `%@`='%@';", [self tableName], [self primaryKey], [self primaryKeyValue]];
        if (RCACTIVERECORDLOGGING){
            NSLog(@"Query: %@", query);
        }
        
        [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
            
            [db executeUpdate: query];
            
        }];
    }
    return YES;
}


-(BOOL)isNewRecord{
    return isNewRecord;
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


+(BOOL) registerPrimaryKey:(NSString*) columnName{
    NSString *key = NSStringFromClass( [self class] );
    [pkName setObject:columnName forKey:key];
    return YES;
}


+(BOOL) registerColumn:(NSString*) columnName{
    
    @synchronized(@"elementTypesSynchronization"){
        NSString *key = NSStringFromClass( [self class] );
        
        NSMutableDictionary* columnData = [schemaData objectForKey:key];
        
        id obj = [[self alloc] initModelValues];
        
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
    
    NSString *key = NSStringFromClass( [self class] );
    if (RCACTIVERECORDLOGGING){
        NSLog(@"Generating schema for table: %@",[[self alloc] tableName]);
    }
    id obj = [[self alloc] initModelValues];
    
    NSDictionary* schema = [schemaData objectForKey:key];
    if ([RCActiveRecordSchemas objectForKey: [obj tableName]] == nil) {
        
        [RCActiveRecordSchemas setObject: @"Defined" forKey: [obj tableName]];
        
        
        NSMutableString* columnData = [[NSMutableString alloc] init];
        [columnData appendFormat:@"%@ INTEGER PRIMARY KEY %@", [obj primaryKey], ([[obj primaryKey] isEqualToString:@"_id"] ? @"AUTOINCREMENT" : @"")];
        
        
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
    return YES;
}

+(BOOL)updateSchema{
    [[self class] generateSchema:YES];
    return YES;
}

+(BOOL)trunctuate{
    [[self class] dropTable];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [[[self class] alloc] initModel];
#pragma clang diagnostic pop
    return YES;
}

+(BOOL)dropTable{
    
    id obj = [self alloc];
    
    NSString *key = NSStringFromClass( [self class] );
    [schemaData setObject: [@{} mutableCopy] forKey:key];
    
    [RCActiveRecordQueue inDatabase:^(FMDatabase *db){
        NSString* dropQuery = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", [obj tableName]];
        if (RCACTIVERECORDLOGGING){
            NSLog(@"Running: %@",dropQuery);
        }
        [db executeUpdate: dropQuery];
    }];
    return YES;
}


-(NSString*) primaryKey{
    NSString *key = NSStringFromClass( [self class] );
    
    return [pkName valueForKey:key];
}

-(NSNumber*) primaryKeyValue {
    
    return [self performSelector:NSSelectorFromString([self primaryKey])];
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
