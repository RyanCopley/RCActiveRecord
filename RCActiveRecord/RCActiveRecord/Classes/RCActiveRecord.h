//
//  RCActiveRecord.h
//  ObjCActiveRecord
//
//  Created by Ryan Copley on 8/13/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

typedef enum  {
    /* Typical operators */
    RCGreaterThan,
    RCGreaterThanOrEqualTo,
    RCEqualTo,
    RCLessThan,
    RCLessThanOrEqualTo,
    RCNotEqualTo,
    
    /* These are range operators. If you are querying an ID of 7 with RCDifferenceOf 2, it will get from 5 to 9. */
    /* RCLessDifferenceOf would be 5 to 7, and RCGreaterDifferenceOf is from 7 to 9 */
    RCLessDifferenceOf,
    RCDifferenceOf,
    RCGreaterDifferenceOf
} RCActiveRecordComparisonOperator;


@interface RCActiveRecord : NSObject{
    BOOL isNewRecord;
    NSString* pkName;
    NSArray* errors;
    
    NSMutableArray* recordData;
    NSMutableArray* conditions;
}



+(id)model;

-(id)recordByIntPK:(int) pk;
-(id)recordByPK:(NSNumber*) pk;
-(NSArray*)recordsByAttribute:(NSString*) attributeName value:(id) value;
-(NSArray*)allRecords;


-(id)limit:(int) count;
-(id)addCondition:(NSString*) columnName is:(RCActiveRecordComparisonOperator) comparer to:(id) value;
-(id)orderByAsc:(NSString*) columnName;
-(id)orderByDesc:(NSString*) columnName;

-(id)joinWith:(id) resultSet foreignKeyName:(NSString*) foreignKey;
-(id)mergeResults:(id) resultSet;

-(BOOL)saveRecord;
-(BOOL)deleteRecord;

-(void)generateSchema;
-(void)updateSchema;
-(void)dropTable;

-(BOOL)registerPrimaryKey:(NSString*) title;
-(BOOL)registerVariable:(NSString*) title;

-(NSString*)recordIdentifier;
-(FMDatabaseQueue*) getDB;


@end
