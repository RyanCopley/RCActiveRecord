//
//  RCCriteria.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c)2013 Ryan Copley. All rights reserved.
//

#import "RCCriteria.h"

@implementation RCCriteria

@synthesize limit, offset;

-(id)init{
    self = [super init];
    if (self) {
        conditions = [[NSMutableArray alloc] init];
        order = RCNoOrder;
        overrideSQL = nil;
    }
    return self;
}

-(NSString*)stringFromCompareOperator:(RCActiveRecordComparisonOperator)operator{
    switch (operator) {
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

-(void)addCondition:(NSString*)columnName is:(RCActiveRecordComparisonOperator)comparer to:(id)value{
    // TODO: Should also check to ensure value is of type NSArray.
    if (comparer == RCIn || comparer == RCNotIn) {
        // TODO: Sanitize the array.
        NSString* arrayStr = [NSString stringWithFormat:@"\"%@\"", [((NSArray*)value)componentsJoinedByString:@"\",\""] ];
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
                [NSString stringWithFormat:@"%@",[self sanitize:value]]
             ]
         ];
    }
}

-(void)orderByAsc:(NSString*)columnName{
    order = RCAscend;
    orderColumn = [self sanitize:columnName];
}

-(void)orderByDesc:(NSString*)columnName{
    order = RCDescend;
    orderColumn = [self sanitize:columnName];
}

-(NSString*)generateWhereClause{
    if (overrideSQL != nil) {
        return overrideSQL;
    }
    NSMutableString * whereClause = [[NSMutableString alloc] init];
    //Conditions...
    if ([conditions count] > 0) {
        for (NSObject * condition in conditions) {
            [whereClause appendFormat: @"%@ AND ",condition];
        }
        whereClause = [[whereClause substringToIndex:whereClause.length - 4] mutableCopy];
    }else{
        whereClause = [@"1=1" mutableCopy];
    }
    //Limit...
    if (limit > 0) {
        [whereClause appendFormat: @" LIMIT %i ", limit];
    }
    //Offset
    if (offset > 0) {
        [whereClause appendFormat: @" OFFSET %i ", offset];
    }
    //Order...
    if (order != RCNoOrder) {
        NSString* orderStr;
        if (order == RCAscend) {
            orderStr = @"ASC";
        }
        if (order == RCDescend) {
            orderStr = @"DESC";
        }
        [whereClause appendFormat: @" ORDER BY `%@` %@", orderColumn, orderStr];
    }
    return whereClause;
}

-(void)where:(NSString*)sqlWhere {
    overrideSQL = sqlWhere;
}

-(NSString*)sanitize:(NSString*)string{
    string = [NSString stringWithFormat:@"%@",string];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    return string;
}

@end
