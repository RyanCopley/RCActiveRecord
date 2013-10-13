//
//  RCExampleCode.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/12/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCExampleCode.h"
#import "Person.h"
#import "App.h"

@implementation RCExampleCode

-(void) runExample{
    
    Person* p = [Person model];
    p.name = @"Ryan C.";
    p.address = [@"Fisher Street" mutableCopy];
    p.age = @(21);
    p.ip = @"127.0.0.1";
    NSLog(@"ID (Before save) [Should be -1, since it is not set]: %@",p._id);
    [p saveRecord]; // <-- Inserts since it is a NEW model
    NSLog(@"ID (After save) [Should be NOT -1]: %@",p._id);
    [p saveRecord]; // <-- Updates since it has previously been saved
    p.address = [@"Price Street" mutableCopy];
    [p updateRecord]; // <-- Updates since it has previously been saved
    p.address = [@"Rice Street" mutableCopy];
    [p saveRecord]; // <-- Updates since it has previously been saved
    NSLog(@"ID (Shouldn't change): %@",p._id);
    
    //Empty the table `App`
    [App trunctuate];
    
    App* a = [App model];
    
    int testSize = 1000;
    int i = testSize;
    a.address2 = @"Test St";
    
    
    __block NSTimeInterval writeStart = [NSDate timeIntervalSinceReferenceDate];
    [a beginTransaction];
    [a beginTransaction];//Whoops! Started a transaction twice! No worries, we safe guard against this.
    do {
        a.name2 = [NSString stringWithFormat:@"Ryan-%i",arc4random()%10000];
        a.age2 = @(arc4random()%50 + 18);
        a.array = @[@(arc4random()%50),@(arc4random()%50),@(arc4random()%50),@(arc4random()%50),@(arc4random()%50)];
        a.dict = @{@"Key":@(arc4random()%10000)};
        [a insertRecord];
    } while (i-->0);
    
    [a commit]; //Commit (write) all changes to the database. This is the key to having exceptionally fast SQLite performance!
    
    //Delete the latest entry (Since we INSERTED `testSize` times, `a` links to the MOST RECENT insertion.
    [a deleteRecord];
    
    
    //Benchmark how long it took us to write `testSize` entries
    NSTimeInterval writeDuration = [NSDate timeIntervalSinceReferenceDate] - writeStart;
    NSLog(@"(WRITE) Duration: %f, count: %i, seconds per record: %f", writeDuration, testSize, (writeDuration/testSize));
    
    
    //Now lets benchmark reading. As you see, this is a fully asyncronous read! Yay!
    __block int recordCount = 0;
    __block NSTimeInterval readStart = [NSDate timeIntervalSinceReferenceDate];
    
    [[[App model] allRecords] execute: ^(App* record){
        NSDate* d = record.creationDate;
        
        //NSLog(@"Age: %@ is %@ years old with objs: %@, dict: %@ insertedDate: %@", record.name2,record.age2, record.array, record.dict, record.creationDate);
        recordCount++;
    } finished: ^(BOOL error){
        //Once we run out of models from SQLite, this block is called. It is optional, so you don't have to have it.
        NSTimeInterval readDuration = [NSDate timeIntervalSinceReferenceDate] - readStart;
        NSLog(@"(READ) Duration: %f, count: %i, seconds per record: %f", readDuration, recordCount, (readDuration/recordCount));
    }];

    
}
@end
