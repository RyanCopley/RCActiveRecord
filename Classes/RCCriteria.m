//
//  RCCriteria.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCCriteria.h"

@implementation RCCriteria

-(id) init{
    self = [super init];
    if (self){
        conditions = [[NSMutableArray alloc] init];
        limit = -1;
        order = RCNoOrder;
        overrideSQL = @"";
        sqlOverride = NO;
    }
    return self;
}

-(void) limit:(int) count{
    limit = count;
}

-(NSString*) stringFromCompareOperator:(RCActiveRecordComparisonOperator) operator{
    switch (operator){
        case RCGreaterThan:
            return @">";
            break;
        case RCGreaterThanOrEqualTo:
            return @">=";
            break;
        case RCEqualTo:
            return @"=";
            break;
        case RCLessThan:
            return @"<";
            break;
        case RCLessThanOrEqualTo:
            return @"<=";
            break;
        case RCNotEqualTo:
            return @"<>";
            break;
        case RCLike:
            return @"LIKE";
            break;
        case RCIn:
            return @"IN";
            break;
        case RCNotIn:
            return @"NOT IN";
            break;
    }
}

-(void) addCondition:(NSString*) columnName is:(RCActiveRecordComparisonOperator) comparer to:(id) value{
    
    // TODO: Should also check to ensure value is of type NSArray
    if (comparer == RCIn || comparer == RCNotIn){
        NSString* arrayStr = [NSString stringWithFormat:@"\"%@\"", [((NSArray*)value) componentsJoinedByString:@"\",\""] ];
        [conditions addObject:
            [NSString stringWithFormat:
                @"%@ %@ (%@)",
                columnName,
                [self stringFromCompareOperator:comparer],
                arrayStr
             ]
         ];
    }else{
        [conditions addObject:
            [NSString stringWithFormat:
                @"%@ %@ \"%@\"",
                columnName,
                [self stringFromCompareOperator:comparer],
                [NSString stringWithFormat:@"%@",value]
             ]
         ];
    }
}

-(void) orderByAsc:(NSString*) columnName{
    order = RCAscend;
    orderColumn = columnName;
}

-(void) orderByDesc:(NSString*) columnName{
    order = RCDescend;
    orderColumn = columnName;
    
}

-(NSString*) generateWhereClause{
    
    if (sqlOverride){
        return overrideSQL;
    }
    
    NSMutableString * whereClause = [[NSMutableString alloc] init];
    
    //Conditions...
    if ([conditions count] > 0){
        for (NSObject * condition in conditions) {
            [whereClause appendFormat: @"%@ AND",condition];
        }
        whereClause = [[whereClause substringToIndex:whereClause.length - 4] mutableCopy];
    }
    
    //Limit...
    if (limit > 0){
        [whereClause appendFormat: @" LIMIT %i ", limit];
    }
    
    //Order...
    if (order != RCNoOrder){
        NSString* orderStr;
        if (order == RCAscend){
            orderStr = @"ASC";
        }
        
        if (order == RCDescend){
            orderStr = @"DESC";
        }
        
        [whereClause appendFormat: @" ORDER BY `%@` %@", orderColumn, orderStr];
    }
    
    return whereClause;
}

-(void) where:(NSString*) sqlWhere {
    overrideSQL = sqlWhere;
    sqlOverride = YES;
}

@end
