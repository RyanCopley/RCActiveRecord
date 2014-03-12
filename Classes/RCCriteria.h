//
//  RCCriteria.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c)2013 Ryan Copley. All rights reserved.
//

#ifndef __RCActiveRecordComparisonOperators__
#define __RCActiveRecordComparisonOperators__

typedef enum  {
	RCGreaterThan = 0,
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
	RCDescend,
	RCNoOrder
} RCActiveRecordOrder;

#endif


@interface RCCriteria : NSObject {
	NSMutableArray *conditions;
	RCActiveRecordOrder order;
	NSString *orderColumn;
	NSString *overrideSQL;
}

@property (nonatomic, assign) int limit; //Tested
@property (nonatomic, assign) int offset; //Tested

- (void)addCondition:(NSString *)columnName is:(RCActiveRecordComparisonOperator)comparer to:(id)value; //Tested
- (void)orderByAsc:(NSString *)columnName; //Tested
- (void)orderByDesc:(NSString *)columnName; //Tested
- (void)where:(NSString *)sqlWhere; //Tested //Note: The [RCCriteria where: ...] function will override ANY and ALL conditions provided. It is one or the other, not both.
- (NSString *)generateWhereClause;

@end
