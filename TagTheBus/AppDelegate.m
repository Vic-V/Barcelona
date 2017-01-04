//
//  AppDelegate.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 29/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import "AppDelegate.h"
#import "BarcelonaAPI.h"
#import "Station.h"
#import "StationDbNotifications.h"

@interface AppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^downloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSURLSession *barcelonaapiDownloadSession;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    
    if (self.managedObjectContext && [Station stationsCount:self.managedObjectContext]) {
        NSDictionary *userInfo = @{ StationDbContext: _managedObjectContext};
        [[NSNotificationCenter defaultCenter] postNotificationName:StationDbAvailabilityNotification object:self userInfo:userInfo];
    }
    
    [self startJSONdownload];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - background download

- (NSURL *)barcelonaapiURLfor:(NSString *)transport {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://barcelonaapi.marcpous.com/%@/stations.json", transport]];
}

- (void)startJSONdownload
{
    [self.barcelonaapiDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if (![downloadTasks count]) {
            NSDictionary *tags = [BarcelonaAPI tags];
            for(NSString *transport in tags) {
                /*
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self barcelonaapiURLfor:tags[transport][urlTag]]];
                [request addValue:@"Fri, 07 Oct 2016 13:08:09 GMT" forHTTPHeaderField:@"If-Modified-Since"];
                NSURLSessionDownloadTask *taskB = [self.barcelonaapiDownloadSession downloadTaskWithRequest:request]; 
                 code 200, never 304 */
                
                NSURLSessionDownloadTask *taskB = [self.barcelonaapiDownloadSession downloadTaskWithURL:[self barcelonaapiURLfor:tags[transport][urlTag]]];
            
                taskB.taskDescription = transport;
                [taskB resume];
            }
            __weak AppDelegate *weakSelf = self;
            self.downloadBackgroundURLSessionCompletionHandler = ^ {
                NSDictionary *userInfo = @{ StationDbContext: weakSelf.managedObjectContext};
                [[NSNotificationCenter defaultCenter] postNotificationName:StationDbUpdatedNotification object:weakSelf userInfo:userInfo];
            };

        } else {
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}

- (NSURLSession *)barcelonaapiDownloadSession {
    if (!_barcelonaapiDownloadSession) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"Barcelona Transport"];
            // [urlSessionConfig setHTTPAdditionalHeaders: @{@"If-Modified-Since": @"Fri, 07 Oct 2016 13:24:08 GMT"}];
            _barcelonaapiDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self
                                                              delegateQueue:nil];
        });
    }
    return _barcelonaapiDownloadSession;
}

#pragma mark - background fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
    [self startJSONdownload];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)())completionHandler
{
    self.downloadBackgroundURLSessionCompletionHandler = completionHandler;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
{
    NSHTTPURLResponse *h = (NSHTTPURLResponse *)downloadTask.response;
    NSLog(@"%@", h.URL.path);
    
    if ([BarcelonaAPI tags][downloadTask.taskDescription]) {
        NSManagedObjectContext *context = self.managedObjectContext;
        if (context) {
            // [context performBlock:^{
                [BarcelonaAPI loadStationsFromLocalURL:localFile
                                           intoContext:context
                                          forTransport:downloadTask.taskDescription
                 andThenExecuteBlock:^{
                  [self downloadTasksMightBeComplete];
                  }
                 ];
            // }];
        }
    }
    [self saveContext];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && (session == self.barcelonaapiDownloadSession)) {
        NSLog(@"TagTheBus background download session failed: %@", error.localizedDescription);
        [self downloadTasksMightBeComplete];
    }
}

- (void)downloadTasksMightBeComplete
{
    if (self.downloadBackgroundURLSessionCompletionHandler) {
        [self.barcelonaapiDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@" downloadTasks.count : %lu", (unsigned long)[downloadTasks count]);
            });
            if (downloadTasks.count == 1) {  // last one, any more downloads left?
                void (^completionHandler)() = self.downloadBackgroundURLSessionCompletionHandler;
                self.downloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    completionHandler();
                }
            }
        }];
    }
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "vic.TagTheBus" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TagTheBus" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TagTheBus.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
