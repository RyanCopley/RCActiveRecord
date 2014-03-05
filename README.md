RCActiveRecord
==============

An easy Obj-C ORM for iPhone, capable of ~0.15ms record read/writes (iPhone 5, iOS 7.0.2). 
Inspired by the Yii CActiveRecord (PHP) and Mongoose ORM (Node.JS). Shout out to FMDB for doing the heavy SQLite work.

RCActiveRecord is designed to reduce boilerplate code for defining completely serializable and savable models. All the extra "fluff" features are designed to be out of the way unless you explicetly need them. Overall, I would like to say this is a fairly robust library.

Need to define a model quickly? 

![Basic Model](http://cl.ly/image/0Q0W070Z1O2G/Screen%20Shot%202014-03-04%20at%2011.19.56%20PM.png "Basic Model")

Later on you realize you need to upgrade the database?


![Basic Model+Migrations](http://cl.ly/image/1H2t1r0x3l12/Screen%20Shot%202014-03-04%20at%2011.20.06%20PM.png "Basic Model+Migrations")

Fetching records is also fairly straight forward:

![looking up a model](http://cl.ly/image/1H2t1r0x3l12/Screen%20Shot%202014-03-04%20at%2011.20.06%20PM.png "Looking up a model")
http://cl.ly/image/0E0l1O2P1T27/Screen%20Shot%202014-03-04%20at%2011.23.22%20PM.png



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
