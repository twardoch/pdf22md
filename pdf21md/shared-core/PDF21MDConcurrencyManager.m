//
//  PDF21MDConcurrencyManager.m
//  pdf21md - Shared Components
//
//  Standardized concurrency patterns and queue management
//  for consistent GCD usage across all implementations.
//

#import "PDF21MDConcurrencyManager.h"

@implementation PDF21MDConcurrencyManager

#pragma mark - Shared Queue Access

+ (dispatch_queue_t)sharedConcurrentQueue {
    static dispatch_queue_t sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create("com.twardoch.pdf21md.concurrent", 
                                          DISPATCH_QUEUE_CONCURRENT);
    });
    return sharedQueue;
}

+ (dispatch_queue_t)sharedFileAccessQueue {
    static dispatch_queue_t sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create("com.twardoch.pdf21md.fileaccess", 
                                          DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
}

+ (dispatch_queue_t)sharedConverterQueue {
    static dispatch_queue_t sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create("com.twardoch.pdf21md.converter", 
                                          DISPATCH_QUEUE_SERIAL);
    });
    return sharedQueue;
}

+ (dispatch_queue_t)sharedBackgroundQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

#pragma mark - Concurrency Utilities

+ (dispatch_group_t)createProcessingGroup {
    return dispatch_group_create();
}

+ (dispatch_semaphore_t)createConcurrencySemaphoreWithLimit:(NSInteger)limit {
    return dispatch_semaphore_create(limit);
}

+ (void)performConcurrentOperation:(void(^)(void))operation
                        completion:(nullable void(^)(void))completion {
    dispatch_async([self sharedConcurrentQueue], ^{
        operation();
        
        if (completion) {
            [self executeOnMainQueue:completion];
        }
    });
}

+ (void)performFileOperation:(void(^)(void))operation
                  completion:(nullable void(^)(void))completion {
    dispatch_async([self sharedFileAccessQueue], ^{
        operation();
        
        if (completion) {
            [self executeOnMainQueue:completion];
        }
    });
}

+ (void)performConverterOperation:(void(^)(void))operation
                       completion:(nullable void(^)(void))completion {
    dispatch_async([self sharedConverterQueue], ^{
        operation();
        
        if (completion) {
            [self executeOnMainQueue:completion];
        }
    });
}

#pragma mark - Parallel Processing Patterns

+ (void)processItemsInParallel:(NSArray *)items
               concurrencyLimit:(NSInteger)limit
                      processor:(void(^)(id item, NSInteger index))processor
                     completion:(void(^)(void))completion {
    [self processItemsInParallel:items
                 concurrencyLimit:limit
                        processor:processor
                  progressHandler:nil
                       completion:completion];
}

+ (void)processItemsInParallel:(NSArray *)items
               concurrencyLimit:(NSInteger)limit
                      processor:(void(^)(id item, NSInteger index))processor
                progressHandler:(nullable void(^)(NSInteger completedCount, NSInteger totalCount))progressHandler
                     completion:(void(^)(void))completion {
    if (items.count == 0) {
        [self executeOnMainQueue:completion];
        return;
    }
    
    dispatch_group_t processingGroup = [self createProcessingGroup];
    dispatch_semaphore_t concurrencySemaphore = [self createConcurrencySemaphoreWithLimit:limit];
    
    __block NSInteger completedCount = 0;
    NSInteger totalCount = items.count;
    
    for (NSInteger i = 0; i < totalCount; i++) {
        id item = items[i];
        
        dispatch_group_async(processingGroup, [self sharedBackgroundQueue], ^{
            dispatch_semaphore_wait(concurrencySemaphore, DISPATCH_TIME_FOREVER);
            
            processor(item, i);
            
            // Update progress if handler provided
            if (progressHandler) {
                @synchronized(self) {
                    completedCount++;
                    NSInteger currentCompleted = completedCount;
                    
                    [self executeOnMainQueue:^{
                        progressHandler(currentCompleted, totalCount);
                    }];
                }
            }
            
            dispatch_semaphore_signal(concurrencySemaphore);
        });
    }
    
    dispatch_group_notify(processingGroup, [self sharedBackgroundQueue], ^{
        [self executeOnMainQueue:completion];
    });
}

#pragma mark - Synchronization Utilities

+ (BOOL)waitForGroup:(dispatch_group_t)group
             timeout:(NSTimeInterval)timeoutSeconds {
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 
                                          (int64_t)(timeoutSeconds * NSEC_PER_SEC));
    return dispatch_group_wait(group, timeout) == 0;
}

+ (BOOL)waitForSemaphore:(dispatch_semaphore_t)semaphore
                 timeout:(NSTimeInterval)timeoutSeconds {
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 
                                          (int64_t)(timeoutSeconds * NSEC_PER_SEC));
    return dispatch_semaphore_wait(semaphore, timeout) == 0;
}

+ (void)executeOnMainQueue:(void(^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)executeOnMainQueueSync:(void(^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end