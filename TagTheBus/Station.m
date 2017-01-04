//
//  Station.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 29/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import "Station.h"
#import "Photo.h"
#import "BarcelonaAPI.h"

@implementation Station


+ (NSUInteger)stationsCount:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Station"];
    NSError *error;
    return [context countForFetchRequest:request error:&error];
}



+ (NSArray *)sortByTitle:(NSArray *)stations {
    NSMutableArray *sorted = [NSMutableArray arrayWithArray:stations];
    [sorted sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1 = [((Station *)obj1).title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *str2 = [((Station *)obj2).title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return [str1 caseInsensitiveCompare:str2];
    }];
    return [sorted copy];
}

+ (NSArray *)inRegion:(MKCoordinateRegion)region inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Station"];
    request.predicate = [NSPredicate predicateWithFormat:@"(longitude > %@) AND (longitude < %@) AND (latitude > %@) AND (latitude < %@)",
                         @(region.center.longitude-region.span.longitudeDelta/2.0),
                         @(region.center.longitude+region.span.longitudeDelta/2.0),
                         @(region.center.latitude-region.span.latitudeDelta/2.0),
                         @(region.center.latitude+region.span.latitudeDelta/2.0)];
    NSError *error;
    return [context executeFetchRequest:request error:&error];
}

+ (NSArray *)stationsInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Station"];
    NSError *error;
    return [context executeFetchRequest:request error:&error];
}

+ (Station *)stationWithJSONInfo:(NSDictionary *)stationDictionary
                       tagsJSON:(NSDictionary *)tags
          intoContext:(NSManagedObjectContext *)context
{
    Station *station = nil;
    NSString *title = [NSString stringWithString:stationDictionary[tags[titleTag]]];  // tag in JSON : bus stop  "street_name", metro as "name"
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Station"];
    request.predicate = [NSPredicate predicateWithFormat:@"(title = %@) AND (transportID == %@)", title, tags[transportId]];
    
    /*
     NSError *error;
     NSArray *matches = [context executeFetchRequest:request error:&error];
     
     if (!matches || error || ([matches count] > 1)) {
     // handle error
     } else if ([matches count]) {
     station = [matches firstObject];
     } else {
     */
    station = [NSEntityDescription insertNewObjectForEntityForName:@"Station"
                                            inManagedObjectContext:context];
    station.stationID = @([[NSString stringWithString:stationDictionary[stationID]] doubleValue]);
    station.title = title;
    station.subtitle = [NSString stringWithFormat:@"%@", [NSString stringWithString:stationDictionary[tags[infoTag]]]];
    station.longitude = @([[NSString stringWithString:stationDictionary[Longitude]] doubleValue]);
    station.latitude = @([[NSString stringWithString:stationDictionary[Latitude]] doubleValue]);
    station.transportID = tags[transportId];
    // }
    
    return station;
}


+ (NSArray *)loadStationsFromJSONArray:(NSArray *)stationsJSON
                              tagsJSON:(NSDictionary *)tags
              intoContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Station"];
    request.predicate = [NSPredicate predicateWithFormat:@"transportID == %@", tags[transportId]];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@" ERROR in loadStationsFromJSONArray "); // handle error
        return nil;
    }

    NSMutableSet *set = [NSMutableSet set];
    if (matches) {
        for (Station *s in matches)
            [set addObject:s.stationID];
    }
    int new = 0;
    NSMutableArray *stations = [NSMutableArray array];
    for (NSDictionary *stationJSON in stationsJSON) {
        NSNumber *numberStationID = @([[NSString stringWithString:stationJSON[stationID]] doubleValue]);
        if (![set containsObject:numberStationID]) {
            Station *station = [self stationWithJSONInfo:stationJSON tagsJSON:tags intoContext:context];
            [stations addObject:station];
            new++;
        }
    }
    NSLog(@"added stations: %d ", new);
    return [stations copy];
}


+ (NSArray *)_loadStationsFromJSONArray:(NSArray *)stationsJSON
                              tagsJSON:(NSDictionary *)tags
                           intoContext:(NSManagedObjectContext *)context
{
    NSMutableArray *stations = [NSMutableArray array];
    
    for (NSDictionary *stationJSON in stationsJSON) {
        Station *station = [self stationWithJSONInfo:stationJSON tagsJSON:tags intoContext:context];
        [stations addObject:station];
    }
    NSLog(@" %lu ", (unsigned long)stations.count);
    return [stations copy];
}

@end
