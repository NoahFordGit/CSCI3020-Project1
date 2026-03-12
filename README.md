# CSCI 3020 – Project One  
## Physical Database Implementation (SQLite)

This repository contains the physical implementation of a relational database system developed for **CSCI 3020 – Advanced Database Topics at East Tennessee State University**.

The project models **Appalachian Outfitters**, a fictional outdoor equipment rental and retail business. The database demonstrates relational schema design, trigger-based validation, auditing, and query optimization using SQLite.

## Features

- **Normalized Relational Schema**  
  Implements a structured relational database with 37 entities representing customers, memberships, rental contracts, equipment units, inventory, and transactions.

- **SQL Schema Implementation**  
  Tables, relationships, and constraints are defined using SQL scripts to enforce relational integrity.

- **Trigger-Based Validation**  
  Triggers enforce business rules such as preventing overlapping rental contracts for the same equipment unit and validating contract activation logic.

- **Audit Logging**  
  A trigger records updates to contract activity, storing previous values, new values, and timestamps for change tracking.

- **Trigger Testing**  
  Dedicated SQL test cases validate trigger behavior and confirm that business rules are enforced correctly.

- **Query Optimization**  
  Validation queries were analyzed using `EXPLAIN QUERY PLAN`, and indexes were used to improve performance and avoid unnecessary table scans.


## Repository Contents

| File | Description |
|-----|-------------|
| `appalachian_outfitters.sqlite` | Fully implemented SQLite database containing schema, triggers, and test data |
| `schema.sqlite` | Initial schema creation file |
| `tables.sql` | SQL definitions for database tables and constraints |
| `triggers.sql` | Trigger implementations enforcing business rules |
| `triggerTests.sql` | Test cases for validating triggers and analyzing query performance |
| `README.md` | Project documentation |

## Authors

- Noah Ford  
- Olivia Smith  
- Vanay Rowell  

**CSCI 3020 – Advanced Database Topics**  
East Tennessee State University
