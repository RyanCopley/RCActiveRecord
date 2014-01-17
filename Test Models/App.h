//
//  App.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"
#import "Person.h"

@interface App : RCActiveRecord{
    NSNumber* appPK;
    NSString* name2;
    NSString* address2;
    NSNumber* age2;
    NSArray* array;
    NSDictionary* dict;
    Person* person;
}


@property (strong, nonatomic)NSNumber* appPK;
@property (strong, nonatomic)NSString* name2;
@property (strong, nonatomic)NSString* address2;
@property (strong, nonatomic)NSNumber* age2;
@property (strong, nonatomic)NSArray* array;
@property (strong, nonatomic)NSDictionary* dict;
@property (strong, nonatomic)Person* person;

@end
