# Virtual Tourist

### Overview
Swift application that uses the MapKit framework to give users ability to drop pins on a world map and then recieve images from those pins locations via the Flickr Api.

<img src="ScreenShots/IMG_0237.PNG" height="500"> <img src="ScreenShots/IMG_0238.PNG" height="500"> <img src="ScreenShots/IMG_0240.PNG" height="500">

### Implementation
2 View Controller Scenes:

* __MapController__- Upon launch you will be presented with a map view which saves previous sessions dropped pins with core data. When a pin is pressed user is directed to Photo Album View while downloading images realitive to that pins location. Pressing and holding a specific location on the map will drop a new pin and an edit button to delete previous dropped pins.

* __CollectionController__ - If images are available they will be displayed in a collection view once they have all been downloaded. Pressing the new collection button will empty the photo album and fetch a new set of images. Users are able to remove photos from an album by tapping them. Pressing the back button will end the session and direct user to MapController.

### Requirements
* Xcode 10.0 
* Swift 5.0
