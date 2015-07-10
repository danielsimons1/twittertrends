//
//  LeftMenuViewController.m
//  caprate
//
//  Created by Daniel Simons on 6/28/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import "LeftMenuViewController.h"
#import "Constants.h"
#import "Flurry.h"
#import <Parse/Parse.h>

#define numRows 6
#define rowHeight 54

@interface LeftMenuViewController () {
NSMutableArray *titles;
}
@end

@implementation LeftMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height - rowHeight * numRows) / 2.0f, self.view.frame.size.width, rowHeight * numRows) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.opaque = NO;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tableView.bounces = YES;
        tableView.scrollsToTop = YES;
        tableView;
    });
    
    titles = [NSMutableArray array];
    [self.view addSubview:self.tableView];

    // titles = @[[NSMutableDictionary dictionaryWithDictionary:@{@"title":@"Agent Commission",@"deeplink":@"Realtor-Commission-Calculator://", @"downloadlink":@"https://itunes.apple.com/us/app/real-estate-agent-commission/id984948275?ls=1&mt=8"}],[NSMutableDictionary dictionaryWithDictionary:@{@"title":@"Future Value",@"deeplink":@"Future-Value-Calculator://", @"downloadlink":@"https://itunes.apple.com/us/app/future-value-calculator/id981005601?ls=1&mt=8"}], [NSMutableDictionary dictionaryWithDictionary:@{@"title":@"Return On Investment",@"deeplink":@"Return-On-Investment://", @"downloadlink":@"https://itunes.apple.com/us/app/return-on-investment-calculator/id983864102?ls=1&mt=8"}], [NSMutableDictionary dictionaryWithDictionary:@{@"title":@"Rent Split",@"deeplink":@"Split-Rent://", @"downloadlink":@"https://itunes.apple.com/us/app/rent-split-calculator/id984741713?ls=1&mt=8"}]];
    //images = @[@"RealEstateAgentCommission", @"FutureValue", @"ReturnOnInvestment", @"RentSplit"];
    
    //UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    //[topView.layer setBackgroundColor:[DEFAULT_COLOR CGColor]];
    
    //[self.view addSubview:topView];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (NSIndexPath *path in [self.tableView indexPathsForSelectedRows]) {
        [[self.tableView cellForRowAtIndexPath:path] setSelected:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return titles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
        return @"More Apps";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont fontWithName:@"Avenir" size:15];
        
        cell.textLabel.textColor = [UIColor darkTextColor];
        cell.textLabel.highlightedTextColor = [UIColor lightGrayColor];
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    
    
    NSMutableDictionary *titleDict = [titles objectAtIndex:indexPath.row];
    
    [cell.textLabel setText:titleDict[@"title"]];
    
    cell.imageView.image = [UIImage imageNamed:titleDict[@"title"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *rowObject = [titles objectAtIndex:indexPath.row];
    NSString *deepLinkString = [rowObject objectForKey:@"deeplinkURL"];
    NSString *downloadLinkString = [rowObject objectForKey:@"appstoreURL"];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:deepLinkString]]) {
        [Flurry logEvent:[NSString stringWithFormat:@"did select %@",[rowObject objectForKey:@"deeplinkURL"]]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:deepLinkString]];
    } else {
        [Flurry logEvent:[NSString stringWithFormat:@"did select %@",[rowObject objectForKey:@"appstoreURL"]]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:downloadLinkString]];
    }
}

@end
