//
//  Person.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"

@interface Person : RCActiveRecord{
    NSString* name;
    NSString* ip;
    NSMutableString* address;
    NSNumber* age;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* ip;
@property (nonatomic, retain) NSMutableString* address;
@property (nonatomic, retain) NSNumber* age;

@end
