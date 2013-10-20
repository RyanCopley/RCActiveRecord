RCActiveRecord
==============

An easy Obj-C ORM for iPhone, capable of ~0.15ms record read/writes (iPhone 5, iOS 7.0.2). 
Inspired by the Yii CActiveRecord (PHP) and Mongoose ORM (Node.JS).

Features
==========
* Fully Asyncronous Reads
* SQL-less queries
* Creates database structure and schema for you
* Transactioning for exceptionally fast queries
* A powerful conditions mechanism making writing queries a breeze (If you even call it writing queries!)
* Based on SQLite (Thanks to FMDB, https://github.com/ccgus/fmdb/)
* Storing NSArrays and NSDictionaries (Although you lose conditional support-- coming soon!)
* SQL Injection Proof
* Auto Timestamps (Created, Saved, Updated)
* Foreign Keys between other RCActiveRecords
* Foreign Key Auto Loading
* Full Transaction support (Starting, committing, and rolling back)

Features Coming Soon
==========
* Create models via JSON, and export models to JSON (By dictionary and array)
* Multiple database support
* A "open" function (It defaults to db.sqlite currently)
* NSArray / NSDictionary Conditional Support
