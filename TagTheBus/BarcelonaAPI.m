//
//  BarcelonaAPI.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 30/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//
// {"code":200,"data":{"tmbs":[{"id":"1","street_name":"Almog\u00e0vers-\u00c0vila","city":"BARCELONA","utm_x":"432542,5460","utm_y":"4583524,2340","lat":"41.3985182","lon":"2.1917991","furniture":"Pal","buses":"06 - 40 - 42 - 141 - B25 - N11"},
// {"code":200,"data":{"bici":[{"id":"1","name":"Gran Via Corts Catalanes, 760","lat":"41.397952","lon":"2.180042","nearby_stations":"24,369,387,424"},
// {"code":200,"data":{"tram":[{"id":"21","line":"T1-T2","name":"Fontsanta i Fatj\u00f3","type":"TRAMBAIX","zone":"Zona 1","connections":"","lat":"41.3602701633887","lon":"2.06231782329774"},
// {"code":200,"data":{"fgc":[{"id":"264","line":"LLEIDA-LA POBLA","name":"Lleida-Pirineus","accessibility":"","zone":"No integrat","connections":"R12-R13-R14-TGV","lat":"41.6206570265921","lon":"0.633413111246983"},
// {"code":200,"data":{"renfe":[{"id":"216","operator":"RENFE","type":"REGIONALS","line":"R16","name":"Ulldecona-Alcanar-La S\u00e8nia","zone":"","lat":"40.5958608323863","lon":"0.449509090610943"},

#import "BarcelonaAPI.h"
#import "Station.h"

@implementation BarcelonaAPI

+ (NSDictionary *)tags {
    return @{Transport_Metro:       @{transportTag: @"metro",   titleTag: @"name" ,         urlTag: @"metro",   infoTag: @"line", transportId:@(0)},
            Transport_Bus:          @{transportTag: @"tmbs",    titleTag: @"street_name",   urlTag: @"bus",     infoTag:@"buses", transportId:@(1)},
            Transport_Bicing:       @{transportTag: @"bici",    titleTag: @"name",          urlTag: @"bicing",  infoTag:@"nearby_stations", transportId:@(2)},
            Transport_Tram:         @{transportTag: @"tram",    titleTag: @"name",          urlTag: @"tram",    infoTag:@"line", transportId:@(3)},
            Transport_Ferrocarrils: @{transportTag: @"fgc",     titleTag: @"name",          urlTag: @"fgc",     infoTag:@"line", transportId:@(4)},
            Transport_Renfe:        @{transportTag: @"renfe",   titleTag: @"name",          urlTag: @"renfe",   infoTag:@"line", transportId:@(5)}};
}

+ (void)loadStationsFromLocalURL:(NSURL *)localFile
                     intoContext:(NSManagedObjectContext *)context
                    forTransport:(NSString *)transport
             andThenExecuteBlock:(void(^)())whenDone
{
    if (context) {
        NSDictionary *structureJSON = [self tags];
        NSData *jonsonData =  [NSData dataWithContentsOfURL:localFile];
        if (!jonsonData) {
            NSLog(@" ERROR in loadStationsFromLocalURL : %@", localFile);
            return;
        }
        NSError *error;
        NSDictionary *dictionaryJSON = [NSJSONSerialization JSONObjectWithData:jonsonData options:0 error:&error];
        NSArray *stationsJSON = dictionaryJSON[@"data"][structureJSON[transport][transportTag]];
        
        [Station loadStationsFromJSONArray:stationsJSON
                                  tagsJSON:structureJSON[transport]
                               intoContext:context];
        [context save:NULL];
        if (whenDone) whenDone();
    } else {
        if (whenDone) whenDone();
    }
}

@end
