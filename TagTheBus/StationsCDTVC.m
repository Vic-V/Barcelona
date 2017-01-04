//
//  StationsCDTVC.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 12/10/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
// if db > 100 massage db,  isDB
// download
// if db > 0, massage "modified"

#import "StationsCDTVC.h"
#import "Station.h"
#import "StationDbNotifications.h"
#import "BarcelonaAPI.h"
#import "AppDelegate.h"

@interface StationsCDTVC()
@property (nonatomic, strong) NSArray *indexOfIndex;
@property (nonatomic, strong) NSString *indexString;
@end

@implementation StationsCDTVC

- (void)addObserverFor:(NSString *)notificationName {
    [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      self.context = note.userInfo[StationDbContext];
                                                  }];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self addObserverFor:StationDbAvailabilityNotification];
    [self addObserverFor:StationDbUpdatedNotification];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.context) {
        self.context = ((AppDelegate *)UIApplication.sharedApplication.delegate).managedObjectContext;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self interfaceOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self interfaceOrientation:toInterfaceOrientation];
}

- (void)setContext:(NSManagedObjectContext *)context {
    _context = context;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Station"];
    request.predicate = nil;
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"transportID" ascending:YES selector:@selector(localizedStandardCompare:)],
                                 [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:@"transportID"
                                                                                   cacheName:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Station Cell"];
    
    Station *station = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = station.title;
    cell.detailTextLabel.text = station.subtitle;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    for (int i=0; i<self.indexOfIndex.count; i++) {
        if (index < [self.indexOfIndex[i] integerValue]) return i;
    }
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @[Transport_Bus, Transport_Metro, Transport_Bicing, Transport_Tram, Transport_Ferrocarrils, Transport_Renfe][section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *indexChars = [self.indexString componentsSeparatedByCharactersInSet:NSCharacterSet.punctuationCharacterSet];
    return indexChars;
}

- (void)interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            self.indexString = @"B.u.s. .M.e.t.r.o. .B.i.c.i. .T.r.a.m. .F.g.c. .R.e.n.f.e";
            //                   0 1 2 3 4 5 6 7 8 9 10        15        20      24
            self.indexOfIndex = @[ @(3), @(9), @(15), @(20), @(24) ];
            break;
        default:
            self.indexString = @"Bus. . .Metro. . .Bicing. . .Tram. . .Fgc. . .Renfe";
            //                   0   1 2 3     4 5 6      7 8 9      11      14
            self.indexOfIndex = @[ @(2), @(5), @(8), @(11), @(14) ];
    }
    [self.tableView reloadSectionIndexTitles];
}

@end
