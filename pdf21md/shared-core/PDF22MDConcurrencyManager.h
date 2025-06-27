//
//  PDF21MDConcurrencyManager.h
//  pdf22md - Shared Components
//
//  Standardized concurrency patterns and queue management
//  for consistent GCD usage across all implementations.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Standardized concurrency manager providing unified GCD patterns
 * and queue management across all PDF21MD implementations.
 */
@interface PDF21MDConcurrencyManager : NSObject

#pragma mark - Shared Queue Access

/**
 * Shared concurrent queue for CPU-intensive operations.
 * Optimized for parallel processing tasks like page conversion.
 */
+ (dispatch_queue_t)sharedConcurrentQueue;

/**
 * Shared serial queue for file system operations.
 * Ensures thread-safe file access and prevents race conditions.
 */
+ (dispatch_queue_t)sharedFileAccessQueue;

/**
 * Shared serial queue for converter operations.
 * Manages conversion workflow and state consistency.
 */
+ (dispatch_queue_t)sharedConverterQueue;

/**
 * Shared global queue for background processing.
 * Standard system queue for general background tasks.
 */
+ (dispatch_queue_t)sharedBackgroundQueue;

#pragma mark - Concurrency Utilities

/**
 * Creates a dispatch group for coordinating multiple operations.
 */
+ (dispatch_group_t)createProcessingGroup;

/**
 * Creates a semaphore with specified concurrent operation limit.
 */
+ (dispatch_semaphore_t)createConcurrencySemaphoreWithLimit:(NSInteger)limit;

/**
 * Executes operation on concurrent queue with completion on main queue.
 */
+ (void)performConcurrentOperation:(void(^)(void))operation
                        completion:(nullable void(^)(void))completion;

/**
 * Executes operation on serial file access queue.
 */
+ (void)performFileOperation:(void(^)(void))operation
                  completion:(nullable void(^)(void))completion;

/**
 * Executes operation on converter queue.
 */
+ (void)performConverterOperation:(void(^)(void))operation
                       completion:(nullable void(^)(void))completion;

#pragma mark - Parallel Processing Patterns

/**
 * Processes array items in parallel with concurrency limit.
 * Uses dispatch groups and semaphores for optimal performance.
 */
+ (void)processItemsInParallel:(NSArray *)items
               concurrencyLimit:(NSInteger)limit
                      processor:(void(^)(id item, NSInteger index))processor
                     completion:(void(^)(void))completion;

/**
 * Processes array items in parallel with progress reporting.
 */
+ (void)processItemsInParallel:(NSArray *)items
               concurrencyLimit:(NSInteger)limit
                      processor:(void(^)(id item, NSInteger index))processor
                progressHandler:(nullable void(^)(NSInteger completedCount, NSInteger totalCount))progressHandler
                     completion:(void(^)(void))completion;

#pragma mark - Synchronization Utilities

/**
 * Waits for dispatch group with timeout.
 * Returns YES if completed within timeout, NO if timed out.
 */
+ (BOOL)waitForGroup:(dispatch_group_t)group
             timeout:(NSTimeInterval)timeoutSeconds;

/**
 * Waits for semaphore with timeout.
 * Returns YES if acquired within timeout, NO if timed out.
 */
+ (BOOL)waitForSemaphore:(dispatch_semaphore_t)semaphore
                 timeout:(NSTimeInterval)timeoutSeconds;

/**
 * Executes block on main queue, handling both main and background thread calls.
 */
+ (void)executeOnMainQueue:(void(^)(void))block;

/**
 * Executes block on main queue synchronously if on background thread,
 * immediately if already on main thread.
 */
+ (void)executeOnMainQueueSync:(void(^)(void))block;

@end

NS_ASSUME_NONNULL_END