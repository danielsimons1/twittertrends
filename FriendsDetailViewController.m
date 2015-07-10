//
//  FriendsDetailViewController.m
//  twittertrends
//
//  Created by Daniel Simons on 6/10/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "FriendsDetailViewController.h"
#import "PNChart.h"
#import <Parse/Parse.h>
#import <TwitterKit/TwitterKit.h>
#import "WMGaugeView.h"
#import "Colours.h"
#import "MBProgressHUD.h"
#import "Flurry.h"
#import "DataAccess.h"
#import "DetailViewController.h"
#import "iRate.h"
#import "twittertrends-Swift.h"
#import <iAd/iAd.h>


@interface FriendsDetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) PNBarChart *barChart;
@property (strong, nonatomic) NSMutableData *chartData;
@property (weak, nonatomic) IBOutlet UIView *chartWrapperView;
@property (weak, nonatomic) IBOutlet UIView *gaugeWrapperView;
@property (strong, nonatomic) WMGaugeView *gaugeView;
@property (weak, nonatomic) IBOutlet SpringButton *popularityButton;
@property (strong, nonatomic) CNPPopupController *shareRatePickerController;
@property (strong, nonatomic) NSNumber *counter;

@end

@implementation FriendsDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [Flurry logEvent:@"FriendsDetailViewController viewDidLoad"];
    //self.canDisplayBannerAds = YES;
    // Do any additional setup after loading the view.
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = [NSString stringWithFormat:@"@%@",self.candidate.twittername];
    
    //self.followerCount.format = @"%d%d.%d%d";
    //[self.followerCount countFrom:0. to:self.count.floatValue];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didPressShare)];
    self.navigationItem.rightBarButtonItem = shareItem;
    self.title = self.candidate.name;
    [self.navigationController setTitle:self.candidate.name];
    [self.followerCount setText:[DetailViewController abbreviateNumber:self.candidate.followersCount.intValue withDecimal:100]];
    [self.listsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.listsCount.intValue withDecimal:100]];
    [self.friendsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.friendsCount.intValue withDecimal:100]];
    [self.tweetsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.tweetsCount.intValue withDecimal:100]];
    
    //[self.popularityLabel setText:[NSString stringWithFormat:@"%.02f",[DetailViewController popularityScore:self.candidate]]];
    [self.avatarImageView setImage:self.backgroundImage];
    [self.avatarImageView.layer setMasksToBounds:YES];
    [self.avatarImageView.layer setCornerRadius:22.];
    
    self.barChart.delegate = self;
    
    [self getRetweetsForUser:self.candidate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    float popularityScore = [DetailViewController popularityScore:self.candidate];
    [self.popularityButton setTitle:[NSString stringWithFormat:@"%.02f", [DetailViewController popularityScore:self.candidate]]  forState:UIControlStateNormal];
    [self.gaugeView setValue:popularityScore animated:YES duration:1.6 completion:^(BOOL finished) {
    }];
    
    self.popularityButton.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureGauge {
    self.gaugeView = [[WMGaugeView alloc] initWithFrame:CGRectMake(0, 0, 250,250.0)];
    self.gaugeView.maxValue = 100.0;
    self.gaugeView.scaleDivisions = 10;
    self.gaugeView.scaleSubdivisions = 5;
    self.gaugeView.scaleStartAngle = 30;
    self.gaugeView.scaleEndAngle = 330;
    self.gaugeView.innerBackgroundStyle = WMGaugeViewInnerBackgroundStyleGradient;
    self.gaugeView.showScaleShadow = NO;
    self.gaugeView.scaleFont = [UIFont fontWithName:@"AvenirNext-UltraLight" size:0.04];
    self.gaugeView.scalesubdivisionsAligment = WMGaugeViewSubdivisionsAlignmentCenter;
    self.gaugeView.scaleSubdivisionsWidth = 0.002;
    self.gaugeView.scaleSubdivisionsLength = 0.04;
    self.gaugeView.scaleDivisionsWidth = 0.007;
    self.gaugeView.scaleDivisionsLength = 0.07;
    self.gaugeView.needleStyle = WMGaugeViewNeedleStyle3D;
    self.gaugeView.needleWidth = 0.012;
    self.gaugeView.needleHeight = 0.4;
    self.gaugeView.needleScrewStyle = WMGaugeViewNeedleScrewStyleGradient;
    self.gaugeView.needleScrewRadius = 0.05;
    self.gaugeView.showScale = YES;
    self.gaugeView.showInnerBackground = NO;
    self.gaugeView.backgroundColor = [UIColor clearColor];
    self.gaugeView.showRangeLabels = YES;
    self.gaugeView.rangeValues = @[@20, @40, @60, @80, @100];
    self.gaugeView.rangeColors = @[[UIColor denimColor],[UIColor skyBlueColor], [UIColor successColor], [UIColor mandarinColor], [UIColor crimsonColor]];
    self.gaugeView.rangeLabels = @[@"Cold", @"Mild", @"Warm", @"Hot", @"On Fire"];
    self.gaugeView.rangeLabelsFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:.065];
    self.gaugeView.rangeLabelsWidth = .12;
    [self.gaugeWrapperView addSubview:self.gaugeView];
    
    [self.gaugeWrapperView bringSubviewToFront:self.avatarImageView];
    
}

- (void)didFinishFriendLoad {
    [self performSegueWithIdentifier:@"friendsList" sender:self.candidate];
}

- (void)goBack {
    [Flurry logEvent:@"FriendsDetailViewController addFriends"];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didPressShare {
    [Flurry logEvent:@"FriendsDetailViewController pressed share button"];
    
    NSString *primaryText = [NSString stringWithFormat:@"Check out @%@'s social trends. Powered by Unofficial Calculators http://itunes.apple.com/app/id1004557203",self.candidate.twittername];
    UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[viewImage, primaryText] applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePostToVimeo, UIActivityTypePostToWeibo];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)didPressPostOrRate:(id)sender {
    [Flurry logEvent:@"FriendsDetailViewController pressed rate or share button"];
    [self displayShareOrRatePicker];
}

- (void)displayShareOrRatePicker {
    CNPPopupButtonItem *twitter = [CNPPopupButtonItem defaultButtonItemWithTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Share on Facebook"] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] backgroundColor:[UIColor denimColor]];
    CNPPopupButtonItem *facebook = [CNPPopupButtonItem defaultButtonItemWithTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Share on Twitter"] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] backgroundColor:[UIColor skyBlueColor]];
    
    CNPPopupButtonItem *rateApp = [CNPPopupButtonItem defaultButtonItemWithTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Rate the app"] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] backgroundColor:[UIColor successColor]];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    self.shareRatePickerController = [[CNPPopupController alloc] initWithTitle:[[NSAttributedString alloc] initWithString:@"Share Twitter Score" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : [UIColor mandarinColor]}] contents:nil buttonItems:@[twitter, facebook, rateApp] destructiveButtonItem:nil];
    
    
    CNPPopupTheme *theme = [CNPPopupTheme defaultTheme];
    [theme setShouldDismissOnBackgroundTouch:YES];
    [theme setMaskType:CNPPopupMaskTypeDimmed];
    [theme setPopupStyle:CNPPopupStyleCentered];
    
    [self.shareRatePickerController setTheme:theme];
    [self.shareRatePickerController setDelegate:self];
    [self.shareRatePickerController presentPopupControllerAnimated:YES];
}


- (void)popupController:(CNPPopupController *)controller didDismissWithButtonTitle:(NSString *)title {
    if ([title isEqualToString:@"Share on Twitter"]) {
        [Flurry logEvent:@"pressed Share on Twitter"];
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        UIGraphicsBeginImageContext(self.gaugeWrapperView.bounds.size);
        
        [self.gaugeWrapperView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        [tweetSheet addImage:viewImage];
        [tweetSheet setInitialText:@"Check out this Twitter Score http://itunes.apple.com/app/id1004557203"];
        
        [self presentViewController:tweetSheet animated:YES completion:nil];
    } else if ([title isEqualToString:@"Share on Facebook"]) {
        [Flurry logEvent:@"pressed Share on Facebook"];
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        UIGraphicsBeginImageContext(self.gaugeWrapperView.bounds.size);
        
        [self.gaugeWrapperView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        [controller addImage:viewImage];
        [controller setInitialText:@"Check out this Twitter Score http://itunes.apple.com/app/id1004557203"];
        [self presentViewController:controller animated:YES completion:Nil];
        
    } else if ([title isEqualToString:@"Rate the app"]) {
        [Flurry logEvent:@"pressed Rate the app"];
        [[UIApplication sharedApplication] openURL:[iRate sharedInstance].ratingsURL];
    }
}

- (void)getRetweetsForUser:(Candidate *)twitterUser {

    NSString * statusesEndpoint = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
    NSDictionary *params2 = @{@"screen_name" : twitterUser.twittername, @"include_rts": @"false"};
    
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
             NSError *jsonError;
             NSMutableDictionary *json = [NSJSONSerialization
                                          JSONObjectWithData:data2
                                          options:0
                                          error:&jsonError];
             [self handleFriendTimelineResponse:json forFriend:twitterUser];
         } else {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             NSLog(@"Error: %@", connectionError2);
             
         }
     }];
}

- (void)handleFriendTimelineResponse:(NSMutableDictionary *)timelines forFriend:(Candidate *)friend {
    
    NSInteger retweetCount = 0;
    for (NSDictionary *tweet in timelines) {
        retweetCount = retweetCount + [tweet[@"retweet_count"] integerValue];
    }
    friend.retweetsCount = [NSNumber numberWithInteger:retweetCount];
    [self configureGauge];
    [self.retweetsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.retweetsCount.intValue withDecimal:100]];
}

@end
