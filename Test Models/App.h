//
//  App.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"
#import "Person.h"

@interface App : RCActiveRecord

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* gitCommitHash;
@property (strong, nonatomic) NSNumber* versionNumber;
@property (strong, nonatomic) NSArray* files;
@property (strong, nonatomic) NSDictionary* settings;
@property (strong, nonatomic) Person* owner;

@end
