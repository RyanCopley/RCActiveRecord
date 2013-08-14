//
//  RCCriteria.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

@interface RCCriteria : NSObject{
    
}



-(id)limit:(int) count;
-(id)addCondition:(NSString*) columnName is:(RCActiveRecordComparisonOperator) comparer to:(id) value;
-(id)orderByAsc:(NSString*) columnName;
-(id)orderByDesc:(NSString*) columnName;

@end
