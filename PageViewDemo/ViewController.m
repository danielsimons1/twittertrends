//
//  ViewController.m
//  PageViewDemo
//
//  Created by Simon on 24/11/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "ViewController.h"
#import <TwitterKit/TwitterKit.h>
#import "Flurry.h"
#import "Candidate.h"
#import "DetailViewController.h"
#import "DataAccess.h"
#import <iAd/iAd.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *loginButtonWrapperView;
@property (strong ,nonatomic) UIImage *cachedImage;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"ViewController viewDidLoad"];

	// Create the data model
    _pageTitles = @[@"What is your Twitter Score?", @"Compare your friends Scores", @"Share Scores"];
    _pageImages = @[@"image1", @"image3", @"image4"];
    
    

    if (YES || [TwitterKit session] == nil) {
        
        // Create page view controller
        self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
        self.pageViewController.dataSource = self;
        
        PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
        NSArray *viewControllers = @[startingViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        
        // Change the size of page view controller
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50);
        
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
        [self.pageViewController didMoveToParentViewController:self];
        
        
        TWTRLogInButton *logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession *session, NSError *error) {
            // play with Twitter session
            if (!error) {
                NSLog(@"twitter login success");
                [Flurry logEvent:@"ViewController successful Login"];
                [self createCandidate:session.userName];
            }
        }];
        
        if ([[[UIDevice currentDevice] model] rangeOfString:[NSString stringWithFormat:@"iPad"]].location == NSNotFound) {
            self.loginButtonWrapperView.frame = CGRectMake(0, self.loginButtonWrapperView.frame.origin.y, self.view.frame.size.width, 10);
        } else {
            self.loginButtonWrapperView.frame = CGRectMake(0, self.loginButtonWrapperView.frame.origin.y - 100, self.view.frame.size.width, 20);
        }
        //
        

        logInButton.center = self.loginButtonWrapperView.center;
        [self.view addSubview:logInButton];
        [self.view bringSubviewToFront:logInButton];
    }
    

}

- (void)viewDidAppear:(BOOL)animated {
    if ([TwitterKit session] != nil) {
        [Flurry logEvent:@"ViewController viewDidAppear already logged in to Twitter"];
        [self createCandidate:[TwitterKit session].userName];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startWalkthrough:(id)sender {
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
}

- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];
    pageContentViewController.imageFile = self.pageImages[index];
    pageContentViewController.titleText = self.pageTitles[index];
    pageContentViewController.pageIndex = index;
    
    return pageContentViewController;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Candidate *candidate = (Candidate *)sender;
    DetailViewController *detailViewController = (DetailViewController *)[[[[segue	destinationViewController] contentViewController] childViewControllers] firstObject];
    [detailViewController setCandidate:candidate];
    [detailViewController setBackgroundImage:self.cachedImage];
}

- (void)createCandidate:(NSString *)twitterName {
    NSString *statusesShowEndpoint = @"https://api.twitter.com/1.1/users/lookup.json";
    NSDictionary *params = @{@"screen_name" : twitterName,@"page" : @"1", @"count" : @"1"};
    NSError *clientError;
    NSURLRequest *request = [[[Twitter sharedInstance] APIClient]
                             URLRequestWithMethod:@"GET"
                             URL:statusesShowEndpoint
                             parameters:params
                             error:&clientError];
    
    if (request) {
        [[[Twitter sharedInstance] APIClient]
         sendTwitterRequest:request
         completion:^(NSURLResponse *response,
                      NSData *data,
                      NSError *connectionError) {
             if (data) {
                 // handle the response data e.g.
                 
                 
                 NSError *jsonError;
                 NSArray *json = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:0
                                  error:&jsonError];
                 NSArray *jsonDict = json;
                 for (NSDictionary *candidate in jsonDict) {
                     
                     NSString * statusesEndpoint = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
                     NSDictionary *params2 = @{@"screen_name" : candidate[@"screen_name"]};
                     
                     NSError *clientError2;
                     NSURLRequest *request2 = [[[Twitter sharedInstance] APIClient]
                                               URLRequestWithMethod:@"GET"
                                               URL:statusesEndpoint
                                               parameters:params2
                                               error:&clientError2];
                     
                     [[[Twitter sharedInstance] APIClient]
                      sendTwitterRequest:request2
                      completion:^(NSURLResponse *response,
                                   NSData *data2,
                                   NSError *connectionError2) {
                          if (data2) {
                              NSError *jsonError2;
                              NSArray *json2 = [NSJSONSerialization
                                                JSONObjectWithData:data2
                                                options:0
                                                error:&jsonError2];
                              NSArray *jsonDict2 = json2;
                              NSInteger retweetCount = 0;
                              for (NSDictionary *tweet in jsonDict2) {
                                  retweetCount = retweetCount + [tweet[@"retweet_count"] integerValue];
                              }
                              Candidate *c = [[DataAccess sharedInstance] saveOrUpdateCandidate:candidate withRetweets:retweetCount isFriend:NO];
                              //Change image url to bigger.
                              NSString *imageUrlString = [[c imageURL] stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"];
                              NSURL *url = [NSURL URLWithString:imageUrlString];
                              NSData *data = [[NSData alloc] initWithContentsOfURL:url];
                              self.cachedImage = [UIImage imageWithData:data];
                              [self didFinishInitialDataLoad:c];
                          } else {
                              NSLog(@"Error: %@", connectionError2);
                          }
                      }];
                 }
             }
             else {
                 NSLog(@"Error: %@", connectionError);
             }
         }];
    }
    else {
        NSLog(@"Error: %@", clientError);
    }
    
}

- (void)didFinishInitialDataLoad:(Candidate *)candidate {
    [self performSegueWithIdentifier:@"detailView" sender:candidate];
}

@end
