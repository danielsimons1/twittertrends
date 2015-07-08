//
//  FriendsViewController.m
//  twittertrends
//
//  Created by Daniel Simons on 6/10/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

//
//  ViewController.m
//  twending
//
//  Created by Daniel Simons on 6/2/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import "FriendsViewController.h"
#import <TwitterKit/TwitterKit.h>
#import "DataAccess.h"
#import "Candidate.h"
#import "MBProgressHUD.h"
#import "FriendsDetailViewController.h"
#import <Parse/Parse.h>
#import <iAd/iAd.h>
#import "Flurry.h"
#import <iAd/iAd.h>


@interface FriendsViewController ()

@property (strong, nonatomic) IBOutlet UITableView *candidateTableView;

@property (strong ,nonatomic) NSMutableArray *tableItems;
@property (strong ,nonatomic) NSMutableDictionary *cachedImages;

@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [Flurry logEvent:@"ViewController viewDidLoad"];
    self.canDisplayBannerAds = YES;
    //self.canDisplayBannerAds = YES;
    
    self.tableItems = nil;
    self.cachedImages = [[NSMutableDictionary alloc] init];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    hud.labelText = @"Loading Teams...";
    self.candidateTableView.delegate = self;
    self.candidateTableView.dataSource = self;
    
    //PFObject *testObject = [PFObject objectWithClassName:@"TestObject"];
    //testObject[@"foo"] = @"bar";
    //[testObject saveInBackground];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[DataAccess sharedInstance] setFetchedCandidatesController:nil];
    self.tableItems = nil;
    [self.candidateTableView reloadData];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark UITableViewDataSource delegate methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.tableItems) {
        self.tableItems = [NSMutableArray arrayWithArray:[[DataAccess sharedInstance].fetchedCandidatesController fetchedObjects]];
        for (Candidate *candidate in self.tableItems) {
            NSURL *url = [NSURL URLWithString:[candidate imageURL]];
            NSData *data = [[NSData alloc] initWithContentsOfURL:url];
            [self.cachedImages setValue:[[UIImage alloc] initWithData:data] forKey:[NSString stringWithFormat:@"MyBasicCell%li",[self.tableItems indexOfObject:candidate]]];
        }
    }
    return self.tableItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyBasicCell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyBasicCell"];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Candidate *object = [[DataAccess sharedInstance].fetchedCandidatesController objectAtIndexPath:indexPath];
    
    NSString *identifier = [NSString stringWithFormat:@"MyBasicCell%li" ,
                            (long)indexPath.row];
    
    if([self.cachedImages objectForKey:identifier] != nil){
        cell.imageView.image = [self.cachedImages valueForKey:identifier];
    }else{
        NSURL *url = [NSURL URLWithString:[object imageURL]];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        
        UIImage *img = [[UIImage alloc] initWithData:data];
        [self.cachedImages setValue:img forKey:identifier];
        cell.imageView.image = img;
    }
    
    cell.textLabel.text = [object name];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"@%@",object.twittername]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.;
}

- (void)didFinishInitialDataLoad {
    [[DataAccess sharedInstance] setFetchedCandidatesController:nil];
    self.tableItems = nil;
    [self.candidateTableView reloadData];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showFriendDetail" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Candidate *candidate = [[[DataAccess sharedInstance] fetchedCandidatesController] objectAtIndexPath:sender];
    FriendsDetailViewController *detailViewController = (FriendsDetailViewController *)[segue destinationViewController];
    detailViewController.interstitialPresentationPolicy = ADInterstitialPresentationPolicyAutomatic;
    [detailViewController setCandidate:candidate];
    [detailViewController setBackgroundImage:[self.cachedImages valueForKey:[NSString stringWithFormat:@"MyBasicCell%li" ,(long)((NSIndexPath*)sender).row]]];
}
- (IBAction)didPressDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
