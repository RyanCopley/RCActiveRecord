//
//  RCActiveRecordTests.m
//  RCActiveRecordTests
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecordTests.h"
#import "Person.h"
#import "App.h"

#define testsize 100

@implementation RCActiveRecordTests

- (void)setUp{
    [super setUp];
    [Person model];
}

- (void)tearDown{
    [super tearDown];
}

- (void)testNewModel{
    STAssertNotNil([Person model], @"Person Model failed to load");
}

- (void)testFreshFlags{
    STAssertTrue([[Person model] isNewRecord], @"Fresh models should be marked as New");
    STAssertFalse([[Person model] isSavedRecord], @"Fresh models should not be marked as saved");
}

- (void)testSavedFlag{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    [p saveRecord];
    
    STAssertFalse([p isNewRecord], @"Saved models should not be new");
    STAssertTrue([p isSavedRecord], @"Saved models should be marked as saved");
    
}

- (void)testTableName{
    STAssertTrue([[[Person model] tableName] isEqualToString:@"person"], @"Table name should reflect class name in lowercase format");
}

- (void)testInsertRecord{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    STAssertTrue([[Person model] recordCount] == 0, @"There should be 0 person in the database.");
    [p insertRecord]; // 1
    [p insertRecord]; // 2
    STAssertTrue([[Person model] recordCount] == 2, @"There should be 2 people in the database.");
}

- (void)testSaveRecord{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    
    [p saveRecord]; // 1
    [p saveRecord]; // 1
    STAssertTrue([[Person model] recordCount] == 1, @"There should be only 1 person in the database.");
    [p insertRecord]; // 2
    [p insertRecord]; // 3
    STAssertTrue([[Person model] recordCount] == 3, @"There should be 3 people in the database.");
}


- (void)testUpdateRecord{
    [Person trunctuate];
    __block BOOL waitingForBlock = YES;
    
    Person* p = [Person model];
    p.name = @"Test-update";
    p.address = [@"Address-update" mutableCopy];
    [p saveRecord]; // Create a record to  update
    
    p.name = @"UpdatedName";
    [p updateRecord]; // Update it
    
    __block Person* tmp;
    [[[Person model] recordsByAttribute:@"address" value:@"Address-update"] execute:^(Person* record){
        tmp = record;
    } finished:^(BOOL error){
        waitingForBlock = NO;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    if (tmp == nil){
        STAssertTrue(false, @"Did not find any records");
    }else{
        STAssertTrue([tmp.name isEqualToString:@"UpdatedName"], @"Update did not update the database");
    }
    
}

- (void)testDeleteRecord{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    
    STAssertEquals([p recordCount], 0, @"Truncate did not empty table");
    [p saveRecord]; // 1
    STAssertEquals([p recordCount], 1, @"Save did not work");
    [p deleteRecord]; // 0
    STAssertEquals([p recordCount], 0, @"Delete did not remove the record");
}


- (void)testRecordCount{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    STAssertEquals([p recordCount], 0, @"There should be 0 records at this point");
    [p saveRecord]; // 1
    STAssertEquals([p recordCount], 1, @"There should be 1 record at this point");
    [p deleteRecord]; // 0
    STAssertEquals([p recordCount], 0, @"There should be 0 records at this point");
}




- (void)testDropTable{
    [Person generateSchema:YES];
    STAssertTrue([[Person model] insertRecord], @"Person should insert");
    [Person dropTable];
    STAssertFalse([[Person model] insertRecord], @"Person should fail to insert");
    [Person generateSchema:YES];
    STAssertTrue([[Person model] insertRecord], @"Person should insert");
}


- (void)testFetchingAllRecords {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    [p saveRecord];
    
    Person* p2 = [Person model];
    p2.name = @"Test2";
    p2.address = [@"Address2" mutableCopy];
    p2.age = @(22);
    p2.ip = @"192.253.23.15";
    [p2 saveRecord];
    
    __block int foundRecords = 0;
    [[Person allRecords] execute: ^(Person* record){
        foundRecords++;
    } finished: ^(BOOL error){
        waitingForBlock = NO;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    STAssertTrue(foundRecords==2, @"All records did not return a valid amount of objects");
}

- (void)testFetchingAllRecordsWithCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    [p saveRecord];
    
    Person* p2 = [Person model];
    p2.name = @"Test2";
    p2.address = [@"Address2" mutableCopy];
    p2.age = @(22);
    p2.ip = @"192.253.23.15";
    [p2 saveRecord];
    
    __block int foundRecords = 0;
    RCCriteria* criteria = [[RCCriteria alloc] init];
    [criteria addCondition:@"name" is:RCEqualTo to:@"Test"];
    [[Person allRecordsWithCriteria:criteria] execute: ^(Person* record){
        foundRecords++;
    } finished: ^(BOOL error){
        waitingForBlock = NO;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertTrue(foundRecords==1, @"All records w/ criteria did not return a valid amount of objects");
}


- (void)testSettingPrimaryKey{
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    STAssertTrue([[p primaryKeyValue] isEqualToNumber:@(-1)], @"Primary key should be -1 before being saved.");
    [p saveRecord];
    STAssertFalse([[p primaryKeyValue] isEqualToNumber:@(-1)], @"Primary key should not be -1 after being saved.");
}

- (void)testTruncate {
    int i = testsize;
    do {
        Person* p = [Person model];
        p.name = @"Test";
        [p saveRecord];
    } while (i-->1);
    STAssertTrue([[Person model] recordCount] >= testsize, @"There should be `testsize` people in the database.");
    
    [Person trunctuate];
    STAssertEquals([[Person model] recordCount], 0, @"There should not be any people in the database.");
}

- (void)testTransactioning {
    [Person trunctuate];
    [Person beginTransaction];
    int i = testsize;
    do {
        Person* p = [Person model];
        p.name = @"Test";
        [p saveRecord];
        if (i == floor(testsize/2)){
            [Person rollback];
            [Person beginTransaction];
        }
    } while (i-->1);
    [Person commit];
    int endCount = [[Person model] recordCount];
    
    STAssertTrue( (endCount==testsize/2-1), @"Rollback did not remove first half of testsize.");
}

- (void)testJSONEncoding {
    Person* p = [Person model];
    p.name = @"Json Test";
    p.address = [@"Json Test Address" mutableCopy];
    p.ip = @"localhost";
    p.age = @(100);
    NSDictionary* obj = [p toJSON];
    
    STAssertTrue([[obj objectForKey:@"_id"] isEqual: @(-1)], @"_id should be -1 from JSON");
    STAssertTrue([[obj objectForKey:@"address"] isEqualToString: p.address], @"address should be supplied from JSON");
    STAssertTrue([[obj objectForKey:@"ip"] isEqualToString: @"localhost"], @"ip should be supplied from JSON");
    STAssertTrue([[obj objectForKey:@"age"] isEqual: @(100)], @"age should be 0 from JSON");
}


- (void)testJSONDecoding {
    Person* p = [Person fromJSON:
                 @{
                   @"name" : @"test",
                   @"address" : @"json",
                   @"age" : @(22)
                   }
                 ];
    
    STAssertNil(p._id, @"_id should be -1 from JSON");
    STAssertTrue([p.address isEqualToString:@"json"], @"address should be supplied from JSON");
    STAssertTrue([p.age isEqual: @(22)], @"age should be 100 from JSON");
}


- (void)testJSONArrayDecoding {
    NSArray* people = [Person fromJSON:
                 @[@{
                       @"name" : @"test",
                       @"address" : @"json",
                       @"age" : @(21)
                       },@{
                       @"name" : @"test2",
                       @"address" : @"json2",
                       @"age" : @(22)
                       }]
                 ];
    
    STAssertTrue([people count] == 2, @"The supplied JSON should generate 2 records");
    STAssertTrue([((Person*)people[0]).name isEqualToString:@"test"], @"The first record should have the name `test`");
    STAssertTrue([((Person*)people[1]).address isEqualToString:@"json2"], @"The second record should have the address `json2`");
}

@end
