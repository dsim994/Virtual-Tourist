# Virtual-Tourist

### Overview
Swift application that allows users to drop a pin on a map and get images from that pins location via the Flickr Api.

<img src="ScreenShots/IMG_0237.PNG" height="500"> <img src="ScreenShots/IMG_0238.PNG" height="500"> <img src="ScreenShots/IMG_0240.PNG" height="500">

### Implementation
Virtual Tourist has two View Controller Scenes:

* __MapController__- When the application starts it will open to the Map View. Users will be able to zoom and scroll around the map using standard pinch and drag gestures. Tapping and holding the map drops a new pin and there is no limit to how many can be placed. When a pin is tapped, the application is navigated to the Photo Album View while downloading the images realitive to your location from Flickr.

* __CollectionController__ - If images are available they will be displayed in a collection view once they have all been downloaded. Tapping the "New Collection" button will empty the photo album and fetch a new set of images. Users are able to remove photos from an album by tapping them. Tapping the back button will return the user to the Map view.

### Requirements
* Xcode 10.0 
* Swift 5.0
