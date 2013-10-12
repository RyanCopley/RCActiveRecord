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

Features Coming Soon
==========
* SQL Injection Proofing (Low priority, since it is a client side app)
* Storing NSArrays and NSDictionaries
* Foreign Keys between other RCActiveRecords
* Create models via JSON, and export models to JSON (By dictionary and array)
* Auto Timestamps
