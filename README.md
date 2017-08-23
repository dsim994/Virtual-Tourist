# Virtual-Tourist
### iOS Developer Nanodegree Project

### Overview
Virtual Tourist is an application that allows users to drop a pin on a map and get images from that pins location via the Flickr Api.

The app will start downloading the appropriate photos from Flickr related to the location selected. Then images will be displayed in a collection view as soon as you drop the pin on the Map, if you want to see more pictures you can use the "New Collection" button. The app will remember the places where you dropped a pin on a previous selection. Users will also be able to move pins to download new pictures and remove unwanted pins.

### Implementation
This Application has two View Controller Scenes:

* __MapController__- When the application starts it will open to the Map View. Users will be able to zoom and scroll around the map using standard pinch and drag gestures. Tapping and holding the map drops a new pin and there is no limit to how many can be placed. When a pin is tapped, the application is navigated to the Photo Album View while downloading the images realitive to your location from Flickr.

* __CollectionController__ - If there are images they will be displayed in a collection view once they have all been downloaded. Tapping the "New Collection" button will empty the photo album and fetch a new set of images. Users are able to remove photos from an album by tapping them. Tapping the back button will return the user to the Map view.

### Requirements
* Xcode 8.0 
* Swift 3.0
