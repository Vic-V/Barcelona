"TagTheBus" is a just a part of bigger application (iOS7 was a requirement).

It works with REST API of Barcelona public transport.
("Barcelona urban mobility API REST": http://barcelonaapi.marcpous.com)

The application design includs : reactive UI, real-time updates, work in low connectivity situations

1. (at first time or if modified) downloads stations data (JSON) from internet in backgroundSessions
2. saves station data to local database (with CoreData)
3. notifies and updates TableView / MapView 

4. in background, using timer, it connects to internet just to check if JSON is modified
   Status: it looks like http://barcelonaapi.marcpous.com is not RESTful,
   (no hash, it ignores HTTPHeaderField:@"If-Modified-Since", and never send back code 304)
  so this part is commented

Lounching next time, TagTheBus loads station data from local database.
