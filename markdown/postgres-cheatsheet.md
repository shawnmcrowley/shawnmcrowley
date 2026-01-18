# PostgreSQL Cheat Sheet

> **The Ultimate PostgreSQL Reference Guide** - Master PostgreSQL from basics to advanced techniques for professional database management

## 📚 Table of Contents

### [Part 1: Terminal Mastery (psql)](#part-1-terminal-mastery-psql)
- [Essential psql Commands](#essential-psql-commands)
- [Data Import & Export](#data-import--export)
- [Database Navigation](#database-navigation)
- [System Information](#system-information)

### [Part 2: SQL Productivity](#part-2-sql-productivity)
- [Data Manipulation](#data-manipulation)
- [Advanced Query Techniques](#advanced-query-techniques)
- [Data Type Conversions](#data-type-conversions)
- [Conditional Logic](#conditional-logic)

### [Part 3: JSON & NoSQL Features](#part-3-json--nosql-features)
- [JSON Data Extraction](#json-data-extraction)
- [JSON Operations](#json-operations)
- [Array Manipulation](#array-manipulation)
- [NoSQL-style Queries](#nosql-style-queries)

### [Part 4: Date & Time Operations](#part-4-date--time-operations)
- [Date Calculations](#date-calculations)
- [Time-based Analytics](#time-based-analytics)
- [Timezone Handling](#timezone-handling)

### [Part 5: Administration & Maintenance](#part-5-administration--maintenance)
- [Monitoring & Performance](#monitoring--performance)
- [Query Management](#query-management)
- [Database Maintenance](#database-maintenance)
- [Index Management](#index-management)

### [Part 6: Advanced Engineering](#part-6-advanced-engineering)
- [Complex Query Patterns](#complex-query-patterns)
- [Performance Optimization](#performance-optimization)
- [Data Streaming](#data-streaming)
- [Real-time Features](#real-time-features)

---

## Part 1: Terminal Mastery (psql)

### Essential psql Commands

> **💡 Pro Tip:** Master these commands to speed up your workflow and stop fighting the command line.

| Command | Description | Example |
|---------|-------------|---------|
| `\x auto` | Auto-format wide tables vertically | `\x auto` then run query |
| `\timing` | Show query execution time | `\timing` then run query |
| `\watch [seconds]` | Auto-refresh query results | `\watch 2` after query |
| `\e` | Open query in external editor | `\e` to edit complex queries |
| `\h [command]` | Show help for SQL command | `\h CREATE INDEX` |
| `\q` | Quit psql gracefully | `\q` |

#### The Readable View (`\x auto`)
```sql
-- Switch to vertical "card" view for wide tables
\x auto

-- Now your wide tables will look clean and readable
SELECT * FROM users WHERE id = 1;
```

#### The Stopwatch (`\timing`)
```sql
-- Enable timing to measure query performance
\timing

-- Run your query and see execution time
SELECT * FROM huge_table;
-- Output: Time: 142.503 ms
```

#### Real-time Monitoring (`\watch`)
```sql
-- Monitor query results in real-time
SELECT count(*) FROM orders WHERE status = 'pending';
\watch 2  -- Re-runs every 2 seconds
```

#### External Editor (`\e`)
```sql
-- Edit complex queries in your preferred editor
\e  -- Opens Vim/Nano, save and quit to execute
```

### Data Import & Export

| Command | Description | Syntax |
|---------|-------------|--------|
| `\copy` | Export data without root access | `\copy (SELECT * FROM table) TO 'file.csv' WITH CSV HEADER` |
| `COPY` | High-performance data import/export | `COPY table FROM 'file.csv';` |

#### Fast Export with `\copy`
```sql
-- Export to CSV without needing superuser privileges
\copy (SELECT * FROM users) TO 'users.csv' WITH CSV HEADER

-- Export with conditions
\copy (SELECT * FROM orders WHERE created_at > '2024-01-01') TO 'recent_orders.csv' WITH CSV HEADER
```

#### High-Performance Export with COPY
```sql
-- For massive datasets, use COPY for maximum speed
COPY (SELECT * FROM massive_logs WHERE created_at > NOW() - INTERVAL '1 day') 
TO '/tmp/logs.csv' WITH CSV HEADER;
```

### Database Navigation

| Command | Description | Use Case |
|---------|-------------|----------|
| `\d` | Describe table structure | `\d users` |
| `\d+` | Detailed table info with sizes | `\d+ users` (shows size, comments) |
| `\dn` | List all schemas | Enterprise databases with multiple schemas |
| `\du` | List all roles and privileges | Security audit |
| `\l` | List all databases | `\l+` shows sizes too |
| `\c [dbname]` | Connect to database | `\c my_production_db` |

#### X-Ray Vision (`\d+`)
```sql
-- Get detailed table information including size and comments
\d+ users

-- Output includes:
-- - Column details
-- - On-disk size (e.g., "Size: 15 MB") 
-- - Column descriptions
-- - Extended statistics
```

#### The Map (`\dn`)
```sql
-- Navigate schemas in enterprise databases
\dn
-- Lists: public, analytics, legacy_data, etc.

-- Switch to a specific schema
SET search_path TO analytics;
```

#### Security Guard (`\du`)
```sql
-- Check who has access and their privileges
\du
-- Shows: Role name, Attributes (Superuser, Create DB), Member of groups
```

#### Big Picture (`\l`)
```sql
-- See all databases and their properties
\l  -- Basic info
\l+ -- Include sizes and encodings

-- Useful to verify you're in Dev vs Prod
\c production_db  -- Connect to production
```

### System Information

| Command | Description | Example |
|---------|-------------|---------|
| `\! [command]` | Run shell command from psql | `\! clear` or `\! ls -la` |
| `\conninfo` | Show current connection info | See user, database, host, port |

#### Multitasker (`\!`)
```sql
-- Clear screen without leaving psql
\! clear

-- Check disk space
\! df -h

-- List files in current directory
\! ls -la
```

---

## Part 2: SQL Productivity

### Data Manipulation

> **⚡ Productivity Boost:** Write smarter, not harder with these SQL shortcuts.

#### RETURNING (Get Data Back)
```sql
-- Instead of INSERT + SELECT, get the ID immediately
INSERT INTO users (name, email) 
VALUES ('Neo', 'neo@matrix.com') 
RETURNING id, created_at;
-- Returns: id=123, created_at="2024-01-15 10:30:00"
```

#### DISTINCT ON (First Row Trick)
```sql
-- Get most recent order for each user without complex GROUP BY
SELECT DISTINCT ON (user_id) 
    user_id, total, created_at, order_status
FROM orders
ORDER BY user_id, created_at DESC;

-- Perfect for "latest status" queries
```

#### COALESCE (Handle NULLs)
```sql
-- Clean up data for UI presentation
SELECT 
    name, 
    COALESCE(phone, 'No Phone Provided') as contact_info,
    COALESCE(address, 'Address not provided') as address
FROM users;
```

### Advanced Query Techniques

#### generate_series (Fake Data Generator)
```sql
-- Generate test data without complex loops
INSERT INTO test_logs (log_date, user_id, action)
SELECT 
    NOW() - (random() * interval '30 days'),
    (random() * 100)::int + 1,
    'page_view'
FROM generate_series(1, 10000);

-- Creates 10,000 random log entries
```

#### ILIKE (Case Insensitive Search)
```sql
-- Better than LOWER(col) = LOWER(val) - preserves index usage
SELECT * FROM products 
WHERE name ILIKE 'iphone%';
-- Matches: iPhone, iphone, IPHONE, Iphone 15

-- Case insensitive pattern matching
SELECT * FROM users 
WHERE email ILIKE '%@gmail.com';
```

#### FILTER (Cleaner Aggregations)
```sql
-- Modern alternative to CASE WHEN inside aggregates
SELECT 
    count(*) FILTER (WHERE status = 'active') as active_users,
    count(*) FILTER (WHERE status = 'pending') as pending_users,
    count(*) FILTER (WHERE status = 'banned') as banned_users,
    count(*) as total_users
FROM users;

-- Much cleaner than multiple CASE statements
```

### Data Type Conversions

#### ::type (Casting Shortcut)
```sql
-- Faster than CAST(column AS TYPE)
SELECT 
    '2025-01-01'::date as formatted_date,
    '123.45'::numeric as decimal_value,
    'true'::boolean as bool_value,
    '123'::integer as integer_value;

-- Common type conversions
SELECT 
    NOW()::date as today_date,
    NOW()::timestamp as timestamp_value,
    42::text as text_value;
```

### Conditional Logic

#### CASE WHEN (Logic Inside SQL)
```sql
-- Handle complex business logic in the database
SELECT 
    name,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'VIP Customer'
        WHEN total_spent > 100 THEN 'Regular Customer' 
        WHEN total_spent > 0 THEN 'New Customer'
        ELSE 'Prospect'
    END as customer_segment,
    CASE 
        WHEN created_at < NOW() - INTERVAL '1 year' THEN 'Long-term'
        ELSE 'Recent'
    END as tenure
FROM customers;

-- Nested CASE example
SELECT 
    order_total,
    CASE 
        WHEN order_total > 1000 THEN 
            CASE 
                WHEN customer_type = 'business' THEN 'High Value Business'
                ELSE 'High Value Individual'
            END
        WHEN order_total > 100 THEN 'Standard'
        ELSE 'Small'
    END as order_priority
FROM orders;
```

#### NULLIF (Division Saver)
```sql
-- Prevent division by zero errors
SELECT 
    total_sales,
    total_orders,
    CASE 
        WHEN total_orders > 0 THEN total_sales / total_orders 
        ELSE 0 
    END as average_order_value,
    -- Cleaner approach using NULLIF
    total_sales / NULLIF(total_orders, 0) as safe_average
FROM sales_stats 
WHERE total_orders IS NOT NULL;

-- If total_orders is 0, result becomes NULL instead of error
```

#### ORDER BY NULLS LAST (Better UX)
```sql
-- Fix the NULL sorting issue for better user experience
SELECT 
    task_name,
    completed_at,
    CASE 
        WHEN completed_at IS NULL THEN 'pending'
        ELSE 'completed'
    END as status
FROM tasks 
ORDER BY 
    completed_at DESC NULLS LAST;  -- Pending tasks at bottom

-- Alternative: Put completed tasks first
ORDER BY completed_at DESC NULLS FIRST;
```

---

## Part 3: JSON & NoSQL Features

> **🚀 NoSQL Power:** PostgreSQL does everything MongoDB can do, with ACID compliance.

### JSON Data Extraction

| Operator | Description | Example |
|----------|-------------|---------|
| `->>` | Extract JSON field as text | `data->>'name'` |
| `->` | Extract JSON field as JSON | `data->'settings'` |
| `jsonb_pretty` | Format JSON for readability | `jsonb_pretty(data)` |

#### Text Extraction (`->>`)
```sql
-- Extract JSON fields as text
SELECT 
    data->>'name' as user_name,
    data->>'email' as user_email,
    (data->>'age')::int as user_age
FROM users 
WHERE data ? 'name';

-- data column: {"name": "John", "email": "john@example.com", "age": 30}
-- Result: 'John', 'john@example.com', 30
```

#### Pretty JSON Output
```sql
-- Make JSON readable in terminal
SELECT jsonb_pretty(user_settings) as formatted_settings
FROM user_configs 
WHERE user_id = 123;

-- Output:
-- {
--     "theme": "dark",
--     "notifications": true,
--     "language": "en"
-- }
```

### JSON Operations

#### Contains Operator (`@>`)
```sql
-- Fast JSON queries with GIN indexes
SELECT * FROM books 
WHERE attributes @> '{"genre": "sci-fi", "published": true}';

-- Check if JSON contains specific structure
SELECT * FROM products 
WHERE metadata @> '{"category": "electronics", "in_stock": true}';

-- Create index for fast JSON queries
CREATE INDEX idx_books_attributes ON books USING GIN (attributes);
```

#### to_jsonb (Instant API Response)
```sql
-- Convert entire row to JSON for API responses
SELECT to_jsonb(u) as user_json
FROM users u 
WHERE u.id = 123;

-- Result: {"id": 123, "name": "John", "email": "john@example.com", ...}

-- Custom JSON structure
SELECT jsonb_build_object(
    'user_id', id,
    'full_name', name,
    'contact', jsonb_build_object('email', email, 'phone', phone)
) as api_response
FROM users;
```

#### jsonb_agg (N+1 Query Killer)
```sql
-- Aggregate related data into JSON arrays
SELECT 
    p.id as post_id,
    p.title,
    jsonb_agg(
        jsonb_build_object(
            'comment_id', c.id,
            'text', c.comment_text,
            'author', c.author_name,
            'created_at', c.created_at
        )
    ) as comments
FROM posts p
LEFT JOIN comments c ON p.id = c.post_id
GROUP BY p.id, p.title;

-- Result: {"post_id": 1, "title": "Great Post", "comments": [...]}
```

#### jsonb_set (Surgical Updates)
```sql
-- Update specific JSON keys without overwriting entire column
UPDATE user_configs 
SET settings = jsonb_set(
    settings, 
    '{theme}', 
    '"dark"'
)
WHERE user_id = 123;

-- Update nested keys
UPDATE user_configs 
SET settings = jsonb_set(
    settings,
    '{notifications,email}',
    'false'
);

-- Set multiple values
UPDATE user_configs 
SET settings = settings || '{"theme": "light", "language": "es"}'::jsonb;
```

### Array Manipulation

| Function | Description | Example |
|----------|-------------|---------|
| `unnest` | Explode array to rows | `SELECT unnest(tags) FROM posts` |
| `array_agg` | Aggregate to array | `array_agg(column)` |
| `array_length` | Get array size | `array_length(tags, 1)` |
| `string_to_array` | Convert string to array | `string_to_array('a,b,c', ',')` |

#### unnest (Explode Arrays)
```sql
-- Convert array to rows for joining
SELECT 
    p.id,
    p.title,
    unnest(p.tags) as tag
FROM posts p;

-- Result: 1 row per tag per post
-- If post has 3 tags, returns 3 rows

-- Join with tag table
SELECT 
    p.title,
    t.tag_name,
    t.category
FROM posts p
JOIN unnest(p.tags) WITH ORDINALITY AS t(tag_name, tag_pos) ON true
JOIN tags t ON t.name = t.tag_name;
```

#### array_agg (Simple Lists)
```sql
-- Aggregate to PostgreSQL arrays (more efficient than strings)
SELECT 
    user_id,
    array_agg(ip_address ORDER BY login_time DESC) as recent_logins,
    array_agg(DISTINCT browser_type) as browsers_used
FROM logins 
GROUP BY user_id;

-- Result: {192.168.1.1, 10.0.0.1}, {'Chrome', 'Firefox'}

-- Nested array aggregation
SELECT 
    department,
    array_agg(
        jsonb_build_object(
            'name', employee_name,
            'skills', array_agg(skill)
        )
    ) as team
FROM employees
GROUP BY department;
```

#### Array Functions
```sql
-- Convert comma-separated strings to arrays
SELECT string_to_array('apple,banana,orange', ',') as fruits;
-- Result: {apple, banana, orange}

-- Array length and bounds
SELECT 
    array_length(tags, 1) as tag_count,
    array_lower(tags, 1) as first_index,
    array_upper(tags, 1) as last_index
FROM posts 
WHERE id = 123;

-- Array concatenation
SELECT 
    tags || 'new_tag'::text as updated_tags
FROM posts 
WHERE id = 123;

-- Array membership
SELECT * FROM posts 
WHERE 'python' = ANY(tags);

-- Array overlap
SELECT * FROM posts 
WHERE tags && '{"python", "tutorial"}';
```

### NoSQL-style Queries

#### JSONB Indexes for Performance
```sql
-- Create GIN indexes for fast JSON queries
CREATE INDEX idx_user_data_gin ON users USING GIN (data);
CREATE INDEX idx_books_attrs_gin ON books USING GIN (attributes);

-- Query JSON data efficiently
SELECT * FROM users 
WHERE data @> '{"role": "admin", "active": true}';

-- Partial JSON indexes
CREATE INDEX idx_active_users ON users USING GIN ((data->'active'));
```

---

## Part 4: Date & Time Operations

### Date Calculations

| Function | Description | Example |
|----------|-------------|---------|
| `age()` | Human-readable duration | `age(birth_date)` |
| `date_trunc` | Round to precision | `date_trunc('month', created_at)` |
| `EXTRACT` | Get date parts | `EXTRACT(HOUR FROM timestamp)` |
| `INTERVAL` | Time arithmetic | `NOW() + INTERVAL '1 week'` |

#### Human Readable Duration (`age()`)
```sql
-- Calculate age in human-readable format
SELECT 
    name,
    birth_date,
    age(birth_date) as age_human_readable,
    EXTRACT(YEAR FROM age(birth_date)) as age_years
FROM employees;

-- Result: "25 years 4 mons 12 days"

-- Age between two dates
SELECT 
    order_date,
    shipped_date,
    age(shipped_date, order_date) as fulfillment_time
FROM orders
WHERE shipped_date IS NOT NULL;
```

#### Interval Math
```sql
-- Add/subtract time using plain English
SELECT 
    NOW() as current_time,
    NOW() + INTERVAL '1 week 2 days' as next_week,
    NOW() - INTERVAL '30 days' as one_month_ago,
    NOW() + INTERVAL '2 hours 30 minutes' as later_today;

-- Common intervals
SELECT 
    created_at,
    created_at + INTERVAL '1 day' as next_day,
    created_at + INTERVAL '1 month' as next_month,
    created_at + INTERVAL '1 year' as next_year
FROM orders;

-- Business days (custom calculation needed)
SELECT 
    created_at,
    created_at + INTERVAL '1 week' as one_week_later
FROM orders;
```

### Time-based Analytics

#### date_trunc (Reporting)
```sql
-- Group data by time periods
SELECT 
    date_trunc('month', created_at) as month,
    date_trunc('week', created_at) as week,
    date_trunc('day', created_at) as day,
    date_trunc('hour', created_at) as hour,
    count(*) as order_count,
    sum(total) as revenue
FROM orders 
GROUP BY 1, 2, 3, 4
ORDER BY month DESC;

-- Popular truncations:
-- 'microsecond', 'millisecond', 'second'
-- 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year'
-- 'decade', 'century', 'millennium'
```

#### EXTRACT (Precision Analytics)
```sql
-- Extract specific date parts for analytics
SELECT 
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    EXTRACT(DOW FROM created_at) as day_of_week,  -- 0=Sunday, 6=Saturday
    EXTRACT(ISODOW FROM created_at) as iso_day,   -- 1=Monday, 7=Sunday
    EXTRACT(DOY FROM created_at) as day_of_year,
    EXTRACT(WEEK FROM created_at) as week_number,
    EXTRACT(QUARTER FROM created_at) as quarter,
    EXTRACT(YEAR FROM created_at) as year,
    EXTRACT(MONTH FROM created_at) as month
FROM page_visits
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';

-- Traffic analysis by hour
SELECT 
    EXTRACT(HOUR FROM created_at) as hour,
    count(*) as page_views
FROM page_visits
GROUP BY 1
ORDER BY hour;

-- Weekend vs weekday analysis
SELECT 
    CASE 
        WHEN EXTRACT(ISODOW FROM created_at) IN (6, 7) THEN 'weekend'
        ELSE 'weekday'
    END as day_type,
    count(*) as visits,
    avg(session_duration) as avg_duration
FROM analytics
GROUP BY 1;
```

#### TO_CHAR (Report Formatting)
```sql
-- Format dates for reports and UI
SELECT 
    TO_CHAR(NOW(), 'DD Mon YYYY HH24:MI') as formatted_datetime,
    TO_CHAR(created_at, 'YYYY-MM-DD') as date_only,
    TO_CHAR(created_at, 'HH24:MI:SS') as time_only,
    TO_CHAR(created_at, 'Mon DD, YYYY') as human_date,
    TO_CHAR(created_at, 'Day, DD Month YYYY') as full_formatted;

-- Common format patterns:
-- YYYY = 4-digit year
-- MM = 2-digit month  
-- DD = 2-digit day
-- HH24 = 24-hour format
-- MI = minutes
-- SS = seconds
-- Mon = abbreviated month
-- Month = full month name
-- Day = full day name

-- Number formatting
SELECT 
    TO_CHAR(1234.56, '999,999.00') as formatted_number,
    TO_CHAR(0.123, '0.00%') as percentage,
    TO_CHAR(42, '099') as zero_padded;
```

### Timezone Handling

#### Timezone Conversions
```sql
-- Convert between timezones
SELECT 
    NOW() as current_utc,
    NOW() AT TIME ZONE 'America/New_York' as new_york_time,
    NOW() AT TIME ZONE 'Europe/London' as london_time,
    NOW() AT TIME ZONE 'Asia/Tokyo' as tokyo_time;

-- Store timezone-aware timestamps
CREATE TABLE events (
    id serial PRIMARY KEY,
    event_name text,
    event_time timestamptz,  -- Always use timestamptz
    event_timezone text
);

-- Convert stored timestamps
SELECT 
    event_name,
    event_time,
    event_time AT TIME ZONE 'UTC' AT TIME ZONE 'America/Los_Angeles' as local_time
FROM events;
```

---

## Part 5: Administration & Maintenance

### Monitoring & Performance

| View/Function | Description | Use Case |
|---------------|-------------|----------|
| `pg_stat_activity` | Current connections and queries | See who's connected and what they're running |
| `pg_size_pretty` | Human-readable sizes | Check database sizes in MB/GB |
| `pg_stat_statements` | Query statistics | Find slow queries (requires extension) |

#### The Control Tower (`pg_stat_activity`)
```sql
-- See who's connected and what they're doing
SELECT 
    pid,
    usename as username,
    application_name,
    client_addr,
    state,
    query_start,
    CASE 
        WHEN state = 'active' THEN query
        ELSE NULL 
    END as current_query,
    EXTRACT(EPOCH FROM (NOW() - query_start)) as query_duration_seconds
FROM pg_stat_activity 
WHERE state IN ('active', 'idle in transaction')
ORDER BY query_start;

-- Find long-running queries
SELECT 
    pid,
    usename,
    query_start,
    EXTRACT(EPOCH FROM (NOW() - query_start)) as duration_seconds,
    query
FROM pg_stat_activity 
WHERE state = 'active' 
  AND query_start < NOW() - INTERVAL '5 minutes'
ORDER BY query_start;

-- Kill a specific query
SELECT pg_cancel_backend(1234);  -- Polite termination
```

#### Database Sizes
```sql
-- Get human-readable database sizes
SELECT 
    pg_database.datname as database_name,
    pg_size_pretty(pg_database_size(pg_database.datname)) as size,
    pg_database_size(pg_database.datname) as size_bytes
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;

-- Table sizes in current database
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### Slow Query Detection (`pg_stat_statements`)
```sql
-- First, enable the extension (run once per database)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find top 5 queries by total execution time
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    min_exec_time,
    max_exec_time,
    (total_exec_time / calls) as avg_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements 
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC 
LIMIT 5;

-- Find most frequently called queries
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows,
    100.0 * calls / sum(calls) OVER () as percent_of_calls
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY calls DESC 
LIMIT 5;

-- Find queries with highest average time
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows,
    mean_exec_time * calls as total_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Reset statistics (careful!)
-- SELECT pg_stat_statements_reset();
```

### Query Management

#### The Polite Kill (`pg_cancel_backend`)
```sql
-- Cancel a specific query without killing the connection
SELECT pg_cancel_backend(12345);  -- Replace with actual PID

-- Returns true if successful
```

#### The Hard Kill (`pg_terminate_backend`)
```sql
-- Forcefully terminate a connection and all its queries
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE pid = 12345 AND usename = 'problematic_user';

-- Use when pg_cancel_backend doesn't work
-- Kills the entire connection, not just one query
```

### Database Maintenance

#### The Bloat Cleaner (`VACUUM`)
```sql
-- Manual VACUUM with verbose output
VACUUM (VERBOSE, ANALYZE) users;

-- VACUUM specific table
VACUUM (VERBOSE, ANALYZE, FULL) users;  -- Full vacuum (locks table)

-- VACUUM entire database
VACUUM (VERBOSE, ANALYZE);

-- Check table bloat
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    CASE 
        WHEN n_live_tup > 0 
        THEN round(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 2)
        ELSE 0 
    END as bloat_percent
FROM pg_stat_user_tables
ORDER BY bloat_percent DESC;

-- Auto-vacuum settings
SELECT 
    relname as table_name,
    reloptions as auto_vacuum_settings
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND reloptions IS NOT NULL;
```

### Index Management

#### Production-Safe Indexing
```sql
-- Create index without locking table (slower but safe)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- Drop index without locking
DROP INDEX CONCURRENTLY IF EXISTS idx_old_index;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexname NOT LIKE '%pkey%';

-- Index size analysis
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
JOIN pg_index ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
WHERE pg_index.indisprimary = false
ORDER BY pg_relation_size(indexrelid) DESC;

-- Composite indexes and their usage
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_get_indexdef(indexrelid) as index_definition,
    idx_scan
FROM pg_stat_user_indexes
WHERE indexname NOT LIKE '%pkey%'
  AND pg_get_indexdef(indexrelid) ~ '\('  -- Composite indexes
ORDER BY idx_scan DESC;
```

#### Primary vs Replica Detection
```sql
-- Check if running on primary or replica
SELECT 
    pg_is_in_recovery() as is_replica,
    CASE 
        WHEN pg_is_in_recovery() THEN 'Read-Only Replica'
        ELSE 'Read-Write Primary'
    END as server_role;

-- Read queries on replica, write on primary
DO $$
BEGIN
    IF pg_is_in_replication() THEN
        RAISE NOTICE 'Running on replica - queries only';
    ELSE
        RAISE NOTICE 'Running on primary - full access';
    END IF;
END $$;
```

---

## Part 6: Advanced Engineering

### Complex Query Patterns

#### WITH (CTEs) - Make Complex Queries Readable
```sql
-- Break complex queries into readable steps
WITH regional_sales AS (
    SELECT 
        region,
        SUM(amount) as total_sales,
        COUNT(*) as order_count,
        AVG(amount) as avg_order_value
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY region
),
top_regions AS (
    SELECT region, total_sales
    FROM regional_sales
    WHERE total_sales > 10000
    ORDER BY total_sales DESC
    LIMIT 5
)
SELECT 
    r.*,
    t.total_sales as top_region_sales,
    ROUND(r.total_sales / t.total_sales * 100, 2) as percentage_of_top
FROM regional_sales r
JOIN top_regions t USING (region)
ORDER BY r.total_sales DESC;

-- Recursive CTE for hierarchical data
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: employees with no manager
    SELECT 
        id, 
        name, 
        manager_id, 
        1 as level,
        name as path
    FROM employees 
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees who report to someone in hierarchy
    SELECT 
        e.id,
        e.name,
        e.manager_id,
        eh.level + 1,
        eh.path || ' > ' || e.name
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.id
    WHERE eh.level < 10  -- Prevent infinite loops
)
SELECT * FROM employee_hierarchy ORDER BY path;
```

#### LATERAL JOIN - For-Loop in SQL
```sql
-- Run subquery for each row of main table
SELECT 
    u.id,
    u.name,
    u.email,
    last_login.login_time,
    last_login.ip_address,
    last_login.user_agent
FROM users u
LEFT JOIN LATERAL (
    SELECT 
        login_time,
        ip_address,
        user_agent
    FROM logins 
    WHERE user_id = u.id 
    ORDER BY login_time DESC 
    LIMIT 1
) last_login ON true;

-- LATERAL with more complex calculations
SELECT 
    u.id,
    u.name,
    stats.total_orders,
    stats.total_spent,
    stats.avg_order_value,
    stats.last_order_date
FROM users u
LEFT JOIN LATERAL (
    SELECT 
        COUNT(*) as total_orders,
        SUM(total) as total_spent,
        AVG(total) as avg_order_value,
        MAX(order_date) as last_order_date
    FROM orders 
    WHERE user_id = u.id
      AND status = 'completed'
) stats ON true
WHERE u.created_at >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY stats.total_spent DESC NULLS LAST;
```

### Performance Optimization

#### EXPLAIN (ANALYZE, BUFFERS) - The Truth Serum
```sql
-- Actually run query and show real performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    o.id,
    o.total,
    u.name as customer_name,
    p.product_name
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
  AND o.total > 100
ORDER BY o.created_at DESC
LIMIT 100;

-- Look for these performance indicators:
-- ✅ "Index Scan" (good) vs "Seq Scan" (bad)
-- ✅ Lower "actual time" 
-- ✅ "Rows" estimate close to "actual rows"
-- ✅ "Shared hit" (from cache) vs "Shared read" (from disk)

-- Analyze with different query plans
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS OFF) 
SELECT * FROM users WHERE email = 'john@example.com';

-- Check if indexes are being used
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as times_used,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

#### Query Performance Analysis
```sql
-- Compare query plans before/after optimization
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM orders 
WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
  AND status = 'completed';

-- With proper index
CREATE INDEX CONCURRENTLY idx_orders_created_at_status 
ON orders(created_at, status);

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM orders 
WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
  AND status = 'completed';

-- Check execution statistics
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    stddev_exec_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE query LIKE '%orders%'
ORDER BY total_exec_time DESC;
```

### Data Streaming

#### COPY TO STDOUT - The Firehose
```sql
-- Stream massive datasets efficiently
COPY (
    SELECT 
        o.id,
        o.created_at,
        u.email as customer_email,
        p.name as product_name,
        oi.quantity,
        oi.unit_price,
        oi.quantity * oi.unit_price as line_total
    FROM orders o
    JOIN users u ON o.user_id = u.id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.created_at >= CURRENT_DATE - INTERVAL '1 year'
    ORDER BY o.created_at DESC
) TO STDOUT WITH CSV HEADER;

-- Stream to program for processing
COPY (
    SELECT * FROM massive_logs 
    WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
) TO PROGRAM 'gzip > /backup/logs_$(date +%Y%m%d).csv.gz';
```

### Real-time Features

#### LISTEN/NOTIFY - Built-in Pub/Sub
```sql
-- Session 1: Set up listener
LISTEN task_completed;

-- Session 2: Publish notification
NOTIFY task_completed, 'Task ID 55 is done with status success';

-- Session 3: Notify with JSON payload
NOTIFY order_events, '{"type": "created", "order_id": 123, "total": 99.99}';

-- Application code example (Python pseudocode):
-- cursor.execute("LISTEN new_orders")
-- for notification in cursor.notifies:
--     data = json.loads(notification.payload)
--     process_new_order(data['order_id'])

-- Practical example: Real-time analytics
-- Session 1: Monitor order updates
LISTEN order_updates;

-- Session 2: Publish order events
INSERT INTO orders (user_id, total) VALUES (123, 99.99);
NOTIFY order_updates, json_build_object(
    'event', 'order_created',
    'order_id', currval('orders_id_seq'),
    'user_id', 123,
    'total', 99.99
)::text;

-- Batch notifications
DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN SELECT * FROM pending_notifications WHERE processed = false LOOP
        PERFORM pg_notify('batch_notification', rec.payload);
        UPDATE pending_notifications SET processed = true WHERE id = rec.id;
    END LOOP;
END $$;
```

#### Advanced NOTIFY Patterns
```sql
-- Channel naming convention
NOTIFY 'analytics:orders', '{"metric": "revenue", "value": 1234.56}';
NOTIFY 'alerts:system', '{"level": "warning", "message": "High CPU usage"}';

-- Notification with metadata
NOTIFY 'user_activity', json_build_object(
    'user_id', NEW.user_id,
    'action', 'profile_updated',
    'timestamp', NOW(),
    'session_id', current_setting('app.session_id', true)
)::text;

-- Automatic notifications with triggers
CREATE OR REPLACE FUNCTION notify_order_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM pg_notify('orders', json_build_object(
            'event', 'created',
            'order_id', NEW.id,
            'data', row_to_json(NEW)
        )::text);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM pg_notify('orders', json_build_object(
            'event', 'updated',
            'order_id', NEW.id,
            'data', row_to_json(NEW)
        )::text);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_changes_notify
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_changes();
```

---

## 🎯 Golden Rules & Pro Tips

### The Golden Rule
> **Master the basics first, then learn advanced features. PostgreSQL rewards those who understand its fundamentals.**

### Performance Tips

1. **Always use `EXPLAIN ANALYZE`** to understand query performance
2. **Create indexes strategically** - measure before and after
3. **Use connection pooling** for high-traffic applications
4. **Monitor with `pg_stat_statements`** to find slow queries
5. **Regular VACUUM and ANALYZE** to maintain performance

### Security Best Practices

1. **Use parameterized queries** to prevent SQL injection
2. **Enable SSL/TLS** for all connections
3. **Implement row-level security** for multi-tenant apps
4. **Regular backups** with `pg_dump` or continuous archiving
5. **Keep PostgreSQL updated** for security patches

### Development Workflow

1. **Use transactions** for data consistency
2. **Implement proper error handling** with `BEGIN/EXCEPTION`
3. **Use CTEs for complex queries** instead of nested subqueries
4. **Leverage JSON features** for flexible schema design
5. **Use `RETURNING`** to avoid extra SELECT queries

### Quick Reference Commands

```bash
# Connection and basic info
psql -h hostname -U username -d database
\conninfo              # Show connection info
\l                     # List databases
\c database_name       # Connect to database

# Query optimization
\timing                # Enable timing
EXPLAIN ANALYZE        # Profile query
\watch 2               # Auto-refresh query results

# Performance monitoring
SELECT * FROM pg_stat_activity;
SELECT pg_size_pretty(pg_database_size('mydb'));

# Maintenance
VACUUM (ANALYZE) table_name;
REINDEX DATABASE database_name;
```

---

## 📖 Final Thoughts

PostgreSQL is more than just a database — it's a powerful platform that can handle:

- **Traditional relational data** with ACID compliance
- **JSON/NoSQL workloads** with flexible schemas  
- **Real-time applications** with built-in pub/sub
- **Analytics and reporting** with advanced SQL features
- **High availability** with streaming replication

**Master the basics** to handle everyday database tasks efficiently.  
**Master the advanced features** to build scalable, performant applications.

**This cheatsheet covers 50+ techniques** — you don't need to memorize them all. Bookmark it for reference when you encounter specific challenges!

**Happy querying!** 🚀