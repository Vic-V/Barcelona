"TagTheBus" is just a REST/JSON part of other application.

It presents the public transport data - bus stops, metro station, etc.
("Barcelona urban mobility API REST": http://barcelonaapi.marcpous.com)

The application design provides : non-blocking UI, real-time updates, work in low connectivity situations

Sceleton:
* (at first lounch or if modified) stations (JSON) are downloaded from internet in background sessions
* recieved stations are saved into local database (CoreData)
* UI (TableView / MapView) is notified and updated as new data arrives 
* in background, the timer periodically connects to internet just to check if server data is modified
   Status: it looks like http://barcelonaapi.marcpous.com is not RESTful,
   (no hash, it ignores HTTPHeaderField:@"If-Modified-Since", and never send back code 304)
  so this part is commented
* Lounched next time, TagTheBus loads station data from local database.

UI:
* MapView with standard annotation pins of 3 color and non-standerd grouping pins
* Disclosure button on standard pin does nothing
* Disclosure button on non-standerd grouping pins zooms to show this group
* TableView sectioned by transport, provides station name, line names
