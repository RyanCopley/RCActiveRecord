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

#import "RCMigrationAssistant.h"

#define testsize 100

@implementation RCActiveRecordTests

-(void)setUp {
    [super setUp];
    [Person model];
    
    [RCMigrationAssistant model]; //Kickstart off the migration assistant
}

-(void)tearDown {
    [super tearDown];
}

-(void)testNewModel {
    STAssertNotNil([Person model], @"Person Model failed to load");
}

-(void)testFreshFlags {
    STAssertTrue([[Person model] isNewRecord], @"Fresh models should be marked as New");
    STAssertFalse([[Person model] isSavedRecord], @"Fresh models should not be marked as saved");
}

-(void)testSavedFlag {
    [Person trunctuate];
    Person *p = [Person model];
    p.name = @"Test";
    [p saveRecord];
    
    STAssertFalse([p isNewRecord], @"Saved models should not be new");
    STAssertTrue([p isSavedRecord], @"Saved models should be marked as saved");
    
}

-(void)testTableName {
    STAssertTrue([[[Person model] tableName] isEqualToString:@"person"], @"Table name should reflect class name in lowercase format");
}

-(void)testInsertRecord {
    [Person trunctuate];
    Person *p = [Person model];
    p.name = @"Test";
    STAssertTrue([[Person model] recordCount] == 0, @"There should be 0 person in the database.");
    [p insertRecord]; // 1
    STAssertTrue([[Person model] recordCount] == 1, @"There should be 1 people in the database.");
    [p insertRecord]; // 2
    STAssertTrue([[Person model] recordCount] == 2, @"There should be 2 people in the database.");
}

-(void)testSaveRecord {
    [Person trunctuate];
    Person *p = [Person model];
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

-(void)testUpdateRecord {
    [Person trunctuate];
    __block BOOL waitingForBlock = YES;
    
    Person *p = [Person model];
    p.name = @"Test-update";
    p.address = [@"Address-update" mutableCopy];
    [p saveRecord]; // Create a record to  update
    
    p.name = @"UpdatedName";
    [p updateRecord]; // Update it
    
    __block Person *tmp;
    [[[Person model] recordsByAttribute:@"address" value:@"Address-update"] each:^(Person *record) {
        tmp = record;
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    if (tmp == nil) {
        STAssertTrue(false, @"Did not find any records");
    } else {
        NSLog(@"Name: %@", tmp.name);
        STAssertTrue([tmp.name isEqualToString:@"UpdatedName"], @"Update did not update the database");
    }
    
}

-(void)testDeleteRecord {
    [Person trunctuate];
    Person *p = [Person model];
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

-(void)testRecordCount {
    [Person trunctuate];
    Person *p = [Person model];
    p.name = @"Test";
    STAssertEquals([p recordCount], 0, @"There should be 0 records at this point");
    [p saveRecord]; // 1
    STAssertEquals([p recordCount], 1, @"There should be 1 record at this point");
    [p deleteRecord]; // 0
    STAssertEquals([p recordCount], 0, @"There should be 0 records at this point");
}

-(void)testDropTable {
    [Person trunctuate];
    [Person generateSchema:YES];
    STAssertTrue([[Person model] insertRecord], @"Person should insert");
    [Person dropTable];
    STAssertFalse([[Person model] insertRecord], @"Person should fail to insert");
    [Person generateSchema:YES];
    STAssertTrue([[Person model] insertRecord], @"Person should insert");
}

-(void)testFetchingAllRecords {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    [p saveRecord];
    
    Person *p2 = [Person model];
    p2.name = @"Test2";
    p2.address = [@"Address2" mutableCopy];
    p2.age = @(22);
    p2.ip = @"192.253.23.15";
    [p2 saveRecord];
    
    __block int foundRecords = 0;
    [[Person allRecords] each:^(Person *record) {
        foundRecords++;
        
        if (foundRecords == 1) {
            STAssertTrue([record.name isEqualToString:@"Test"], @"Loading the record did not render the correct name.");
        }
        
        if (foundRecords == 2) {
            STAssertTrue([record.name isEqualToString:@"Test2"], @"Loading the record did not render the correct name.");
        }
    } finished:^(NSInteger count, BOOL error) {
        STAssertFalse(error, @"An error was flagged");
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    STAssertTrue(foundRecords==2, @"All records did not return a valid amount of objects");
}

-(void)testFetchingAllRecordsWithCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    [p saveRecord];
    
    Person *p2 = [Person model];
    p2.name = @"Test2";
    p2.address = [@"Address2" mutableCopy];
    p2.age = @(22);
    p2.ip = @"192.253.23.15";
    [p2 saveRecord];
    
    __block int foundRecords = 0;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria addCondition:@"name" is:RCEqualTo to:@"Test"];
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        foundRecords++;
        
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertTrue(foundRecords==1, @"All records w/ criteria did not return a valid amount of objects");
}

-(void)testFetchingAllRecordsWithComplexCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.age = @(21);
    [p saveRecord];
    
    Person *p2 = [Person model];
    p2.age = @(30);
    [p2 insertRecord];
    p2.age = @(31);
    [p2 insertRecord];
    p2.age = @(32);
    [p2 insertRecord];
    p2.age = @(33);
    [p2 insertRecord];
    p2.age = @(34);
    [p2 insertRecord];
    
    
    __block int foundRecords = 0;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria addCondition:@"age" is:RCLessThan to:@(33)];
    [criteria addCondition:@"age" is:RCGreaterThan to:@(25)];
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        foundRecords++;
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertTrue(foundRecords==3, @"All records w/ complex criteria did not return a valid amount of objects");
}

-(void)testFetchingAllRecordsWithLimitCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.age = @(21);
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    [p insertRecord];
    
    __block int foundRecords = 0;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria addCondition:@"age" is:RCLessThan to:@(33)];
    [criteria addCondition:@"age" is:RCGreaterThan to:@(19)];
    [criteria setLimit:2];
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        foundRecords++;
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertTrue(foundRecords==2, @"All records w/ complex + limit criteria did not return a valid amount of objects");
}

-(void)testFetchingAllRecordsWithLimitAndOffset {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.age = @(80);
    [p insertRecord];
    p.age = @(70);
    [p insertRecord];
    p.age = @(60);
    [p insertRecord];
    p.age = @(50);
    [p insertRecord];
    p.age = @(30);
    [p insertRecord];
    p.age = @(40);
    [p insertRecord];
    p.age = @(20);
    [p insertRecord];
    p.age = @(10);
    [p insertRecord];
    p.age = @(0);
    [p insertRecord];
    
    __block int recordCount = 0;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria setOffset:2];
    [criteria setLimit:5];
    
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        recordCount++;
        
        if (recordCount == 1) {
            STAssertTrue([record.age isEqual:@(60)], @"This age should be 60.");
        }
        
        if (recordCount == 2) {
            STAssertTrue([record.age isEqual:@(50)], @"This age should be 50.");
        }
        
        if (recordCount == 3) {
            STAssertTrue([record.age isEqual:@(30)], @"This age should be 30.");
        }
        
        if (recordCount == 4) {
            STAssertTrue([record.age isEqual:@(40)], @"This age should be 40.");
        }
        
        if (recordCount == 5) {
            STAssertTrue([record.age isEqual:@(20)], @"This age should be 20.");
        }
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertTrue(recordCount = 5, @"Results were not ordered correctly.");
}

-(void)testFetchingAllRecordsWithAscOrderCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.age = @(80);
    [p insertRecord];
    p.age = @(70);
    [p insertRecord];
    p.age = @(60);
    [p insertRecord];
    p.age = @(50);
    [p insertRecord];
    p.age = @(40);
    [p insertRecord];
    p.age = @(30);
    [p insertRecord];
    p.age = @(20);
    [p insertRecord];
    p.age = @(10);
    [p insertRecord];
    p.age = @(0);
    [p insertRecord];
    
    __block int pastSize = 0;
    __block BOOL error = NO;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria orderByAsc:@"age"];
    
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        if ([record.age intValue] < pastSize) {
            error = YES;
        }
        pastSize = [record.age intValue];
        
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertFalse(error, @"Results were not ordered correctly.");
}

-(void)testFetchingAllRecordsWithDescOrderCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.age = @(80);
    [p insertRecord];
    p.age = @(0);
    [p insertRecord];
    p.age = @(20);
    [p insertRecord];
    p.age = @(50);
    [p insertRecord];
    p.age = @(40);
    [p insertRecord];
    p.age = @(30);
    [p insertRecord];
    p.age = @(60);
    [p insertRecord];
    p.age = @(10);
    [p insertRecord];
    p.age = @(70);
    [p insertRecord];
    
    __block int pastSize = 100;
    __block BOOL error = NO;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria orderByDesc:@"age"];
    
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        if ([record.age intValue] > pastSize) {
            error = YES;
        }
        pastSize = [record.age intValue];
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertFalse(error, @"Results were not ordered correctly.");
}

-(void)testFetchingAllRecordsWithCustomWhere {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person *p = [Person model];
    p.age = @(80);
    [p insertRecord];
    p.age = @(0);
    [p insertRecord];
    p.age = @(20);
    [p insertRecord];
    p.age = @(50);
    [p insertRecord];
    p.age = @(40);
    [p insertRecord];
    p.age = @(30);
    [p insertRecord];
    p.age = @(60);
    [p insertRecord];
    p.age = @(10);
    [p insertRecord];
    p.age = @(70);
    [p insertRecord];
    
    __block int recordCount = 0;
    RCCriteria *criteria = [[RCCriteria alloc] init];
    [criteria where:@"age < 30"];
    [[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
        recordCount++;
    } finished:^(NSInteger count, BOOL error) {
        waitingForBlock = NO;
    }];
    
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    
    STAssertTrue(recordCount == 3, @"Results were not ordered correctly.");
}

-(void)testSettingPrimaryKey {
    Person *p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    STAssertTrue([[p primaryKeyValue] isEqualToNumber:@(-1)], @"Primary key should be -1 before being saved.");
    [p saveRecord];
    STAssertFalse([[p primaryKeyValue] isEqualToNumber:@(-1)], @"Primary key should not be -1 after being saved.");
}

-(void)testTruncate {
    int i = testsize;
    
    do {
        Person *p = [Person model];
        p.name = @"Test";
        [p saveRecord];
    } while (i-->1);
    STAssertTrue([[Person model] recordCount] >= testsize, @"There should be `testsize` people in the database.");
    
    [Person trunctuate];
    STAssertEquals([[Person model] recordCount], 0, @"There should not be any people in the database.");
}

-(void)testTransactioning {
    [Person trunctuate];
    [Person beginTransaction];
    int i = testsize;
    
    do {
        Person *p = [Person model];
        p.name = @"Test";
        [p saveRecord];
        
        if (i == floor(testsize/2)) {
            [Person rollback];
            [Person beginTransaction];
        }
    } while (i-->1);
    [Person commit];
    int endCount = [[Person model] recordCount];
    
    STAssertTrue( (endCount==testsize/2-1), @"Rollback did not remove first half of testsize.");
}

-(void)testJSONEncoding {
    Person *p = [Person model];
    p.name = @"Json Test";
    p.address = [@"Json Test Address" mutableCopy];
    p.ip = @"localhost";
    p.age = @(100);
    NSDictionary *obj = [p toJSON];
    
    STAssertTrue([[obj objectForKey:@"_id"] isEqual:@(-1)], @"_id should be -1 from JSON");
    STAssertTrue([[obj objectForKey:@"address"] isEqualToString:p.address], @"address should be supplied from JSON");
    STAssertTrue([[obj objectForKey:@"age"] isEqual:@(100)], @"age should be 0 from JSON");
}

-(void)testJSONDecoding {
    Person *p = [Person fromJSON:
                 @ {
                   @"name" :@"test",
                   @"address" :@"json",
                   @"age" :@(22)
                   }
                 ];
    
    STAssertNil(p._id, @"_id should be -1 from JSON");
    STAssertTrue([p.address isEqualToString:@"json"], @"address should be supplied from JSON");
    STAssertTrue([p.age isEqual:@(22)], @"age should be 100 from JSON");
}

-(void)testJSONArrayDecoding {
    NSArray *people = [Person fromJSON:
                 @[@ {
                       @"name" :@"test",
                       @"address" :@"json",
                       @"age" :@(21)
                       },
                     @ {
                       @"name" :@"test2",
                       @"address" :@"json2",
                       @"age" :@(22)
                       }]
                 ];
    
    STAssertTrue([people count] == 2, @"The supplied JSON should generate 2 records");
    STAssertTrue([((Person*)people[0]).name isEqualToString:@"test"], @"The first record should have the name `test`");
    STAssertTrue([((Person*)people[1]).address isEqualToString:@"json2"], @"The second record should have the address `json2`");
}

@end
