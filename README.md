# Edible
[![Build Status](https://travis-ci.org/aweidner/edible.svg?branch=master)](https://travis-ci.org/aweidner/edible)
[![Coverage Status](https://coveralls.io/repos/github/aweidner/edible/badge.svg?branch=master)](https://coveralls.io/github/aweidner/edible?branch=master)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

Edible is an **E**mbe**d**da**ble** database written in Lua.  It is heavily inspired and derived from
Sqlite. Basically Edible is a less capable Sqlite clone.

# Goals

* Zero dependencies 
* Both in memory and on disk options
* Support a subset of Sqlite functionality

# Why? 

The main purpose is to understand the internals of Sqlite and databases in general by building one
from scratch.  If the code and
documentation for Edible ends up being clean enough I hope that it can be used as
a tutorial that anyone can follow along with to build a small database themselves.

# Architecture

The architecture for Edible will closely follow that of Sqlite (see https://www.sqlite.org/arch.html)
for a diagram.

# Tasks and project planning 

The project will be tackled in two phases. The first
phase focuses on trying to make Edible an actual database -- albeit in a very limited fashion.
The second phase focuses on optimizations and adding features to make working with Edible easier.

## Phase 1

- [ ] Create a tree structure to hold data
- [ ] Add the integer data type (32 bit only)
- [ ] Add the string data type (UTF-8)

At this point I should be able to store string and integer data into the tree structure and retrieve it.  No indexing
or anything yet, basically just a tree straight out of a Data Structures textbook.

- [ ] Create a tokenizer for SQL syntax
- [ ] Create a parser for SQL syntax
- [ ] Support for SELECT statements
- [ ] Support for INSERT statements
- [ ] Support for CREATE TABLE statements

After this I should have a basic extensible grammar that I can add commands and features to.  Not hooked up to the tree
structure at all but I can operate this through test cases.  The initial two commands are to implement just enough to be
able to read and write data

- [ ] Create the Code Generator

This involves mapping the SQL grammar down to something that can work with the tree structure.  Since I won't be implementing
the virtual machine that Sqlite has, this will most likely map down to function calls.  Essentially this is making the query 
planner which will generate a set of function calls to get or write data into the tree structure

- [ ] Create the SQL Command Processor and an interface to operate it

After this point we have a *very* limited database that can just do INSERT and SELECT statements.  Everything will be
in memory at this point as well.

- [ ] UPDATE
- [ ] DELETE
- [ ] DROP TABLE

After these commands the database will sort of start to look like a real database.  Around this time we should have a small terminal
application that can be used as a frontend to the database as well.  This marks the end of the first phase.

## Phase 2

- [ ] Support `EXPLAIN`

This needs to be the first thing supported so that I have an interface into how the database is actually using indexes

- [ ] Any other "basic" SQL commands like `ALTER TABLE`

This task is more or less a placeholder for now.  I'm not sure how much time I want to dedicate to it.  Hopefully it's just
a matter of implementing a few commands that were not done in Phase 1.

- [ ] Disk based file format and B-Tree
- [ ] Indexes
- [ ] Transactions

This is the meat of the project and implementing these three features will probably take the most time and be the most "interesting"

- [ ] Support analysis for improving the query planner 

Sqlite has the `ANALYZE` command which helps the query planner make more efficient choices in certain scenarios.  This is honestly just
really cool and I want to take a stab at it.

- [ ] Multi-client support

This is just a rough outline and other tasks might pop up while implementing the larger roadmap plans.  If they do they'll be added to
this list.

# What won't be covered

* Lots of compatibility issues - If the machine in question can run Lua 5.3, the database should work.  Otherwise no guarantees.
* Special Date/Time implementations and functionality
* Views, Virtual tables, lots of other SQL features
* Sqlite's virtual machine
