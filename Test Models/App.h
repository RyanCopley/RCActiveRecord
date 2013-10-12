//
//  App.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"

@interface App : RCActiveRecord{
    NSNumber* appPK;
    NSString* name2;
    NSString* address2;
    NSNumber* age2;
}


@property (nonatomic, retain) NSNumber* appPK;
@property (nonatomic, retain) NSString* name2;
@property (nonatomic, retain) NSString* address2;
@property (nonatomic, retain) NSNumber* age2;

@end
