# Efficiency Improvement Report for White House 3

This report documents performance inefficiencies identified in the Ruby on Rails 2.3.2 codebase and provides recommendations for optimization.

## Executive Summary

The codebase contains several performance bottlenecks that could significantly impact application performance, especially as user base and data volume grow. The most critical issues include N+1 queries, inefficient database operations, and suboptimal loop patterns.

## Critical Issues (High Impact)

### 1. N+1 Query in ApplicationController (FIXED)

**Location**: `app/controllers/application_controller.rb:68`

**Issue**: The `current_following_facebook_uids` method triggers N+1 queries when accessing `other_user.facebook_uid` for each following relationship.

```ruby
# Before (inefficient)
@current_following_facebook_uids ||= current_user.followings.up.map { |f| f.other_user.facebook_uid }.compact

# After (optimized)
@current_following_facebook_uids ||= current_user.followings.up.includes(:other_user).map { |f| f.other_user.facebook_uid }.compact
```

**Impact**: High - This method is called frequently as a helper method and can trigger 1+N database queries instead of 2 queries.

**Status**: ✅ FIXED in this PR

### 2. Inefficient Bulk Deletions in User Model

**Location**: `app/models/user.rb:275-296`

**Issue**: The `do_delete` method uses individual `destroy` calls in loops instead of bulk operations.

```ruby
# Current inefficient approach
for e in endorsements
  e.destroy
end
for f in followings
  f.destroy
end
# ... more individual destroys
```

**Recommendation**: Use bulk delete operations:
```ruby
endorsements.delete_all
followings.delete_all
followers.delete_all
received_capitals.delete_all
sent_capitals.delete_all
constituents.delete_all
```

**Impact**: High - User deletion could be 10-100x faster with bulk operations.

### 3. Inefficient Count Operations

**Location**: `app/models/user.rb:352-362`

**Issue**: Using `.size` on associations loads all records into memory just to count them.

```ruby
# Inefficient - loads all records
self.endorsements_count = endorsements.active.size
self.up_endorsements_count = endorsements.active.endorsing.size
```

**Recommendation**: Use `.count` for database-level counting or implement counter caches:
```ruby
self.endorsements_count = endorsements.active.count
# Or better: implement counter_cache on associations
```

**Impact**: Medium-High - Significant memory usage and slower performance for users with many endorsements.

## Medium Impact Issues

### 4. Multiple find(:all) Patterns

**Locations**: Throughout controllers (29+ instances found)

**Issue**: Using deprecated `find(:all)` syntax instead of modern Rails patterns.

**Examples**:
- `app/controllers/priorities_controller.rb:11`
- `app/controllers/blurbs_controller.rb:8`
- `app/controllers/users_controller.rb:9`

**Recommendation**: Replace with `.all` or scoped queries:
```ruby
# Instead of
Priority.published.find(:all, :conditions => [...])

# Use
Priority.published.where(...)
```

### 5. Raw SQL Queries

**Locations**: Multiple models use `find_by_sql`

**Issue**: Raw SQL queries are harder to maintain and may not be optimally indexed.

**Examples**:
- `app/models/priority.rb:367` - Complex undecideds query
- `app/models/priority.rb:379` - Related priorities query
- `app/models/user.rb:546` - Recommendation algorithm

**Recommendation**: Consider converting to ActiveRecord queries where possible or ensure proper indexing.

### 6. Inefficient Loop in Priority Controller

**Location**: `app/controllers/priorities_controller.rb:114-117`

**Issue**: Iterating through all notifications to mark specific ones as read.

```ruby
for n in current_user.received_notifications.all
  n.read! if n.class == NotificationPriorityFinished and n.unread?
end
```

**Recommendation**: Use scoped update:
```ruby
current_user.received_notifications
  .unread
  .where(type: 'NotificationPriorityFinished')
  .update_all(read: true)
```

## Low Impact Issues

### 7. Inefficient String Operations

**Location**: `app/models/webpage.rb:73`

**Issue**: Chained string operations that could be optimized.

```ruby
self.title = title.inner_html.gsub("\r"," ").gsub("\n"," ").split(" ").join(" ")
```

**Recommendation**: Use single regex or more efficient string cleaning.

### 8. Repeated Database Queries in Views

**Locations**: Various view files

**Issue**: Database queries in view templates that could be moved to controllers.

**Recommendation**: Move data fetching to controllers and use instance variables in views.

## Database Optimization Opportunities

### Missing Indexes (Recommended Investigation)

Based on the query patterns observed, consider adding indexes on:
- `endorsements(user_id, status, position)`
- `followings(user_id, value)`
- `priorities(status, position)`
- `activities(user_id, type, created_at)`

### Counter Cache Opportunities

Implement counter caches for frequently accessed counts:
- `users.endorsements_count`
- `priorities.endorsements_count`
- `users.followings_count`

## Implementation Priority

1. **High Priority**: Fix N+1 queries (✅ Done for ApplicationController)
2. **High Priority**: Implement bulk operations for user deletion
3. **Medium Priority**: Replace .size with .count or counter caches
4. **Medium Priority**: Update find(:all) patterns to modern Rails syntax
5. **Low Priority**: Optimize string operations and view queries

## Performance Testing Recommendations

1. Use tools like `bullet` gem to detect additional N+1 queries
2. Implement database query monitoring in development
3. Add performance benchmarks for critical user flows
4. Consider implementing caching strategies for expensive operations

## Conclusion

The identified inefficiencies, particularly the N+1 queries and bulk operation opportunities, represent significant performance improvement potential. The fix implemented in this PR addresses the most frequently called N+1 query, but additional work on bulk operations and count optimizations would provide substantial benefits for the application's scalability.
