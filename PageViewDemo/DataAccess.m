//
//  DataAccess.m
//  twending
//
//  Created by Daniel Simons on 6/3/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Candidate.h"
#import <CoreGraphics/CoreGraphics.h>
#import "DataAccess.h"
#import <Parse/Parse.h>
#import <TwitterKit/TwitterKit.h>
#import "ViewController.h"

@implementation DataAccess

+ (DataAccess *)sharedInstance {
    static DataAccess *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DataAccess alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (NSFetchedResultsController *)fetchedCandidatesController
{
    if (_fetchedCandidatesController != nil) {
        return _fetchedCandidatesController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Candidate" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    //[fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"followersCount" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"friend = YES"]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedCandidatesController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedCandidatesController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedCandidatesController;
    
}

- (NSFetchedResultsController *)fetchedCandidatesController:(NSString *)twitterName {
    NSFetchedResultsController *fetchedCandidatesForTwitterNameController = self.fetchedCandidatesController;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"twittername CONTAINS[cd] %@", twitterName];
    [fetchedCandidatesForTwitterNameController.fetchRequest setPredicate:predicate];
    return fetchedCandidatesForTwitterNameController;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.unofficialcalculators.twending" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"twittertrends" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"twittertrends.sqlite"];
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
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
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

- (Candidate *)saveOrUpdateCandidate:(NSDictionary *)candidateJSON withRetweets:(NSInteger)retweets isFriend:(bool)isFriend {
    NSString *name = candidateJSON[@"name"];
    NSString *twittername = candidateJSON[@"screen_name"];
    NSString *followersCount = candidateJSON[@"followers_count"];
    NSString *listsCount = candidateJSON[@"listed_count"];
    NSString *friendsCount = candidateJSON[@"friends_count"];
    NSString *statusesCount = candidateJSON[@"statuses_count"];
    NSString *retweetCount = [NSString stringWithFormat:@"%li", retweets];
    NSString *accountDescriptor = candidateJSON[@"description"];
    NSString *profileURL = candidateJSON[@"profile_image_url_https"];
    NSString *backgroundImageURL = candidateJSON[@"profile_banner_url"];
    
    NSArray *fetchedCandidatesForTwitterName = [[self fetchedCandidatesController:twittername] fetchedObjects];
    Candidate *managedObject = nil;
    if ([fetchedCandidatesForTwitterName count] > 0) {
        for (Candidate *candidate in fetchedCandidatesForTwitterName) {
            if ([[candidate twittername] isEqualToString:twittername]) {
                managedObject = candidate;
            }
        }
    }
    
    if (managedObject == nil) {
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Candidate" inManagedObjectContext:self.managedObjectContext];
    }
    
    [managedObject setName:name];
    [managedObject setImageURL:profileURL];
    [managedObject setBackgroundImageURL:backgroundImageURL];
    [managedObject setTwittername:twittername];
    [managedObject setAccountDescriptor:accountDescriptor];
    [managedObject setFollowersCount:[NSNumber numberWithInteger:followersCount.integerValue]];
    [managedObject setListsCount:[NSNumber numberWithInteger:listsCount.integerValue]];
    [managedObject setFriendsCount:[NSNumber numberWithInteger:friendsCount.integerValue]];
    [managedObject setTweetsCount:[NSNumber numberWithInteger:statusesCount.integerValue]];
    [managedObject setRetweetsCount:[NSNumber numberWithInteger:retweetCount.integerValue]];
    
    [managedObject setFriend:[NSNumber numberWithBool:isFriend]];
    
    //TODO: Save entry for follower if it's been long enough time
    [self saveContext];
    return managedObject;
}


- (void)logout {
    NSFetchRequest * allcandidates = [[NSFetchRequest alloc] init];
    [allcandidates setEntity:[NSEntityDescription entityForName:@"Candidate" inManagedObjectContext:self.managedObjectContext]];
    [allcandidates setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * candidates = [self.managedObjectContext executeFetchRequest:allcandidates error:&error];
    //error handling goes here
    for (NSManagedObject * candidate in candidates) {
        [self.managedObjectContext deleteObject:candidate];
    }
    [self saveContext];
}


@end

