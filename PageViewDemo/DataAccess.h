//
//  DataAccess.h
//  twending
//
//  Created by Daniel Simons on 6/3/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Candidate.h"

@interface DataAccess : NSObject <NSFetchedResultsControllerDelegate>

+ (DataAccess *)sharedInstance;

@property (strong, nonatomic) NSFetchedResultsController *fetchedCandidatesController;
@property (strong, nonatomic) NSFetchedResultsController * fetchedFollowersController;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (Candidate *)saveOrUpdateCandidate:(NSDictionary *)candidateJSON withRetweets:(NSInteger)retweetCount isFriend:(bool)isFriend;
- (Candidate *)fetchedCandidateForName:(NSString *)twittername;

- (void)logout;

@end
