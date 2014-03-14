RCActiveRecord
==============

An easy Obj-C ORM for iPhone, capable of ~0.15ms record read/writes (iPhone 5, iOS 7.0.2). 
Inspired by the Yii CActiveRecord (PHP) and Mongoose ORM (Node.JS). Shout out to FMDB for doing the heavy SQLite work.

RCActiveRecord is designed to reduce boilerplate code for defining completely serializable and savable models. All the extra "fluff" features are designed to be out of the way unless you explicetly need them. Overall, I would like to say this is a fairly robust library.


### Install via CocoaPods
```ruby
pod 'RCActiveRecord', '~> 2.0'
```
(Or git check out 2.0.0)

## Requirements

- Xcode4 and above
- iOS 6.0 or above

## How to get started

Need to define a model quickly? (You also need the appropriate .h file with the properties defined as you wish)

```Objective-C
#import "Person.h"

@implementation Person

@synthesize name, address, age, ip, md5, version, sha1;

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    address = @"";
    age = @(0);
    ip = @"";
    version = @(1.0f);
    md5 = @"e21b0ff3877dca5c2b3c5a37f3fa3ee4"; // Bonus points to whoever cracks this hash.
    sha1 = @"";
}

-(void)schema{
    [super schema];
    [Person registerColumn:@"name"];
    [Person registerColumn:@"address"];
    [Person registerColumn:@"age"];
    [Person registerColumn:@"ip"];
}
@end
```

Later on you realize you need to upgrade the database?


```Objective-C
#import "Person.h"

@implementation Person

@synthesize name, address, age, ip, md5, version, sha1;

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    address = @"";
    age = @(0);
    ip = @"";
    version = @(1.0f);
    md5 = @"e21b0ff3877dca5c2b3c5a37f3fa3ee4"; // Bonus points to whoever cracks this hash.
    sha1 = @"";
}

-(void)schema{
    [super schema];
    [Person registerColumn:@"name"];
    [Person registerColumn:@"address"];
    [Person registerColumn:@"age"];
    [Person registerColumn:@"ip"];
}
-(BOOL) migrateToVersion_1{
    [Person registerColumn:@"version"];
    [Person deleteColumn:@"ip"];
    return YES;
}

-(BOOL) migrateToVersion_2{
    [Person registerColumn:@"md5"];
    return YES;
}
-(BOOL) migrateToVersion_3{
    [Person registerColumn:@"sha1"];
    return YES;
}

@end
```

Next you'll want to creating a record... It's as easy as your regular models!

```Objective-C
Person *p = [Person model];
p.name = @"Test Name";
p.address = @"Address";
p.age = @(21);
p.ip = @"localhost";
[p saveRecord];
```


Fetching all records is also fairly straight forward:

```Objective-C
[[Person allRecords] each:^(Person *record) {
    //Person records come in asynchronously!
} finished:^(BOOL error) {
    //Done processing. This is called even if there are no records.
}];
```

Oh, so you don't want all the records, but want to define a set of criteria? There's a few ways!

```Objective-C
RCCriteria *criteria = [[RCCriteria alloc] init];
[criteria addCondition:@"age" is:RCLessThan to:@(33)];
[criteria addCondition:@"age" is:RCGreaterThan to:@(25)];
[[Person allRecordsWithCriteria:criteria] each:^(Person *record) {
    [record goFishing];
} finished:^(BOOL error) {
    NSLog(@"No more people are going fishing");
 }];
```

Although sometimes creating an RCCriteria object can be a bit excessive, so,

```Objective-C
[[[Person model] recordsByAttribute:@"address" value:@"Address-update"] each:^(Person *record) {
    /// ...
} finished:^(BOOL error) {
    /// ...
}];
```

And by primary key...

```Objective-C
[[[Person model] recordsByPK:@(1)] each:^(Person *record) {
    /// ...
} finished:^(BOOL error) {
    /// ...
}];
```

Also, the finished: section is optional.

```Objective-C
[[[Person model] recordsByPK:@(1)] each:^(Person *record) {
    /// ... Records as they come in, but no finalized callback!
}];
```

Features
==========
* SQLite
* Fully Asyncronous, Queued Reads
* SQL-less queries (and optionally: SQL-full)
* Automatic table generation
* Transactioning for exceptionally fast queries
* A powerful conditions mechanism making writing queries a breeze (If you even call it writing queries!)
* Storing NSArrays and NSDictionaries
* Auto Timestamps (Created, Saved, Updated)
* Create models via JSON, and export models to JSON (By dictionary and array)
* Customizable data coders
* Foreign Keys between models
* Foreign Key Auto Loading / Manual Loading Modes
* Full Unit Tests (And passing ... )
* Migrations

Features Coming Soon
==========
* Multiple database support
* NSArray / NSDictionary Conditional Support
* Subclassed models
* Better error handling
* Prepared statements overhaul
* JSON Mapping
