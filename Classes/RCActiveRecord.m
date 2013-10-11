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
@synthesize isNewRecord;


static FMDatabaseQueue *queue;
static NSMutableDictionary* schemas;


#pragma mark Active Record functions
-(id)init{
    self = [super init];
    if (self){
        isNewRecord = YES;
        
        if (!queue){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString* dbPath =  [NSString stringWithFormat:@"%@/RCActiveRecord/db.sqlite",documentsDirectory];
            queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            
            schemaData = [[NSMutableDictionary alloc] init];
            schemas = [[NSMutableDictionary alloc] init];
            
            
        }
        
    }
    return self;
}

+(id) model{
    return [[[self class] alloc] init];
}

-(void)setCriteria:(RCCriteria*) _criteria{
    criteria = _criteria;
}




-(id)recordByPK:(NSNumber*) pk{
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE `%@`='%@' LIMIT 1", [self recordIdentifier], pkName, [self sanitize: [NSString stringWithFormat:@"%@",pk]] ];
    FMResultSet* s = [self performQuery:query];
    if (s == nil){
        return nil;
    }else {
        id AR = [[[self class] alloc] init];
        [(RCActiveRecord*)AR setIsNewRecord:NO];
        
        for (int i=0; i < [s columnCount]; i++){
            //Some type checking for some basic classes...
            
            NSString* varName = [s columnNameForIndex: i];
            NSString* dataType = NSStringFromClass([[AR performSelector:NSSelectorFromString(varName)] class]);
            NSLog(@"Data Type: %@", dataType);
            
            id value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
            
            
            NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
            @try {
                [AR performSelector: NSSelectorFromString(setConversion) withObject: value];
            }
            @catch (NSException* e){
                NSLog(@"[Email to RCActiveRecord@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to set: %@", varName);
            }
        }
        
        return AR;
    }
    
}

-(NSArray*)recordsByAttribute:(NSString*) attributeName value:(id) value{
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE `%@`='%@' LIMIT 1", [self recordIdentifier], [self sanitize: attributeName], [self sanitize: value] ];
    
    FMResultSet* s = [self performQuery:query];
    if (s == nil){ return nil; }
    
    NSMutableArray* returnObjs = [[NSMutableArray alloc] init];
    do {
        [returnObjs addObject: [self rowToModel:s]];
    } while ([s next]);
    
    return returnObjs;
}


-(NSArray*)allRecords{
    
}


-(id)joinWith:(id) resultSet foreignKeyName:(NSString*) foreignKey{
    
}

-(id)mergeResults:(id) resultSet{
    
}

-(BOOL)saveRecord{
    
}

-(BOOL)deleteRecord{
    
}

-(void)generateSchema{
    
    if ([schemas objectForKey:[self recordIdentifier]] == nil) {
        
        [schemas setObject: [self schemaProfile] forKey: [self recordIdentifier]];
        
        NSMutableString* columnData = [[NSMutableString alloc] init];
        [columnData appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT", pkName];
        
        
        for (NSString* keys in schemaData){
            [columnData appendFormat:@", %@ TEXT", keys];
        }
        
        [queue inDatabase:^(FMDatabase *db){
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
    
}

-(BOOL)registerPrimaryKey:(NSString*) title{
    pkName = title;
}

-(BOOL)registerVariable:(NSString*) title{
    [schemaData addObject: title];
}

-(NSString*)recordIdentifier{
    return [NSStringFromClass([self class]) lowercaseString];
}

-(FMDatabaseQueue*) getFMDBQueue{
    return queue;
}



-(NSString*)sanitize:(NSString*)string{
    string = [NSString stringWithFormat:@"%@",string];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    return string;
}

-(FMResultSet*) performQuery:(NSString*)query {
    
    __block FMResultSet *s;
    __block BOOL ERROR = NO;
    [queue inDatabase:^(FMDatabase *db) {
        s = [db executeQuery: query];
        if (![s next]){
            ERROR = YES;
        }
    }];
    
    if (ERROR){
        return nil;
    }
    return s;
}

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

-(NSString*)dataTypeOfVariable:(NSString*)variableName{
    
    NSString* dataType = NSStringFromClass([[AR performSelector:NSSelectorFromString(variableName)] class]);
    
    return dataType;
}
@end

#pragma clang diagnostic pop
