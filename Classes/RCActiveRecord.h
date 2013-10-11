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
    @protected
    NSNumber* _id;
    
    BOOL isNewRecord;
    BOOL isSavedRecord;
    
    NSArray* errors;
    
    RCCriteria* criteria;
    
}

@property (nonatomic) BOOL isNewRecord;
@property (nonatomic) BOOL isSavedRecord;
@property (nonatomic, retain) NSNumber* _id;

-(id) initModelValues; // Protocol method
-(id) initModel; // Protocol Method

-(id) init;
+(id) model;

-(void) setCriteria:(RCCriteria*) criteria;

-(RCActiveRecordResultSet*) recordByPK:(NSNumber*) pk;
-(RCActiveRecordResultSet*) recordsByAttribute:(NSString*) attributeName value:(id) value;
-(RCActiveRecordResultSet*) allRecords;


-(void)beginTransaction;
-(void)commit;

-(BOOL) insertRecord;
-(BOOL) updateRecord;
-(BOOL) saveRecord;
-(BOOL) deleteRecord;
-(BOOL) isNewRecord;

+(BOOL) hasSchemaDeclared;
+(BOOL) registerPrimaryKey:(NSString*) columnName;
+(BOOL) registerColumn:(NSString*) columnName;
+(BOOL) registerForeignKey:(Class*) activeRecord forColumn:(NSString*) column;


+(BOOL) generateSchema: (BOOL)force;
+(BOOL) updateSchema;
+(BOOL) trunctuate;
+(BOOL) dropTable;

-(NSString*) primaryKey;
-(NSNumber*) primaryKeyValue;
-(NSString*) tableName;

-(NSArray*) getErrors;

-(FMDatabaseQueue*) getFMDBQueue;


@end