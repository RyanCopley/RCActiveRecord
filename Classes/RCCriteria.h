//
//  RCCriteria.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#ifndef __RCActiveRecordComparisonOperators__
#define __RCActiveRecordComparisonOperators__

typedef enum  {
    /* Typical operators */
    RCGreaterThan,
    RCGreaterThanOrEqualTo,
    RCEqualTo,
    RCLessThan,
    RCLessThanOrEqualTo,
    RCNotEqualTo,
    
    RCLike,
    
    RCIn, // Arrays only
    RCNotIn, // Arrays only
    
} RCActiveRecordComparisonOperator;

typedef enum {
    RCAscend,
    RCDescend
} RCActiveRecordOrder;
#endif


@interface RCCriteria : NSObject{
    int limit;
    NSArray* conditions;
    RCActiveRecordOrder order;
    NSString* ordercolumn;
}

-(id) limit:(int) count;
-(id) addCondition:(NSString*) columnName is:(RCActiveRecordComparisonOperator) comparer to:(id) value;
-(id) orderByAsc:(NSString*) columnName;
-(id) orderByDesc:(NSString*) columnName;

-(NSString*) generateWhereClause;
@end
