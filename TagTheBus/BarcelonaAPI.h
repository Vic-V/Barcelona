//
//  BarcelonaAPI.h
//  TagTheBus
//
//  Created by Victor Vostriakov on 30/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

static NSString *const _Nonnull Latitude = @"lat";
static NSString *const _Nonnull Longitude = @"lon";

static NSString *const _Nonnull Transport_Bus = @"bus";
static NSString *const _Nonnull Transport_Metro = @"metro";
static NSString *const _Nonnull Transport_Bicing = @"bicing";
static NSString *const _Nonnull Transport_Tram = @"tram";
static NSString *const _Nonnull Transport_Ferrocarrils = @"ferrocar";
static NSString *const _Nonnull Transport_Renfe = @"renfe";

static NSString *const _Nonnull transportTag = @"Transport";
static NSString *const _Nonnull titleTag = @"Title";
static NSString *const _Nonnull urlTag = @"url";
static NSString *const _Nonnull infoTag = @"info";
static NSString *const _Nonnull transportId = @"id";
static NSString *const _Nonnull stationID = @"id";


@interface BarcelonaAPI : NSObject
+ (void)loadStationsFromLocalURL:(NSURL *)localFile
                     intoContext:(NSManagedObjectContext *)context
                    forTransport:(NSString *)transport
             andThenExecuteBlock:(void(^)())whenDone;

+ (NSDictionary *)tags;

    
@end
