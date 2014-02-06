RCActiveRecord
==============

An easy Obj-C ORM for iPhone, capable of ~0.15ms record read/writes (iPhone 5, iOS 7.0.2). 
Inspired by the Yii CActiveRecord (PHP) and Mongoose ORM (Node.JS). Shout out to FMDB for doing the heavy SQLite work.

Features
==========
* SQLite
* Fully Asyncronous, Queued Reads
* SQL-less queries (and optionally: SQL-full)
* Automatic table generation
* Transactioning for exceptionally fast queries
* A powerful conditions mechanism making writing queries a breeze (If you even call it writing queries!)
* Storing NSArrays and NSDictionaries
* SQL Injection Proof
* Auto Timestamps (Created, Saved, Updated)
* Create models via JSON, and export models to JSON (By dictionary and array)
* Customizable data coders

Features Coming Soon
==========
* Multiple database support
* A "open" function (It defaults to db.sqlite currently)
* NSArray / NSDictionary Conditional Support
* Migrations (Researching ideas of the best way to do this)
* Full Test Suite (Half done-ish)
* Subclassed models
* Foreign Keys between other models
* Foreign Key Auto Loading / Manual Loading
