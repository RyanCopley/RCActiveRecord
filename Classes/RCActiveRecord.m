//
//  RCActiveRecord.m
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c)2013 Ryan Copley. All rights reserved.
//

#import "RCInternals.h"
#import "RCActiveRecord.h"
#import "FMDatabaseAdditions.h"
#import "RCDataCoder.h"

#define RCACTIVERECORDLOGGING 0

@implementation RCActiveRecord

@synthesize isNewRecord, isSavedRecord;
@synthesize _id, creationDate, updatedDate, savedDate;
@synthesize criteria;

#pragma mark Active Record functions

- (void)schema {
	if ([[self class] hasSchemaDeclared] == NO) {
		RCInternals *internal = [RCInternals instance];

		NSString *key = NSStringFromClass([self class]);
        //Register a spot for the schema data if need be
		if ([internal.schemaData objectForKey:key] == nil) {
			[internal.schemaData setObject:[@{} mutableCopy] forKey:key];  /* empty */
		}
        
		[[self class] registerColumn:@"creationDate"];
		[[self class] registerColumn:@"savedDate"];
		[[self class] registerColumn:@"updatedDate"];
	}
}
- (void)defaultValues {
	_id = @(-1);
	creationDate = [[NSDate alloc] init];
	savedDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
	updatedDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
	isNewRecord = YES;
	isSavedRecord = NO;
}

+ (id)model {
	id model = [[self class] alloc];
	[model defaultValues];
	if ([[self class] hasSchemaDeclared] == NO) {
		[model schema];
		[[model class] generateSchema:NO];
	}
	return model;
}

- (int)recordCount {
	if (!criteria) {
		criteria = [[RCCriteria alloc] init];
	}

	NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@;", [self tableName], [criteria generateWhereClause]];
	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Query: %@", query);
	}
	__block int recordCount;
	RCInternals *internal = [RCInternals instance];
	[internal.internalQueue inDatabase: ^(FMDatabase *db) {
	    recordCount = [db intForQuery:query];
	}];

	return recordCount;
}

- (RCResultSet *)customQuery:(NSString *)query {
	RCInternals *internal = [RCInternals instance];
	return [[RCResultSet alloc] initWithFMDatabaseQueue:internal.internalQueue andQuery:query andActiveRecordClass:[self class]];
}

- (RCResultSet *)recordByPK:(NSNumber *)pk {
	if (!criteria) {
		criteria = [[RCCriteria alloc] init];
		[criteria addCondition:[self primaryKeyName] is:RCEqualTo to:[NSString stringWithFormat:@"%@", pk]];
	}

	[criteria setLimit:1];
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM `%@` WHERE %@;", [self tableName], [criteria generateWhereClause]];
	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Query: %@", query);
	}
	RCInternals *internal = [RCInternals instance];
	return [[RCResultSet alloc] initWithFMDatabaseQueue:internal.internalQueue andQuery:query andActiveRecordClass:[self class]];
}

- (RCResultSet *)recordsByAttribute:(NSString *)attributeName value:(id)value {
	if (!criteria) {
		criteria = [[RCCriteria alloc] init];
		[criteria addCondition:attributeName is:RCEqualTo to:[NSString stringWithFormat:@"%@", value]];
	}

	NSString *query = [NSString stringWithFormat:@"SELECT * FROM `%@` WHERE %@;", [self tableName], [criteria generateWhereClause]];
	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Query: %@", query);
	}
	RCInternals *internal = [RCInternals instance];
	return [[RCResultSet alloc] initWithFMDatabaseQueue:internal.internalQueue andQuery:query andActiveRecordClass:[self class]];
}

+ (RCResultSet *)allRecords {
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM `%@`;", [[self model] tableName]];
	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Query: %@", query);
	}
	RCInternals *internal = [RCInternals instance];
	return [[RCResultSet alloc] initWithFMDatabaseQueue:internal.internalQueue andQuery:query andActiveRecordClass:[self class]];
}

+ (RCResultSet *)allRecordsWithCriteria:(RCCriteria *)criteria {
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM `%@` WHERE %@;", [[self model] tableName], [criteria generateWhereClause]];
	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Query: %@", query);
	}
    
	RCInternals *internal = [RCInternals instance];
	return [[RCResultSet alloc] initWithFMDatabaseQueue:internal.internalQueue andQuery:query andActiveRecordClass:[self class]];
}

- (NSDictionary *)toJSON {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setValue:[self primaryKeyValue] forKey:[self primaryKeyName]];
	NSString *key = NSStringFromClass([self class]);

	RCInternals *internal = [RCInternals instance];
	NSMutableDictionary *columnData = [internal.schemaData objectForKey:key];
	for (NSString *key in columnData) {
		id value = [self getProperty:key];
		if ([value isKindOfClass:[RCActiveRecord class]] == NO) {
			[dict setValue:value forKey:key];
		}
		else {
			RCActiveRecord *tmp = value;
			[dict setValue:[tmp primaryKeyValue] forKey:key];
		}
	}

	return dict;
}

+ (id)fromJSON:(id)json {
	if ([json isKindOfClass:[NSArray class]]) {
		NSMutableArray *array = [[NSMutableArray alloc] init];
		id tmp = nil;
		for (NSDictionary *obj in json) {
			tmp = [[self class] fromJSON:obj];
			if (tmp != nil) {
				[array addObject:tmp];
			}
		}
		return [NSArray arrayWithArray:array];
	}
	if ([json isKindOfClass:[NSDictionary class]]) {
		id model = [[self class] alloc];
		[model defaultValues];
		for (NSString *aKey in json) {
			id value = [json objectForKey:aKey];
            [model setProperty:aKey toValue:value];
		}
		NSString *aKey = [model primaryKeyName];
		NSString *value = [json objectForKey:aKey];
		static NSNumberFormatter *f = nil;
		if (f == nil) {
			f = [[NSNumberFormatter alloc] init];
			[f setNumberStyle:NSNumberFormatterDecimalStyle];
		}
		NSNumber *myNumber = [f numberFromString:value];
        
        [model setProperty:aKey toValue:myNumber];

		return model;
	}
	return nil;
}

+ (void)beginTransaction {
	RCInternals *internal = [RCInternals instance];
	if (!internal.inTransaction) {
		internal.inTransaction = YES;
		[internal.internalQueue inDatabase: ^(FMDatabase *db) {
		    [db beginTransaction];
		}];
	}
}

+ (void)commit {
	__weak RCInternals *internal = [RCInternals instance];
	[internal.internalQueue inDatabase: ^(FMDatabase *db) {
	    [db commit];
	    internal.inTransaction = NO;
	}];
}

+ (void)rollback {
	__weak RCInternals *internal = [RCInternals instance];
	[internal.internalQueue inDatabase: ^(FMDatabase *db) {
	    [db rollback];
	    internal.inTransaction = NO;
	}];
}

// TODO: Refactor
- (BOOL)insertRecord {
	RCInternals *internal = [RCInternals instance];

	__block BOOL success = NO;
	isNewRecord = NO;
	isSavedRecord = YES;
	self.savedDate = [NSDate date];

	NSDictionary *schema = [internal.schemaData objectForKey:NSStringFromClass([self class])];

	NSMutableString *columns = [[NSMutableString alloc] init];
	NSMutableString *data = [[NSMutableString alloc] init];

	RCDataCoder *coder = [RCDataCoder sharedSingleton];
	for (NSString *columnName in[schema copy]) {
		[columns appendFormat:@"`%@`, ", columnName];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[data appendFormat:@"\"%@\", ", [coder encode:[self performSelector:NSSelectorFromString(columnName)]]];
#pragma clang diagnostic pop
	}

	if ([columns isEqualToString:@""] == FALSE && [data isEqualToString:@""] == FALSE) {
		columns = [[columns substringToIndex:columns.length - 2] mutableCopy]; //Remove the extra ", "
		data = [[data substringToIndex:data.length - 2] mutableCopy]; //Remove the extra ", "

		__block NSString *query = [NSString stringWithFormat:@"INSERT INTO `%@` (%@)VALUES (%@)", [self tableName], columns, data];
		if (RCACTIVERECORDLOGGING) {
			NSLog(@"RCActiveRecord: Query: %@", query);
		}

		[internal.internalQueue inDatabase: ^(FMDatabase *db) {
		    success = [db executeUpdate:query];
            
            [self setProperty:[self primaryKeyName] toValue:@([db lastInsertRowId])];
            
		}];
	}
	return success;
}

// TODO: Refactor
- (BOOL)updateRecord {
    
	if (isNewRecord == NO) {
		RCInternals *internal = [RCInternals instance];
		self.updatedDate = [NSDate date];

		NSDictionary *schema = [internal.schemaData objectForKey:NSStringFromClass([self class])];
		NSMutableString *updateData = [[NSMutableString alloc] init];
		RCDataCoder *coder = [RCDataCoder sharedSingleton];
		for (NSString *columnName in schema) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[updateData appendFormat:@"`%@`=\"%@\", ", columnName, [coder encode:[self performSelector:NSSelectorFromString(columnName)]]];
#pragma clang diagnostic pop
		}
        
		if ([updateData isEqualToString:@""] == FALSE) {
			updateData = [[updateData substringToIndex:updateData.length - 2] mutableCopy];
			__block NSString *query = [NSString stringWithFormat:@"UPDATE `%@` SET %@ WHERE `%@`=\"%@\";", [self tableName], updateData, [self primaryKeyName], [self primaryKeyValue]];
			if (RCACTIVERECORDLOGGING) {
				NSLog(@"RCActiveRecord: Query: %@", query);
			}

			[internal.internalQueue inDatabase: ^(FMDatabase *db) {
			    [db executeUpdate:query];
			}];
		}
		isSavedRecord = YES;
		return YES;
	}
	return NO;
}

- (BOOL)saveRecord {
	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Saving record...");
	}

	if (isNewRecord) {
		return [self insertRecord];
	}
	else if (isSavedRecord) {
		return [self updateRecord];
	}
	return NO;
}

- (BOOL)deleteRecord {
	if (!isNewRecord && isSavedRecord) {
		__block NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE `%@`='%@';", [self tableName], [self primaryKeyName], [self primaryKeyValue]];
		if (RCACTIVERECORDLOGGING) {
			NSLog(@"RCActiveRecord: Query: %@", query);
		}

		RCInternals *internal = [RCInternals instance];
		[internal.internalQueue inDatabase: ^(FMDatabase *db) {
		    [db executeUpdate:query];
		}];
		return YES;
	}
	return NO;
}

// TODO: Refactor 1/2
+ (BOOL)generateSchema:(BOOL)force {
	__block BOOL success = YES;
	[[self class] generateDefaultCoders];

	if (RCACTIVERECORDLOGGING) {
		NSLog(@"RCActiveRecord: Generating schema for table: %@", [[self alloc] tableName]);
	}
	id obj = [[self alloc] init];
	[obj defaultValues];
	RCInternals *internal = [RCInternals instance];
	NSString *key = NSStringFromClass([self class]);
	NSDictionary *schema = [internal.schemaData objectForKey:key];
	if ([internal.schemaIsDefined objectForKey:[obj tableName]] == nil) {
		[internal.schemaIsDefined setObject:@(1) forKey:[obj tableName]];   //This just stops us from constantly redefining.

		NSMutableString *columnData = [[NSMutableString alloc] init];
		[columnData appendFormat:@"%@ INTEGER PRIMARY KEY %@", [obj primaryKeyName], ([[obj primaryKeyName] isEqualToString:@"_id"] ? @"AUTOINCREMENT" : @"")];
		for (NSString *columnName in schema) {
			//NSDictionary *columnSchema = [schema objectForKey:columnName];
            
			[columnData appendFormat:@", `%@` %@", columnName, @"text"]; //This could be done more efficiently based on the datatype
		}
		if (force) {
			[[self class] dropTable];
		}
		[internal.internalQueue inDatabase: ^(FMDatabase *db) {
		    NSString *query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);", [obj tableName], columnData];
		    if (RCACTIVERECORDLOGGING) {
		        NSLog(@"RCActiveRecord: Running: %@", query);
			}

		    if (![db executeUpdate:query]) {
		        if ([db lastErrorCode] != 0) {
		            success = NO;
		            NSLog(@"RCActiveRecord: FMDB Error: %d: %@ Query: %@", [db lastErrorCode], [db lastErrorMessage], query);
				}
			}
		}];
	}
	return success;
}

+ (void)migrate:(void (^)())block{
    
    
    NSString *key = NSStringFromClass([self class]);
    RCInternals *internal = [RCInternals instance];
    
    //Grab a copy of the current schema
    NSArray* processedKeys = [[internal.schemaData objectForKey:key] allKeys];
    
    block();
    //Get the New+old schema
    NSMutableDictionary *freshSchema = [[internal.schemaData objectForKey:key] mutableCopy];
    
    //Set theory. New+old - old = new.
    [freshSchema removeObjectsForKeys: processedKeys];
    
    //Alter the DB to reflect the new
    __block NSString *tableName = [self tableName];
    [internal.internalQueue inDatabase: ^(FMDatabase *db) {
        for (NSString * newColumn in freshSchema) {
            NSString *query = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", tableName, newColumn];
            if (RCACTIVERECORDLOGGING) {
                NSLog(@"RCActiveRecord: Running: %@", query);
            }

            BOOL returnedValue = [db executeUpdate:query];
            if (RCACTIVERECORDLOGGING){
                if (!returnedValue){
                    NSLog(@"This migration was already performed");
                }else{
                    NSLog(@"Successfully migrated column: %@ to %@", newColumn, tableName);
                }
            }
        }
    }];
}

+ (void)generateDefaultCoders {
	RCDataCoder *coder = [RCDataCoder sharedSingleton];
	[coder addEncoderForType:[self class] encoder: ^NSString *(RCActiveRecord *obj) {
	    return [NSString stringWithFormat:@"%@", [obj primaryKeyValue]];
	}];

	[coder addDecoderForType:[self class] decoder: ^id (NSString *stringRepresentation, Class type) {
        //Eventually some preloading could go here
        return stringRepresentation;
	}];
}

+ (BOOL)updateSchema {
	[[self class] generateSchema:YES];
	return YES;
}

+ (BOOL)trunctuate {
	[[self class] dropTable];
	[[self class] generateSchema:YES];
	return YES;
}

+ (BOOL)dropTable {
	id obj = [[self alloc] init];
	__weak id weakobj = obj;

	RCInternals *internal = [RCInternals instance];
	[internal.schemaIsDefined removeObjectForKey:[obj tableName]];
	[internal.internalQueue inDatabase: ^(FMDatabase *db) {
	    NSString *query = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", [weakobj tableName]];
	    if (RCACTIVERECORDLOGGING) {
	        NSLog(@"RCActiveRecord: Running: %@", query);
		}
	    [db executeUpdate:query];
	}];
	return YES;
}


+ (BOOL)registerColumn:(NSString *)columnName {
	id obj = [[self alloc] init];
	[obj defaultValues];
    return [self registerColumn:columnName ofType: [[obj getProperty:columnName] class]];
}

+ (BOOL)registerColumn:(NSString *)columnName ofType:(Class) classType {
	RCInternals *internal = [RCInternals instance];
	NSString *key = NSStringFromClass([self class]);
	NSMutableDictionary *columnData = [internal.schemaData objectForKey:key];
	if (columnData == nil) {
		columnData = [[NSMutableDictionary alloc] init];
	}

    id obj = [[self alloc] init];
    [obj defaultValues];
    if ([[obj getProperty:columnName] class] == nil){
        //Hail Mary
        [obj setProperty:columnName toValue: [[classType alloc] init]];
    }
    
    NSString *type = NSStringFromClass([[obj getProperty:columnName] class]);
    
    if (type == nil){
        NSLog(@"Variable: %@ was not initialized with a defaultValue and you did not specify a class. I can't determine what a nil object is during runtime. ", columnName);
        return NO;
    }
    
    // TODO: I would like a true model here instead, eventually.
    [columnData setObject:@{ @"columnName" : columnName, @"type" : type } forKey: columnName];
    [internal.schemaData setObject:columnData forKey:key];
    return YES;
}

+ (BOOL)deleteColumn:(NSString *)columnName {
	RCInternals *internal = [RCInternals instance];
	NSString *key = NSStringFromClass([self class]);
	NSMutableDictionary *columnData = [internal.schemaData objectForKey:key];
	if (columnData == nil) {
		columnData = [[NSMutableDictionary alloc] init];
	}

	if ([columnData objectForKey:columnName] != nil) {
		[columnData removeObjectForKey:columnName];
		[internal.schemaData setObject:columnData forKey:key];
		return YES;
	}
	return NO;
}

// TODO: Refactor
+ (BOOL)hasSchemaDeclared {
	RCInternals *internal = [RCInternals instance];
	return [[internal.schemaData objectForKey:NSStringFromClass([self class])] count] > 3;   // This should not be hard coded in. It's 3 because I prepopulate 3 fields (creation time, update time, saved time or something like that)
}

- (NSString *)primaryKeyName {
	return @"_id";
}

- (NSNumber *)primaryKeyValue {
    return _id;
}

- (NSString *)tableName {
	return [NSStringFromClass([self class]) lowercaseString];
}

+ (NSString *)tableName {
	return [NSStringFromClass(self) lowercaseString];
}

- (FMDatabaseQueue *)getFMDBQueue { //Exposed for subclasses
	return [RCInternals instance].internalQueue;
}


//Internal

-(void) setProperty:(NSString*)prop toValue:(id)value{
    NSString *setConversion = [NSString stringWithFormat:@"set%@%@:", [[prop substringToIndex:1] uppercaseString], [prop substringFromIndex:1]];
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(setConversion) withObject:value];
#pragma clang diagnostic pop
    }
    @catch (NSException *e)
    {
        NSLog(@"RCActiveRecord: %@ object is not properly synthesized. Unable to set: %@", NSStringFromClass([self class]), prop);
    }
}

-(id) getProperty:(NSString*)prop {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:NSSelectorFromString(prop)];
#pragma clang diagnostic pop
    
}

@end
