//
//  Station.h
//  TagTheBus
//
//  Created by Victor Vostriakov on 29/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MapKit/MapKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface Station : NSManagedObject

+ (NSUInteger)stationsCount:(NSManagedObjectContext *)context;

+ (NSArray *)inRegion:(MKCoordinateRegion)region inContext:(NSManagedObjectContext *)context;

+ (NSArray *)stationsInContext:(NSManagedObjectContext *)context;

+ (Station *)stationWithJSONInfo:(NSDictionary *)stationDictionary
                        tagsJSON:(NSDictionary *)tags
                     intoContext:(NSManagedObjectContext *)context;

+ (NSArray *)loadStationsFromJSONArray:(NSArray *)stationsJSON
                              tagsJSON:(NSDictionary *)tags
                           intoContext:(NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END

#import "Station+CoreDataProperties.h"
