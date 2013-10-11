//
//  RCActiveRecord.h
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#import "RCCriteria.h"
#import "RCActiveRecordResultSet.h"


@interface RCActiveRecord : NSObject{
    BOOL isNewRecord;
    NSArray* errors;
    
    NSString* pkName;
    NSMutableDictionary* schemaData;
    
    RCCriteria* criteria;
}

@property (nonatomic) BOOL isNewRecord;


-(void) setCriteria:(RCCriteria*) criteria;

-(RCActiveRecordResultSet*) recordByPK:(NSNumber*) pk;
-(RCActiveRecordResultSet*) recordsByAttribute:(NSString*) attributeName value:(id) value;
-(RCActiveRecordResultSet*) allRecords;

-(BOOL) saveRecord;
-(BOOL) deleteRecord;
-(BOOL) isNewRecord;

+(BOOL) generateSchema: (BOOL)force;
+(BOOL) isSchemaUptoDate;
+(BOOL) dropTable;
+(BOOL) emptyTable;

+(BOOL) hasSchemaDeclared;
+(BOOL) registerPrimaryKey:(NSString*) columnName;
+(BOOL) registerColumn:(NSString*) columnName;
+(BOOL) registerForeignKey:(Class*) activeRecord forColumn:(NSString*) column;

-(NSString*) primaryKey;
-(NSString*) tableName;
-(NSArray*) columns;

-(NSArray*) getErrors;

-(FMDatabaseQueue*) getFMDBQueue;


@end
