# Google Play Music Tools
This collection of small functions was created for people who either have a relatively un-maintained Google Play Music account or have just used a tool to move from another music service over to GPM. A description of the functions included, FAQ, and required packages are listed below.

**NOTE:** While this is all based on Python 3.5 and should be OS agnostic, all but the original script ([DeleteDuplicateLibrarySongs.py](https://github.com/NullFragment/GooglePlayMusicTools/blob/master/DeleteDuplicatesFromPlaylist.py "DeleteDuplicateLibrarySongs.py")) were written and tested only on Ubuntu 16.04. YMMV.

## Functions Included
* [**DeleteDuplicateLibrarySongs:**](https://github.com/NullFragment/GooglePlayMusicTools/blob/master/DeleteDuplicateLibrarySongs.py "DeleteDuplicateLibrarySongs.py") Deletes all duplicate songs from a user's library
* [**DeleteDuplicatesFromPlaylist:**](https://github.com/NullFragment/GooglePlayMusicTools/blob/master/DeleteDuplicatesFromPlaylist.py "DeleteDuplicatesFromPlaylist.py") Deletes all duplicates from playlists in a user's library 
* [**EntireLibraryToPlaylists:**](https://github.com/NullFragment/GooglePlayMusicTools/blob/master/DeleteDuplicatesFromPlaylist.py "EntireLibraryToPlaylists.py") Adds all songs in a user's library into playlists for easily downloading all songs on mobile devices.

## FAQ / Recommendations
* **What should I use for my username and password?**
    * For the username, simply enter the same login email as you would using a browser or mobile device.
    * I highly recommend using a [Google App Password](https://support.google.com/accounts/answer/185833?hl=en "Google App Password Help") and then deleting it after you are finished.
* **Why does the playlist duplicate remover script use regex?**
    * This is a double edged sword. If you have multiple playlists that share a common phrase (especially common when transferring playlists from a music service that allows more than 1000 songs per playlist), it will search if that phrase exists in all of the playlists and remove the duplicates from them.
    * **Be sure to change the name of a playlist to something unique first if you only want that playlist to be affected** (or modify the code)

* **Why would you want all of your library put into playlists? **
    * Because I have a problem....
    * Also if you want to download all of your music on your phone or any other mobile device, it makes it a hell of a lot easier than downloading each album individually.

## Requirements
[gmusicapi](https://github.com/simon-weber/Unofficial-Google-Music-API "gmusicapi")


## This entire repository was started thanks to the prior work of:
* shuichinet
* fcrimins
* Morgan Gothard
* John M. Kuchta

Acknowledgements are also listed in the [DeleteDuplicateLibrarySongs.py](https://github.com/NullFragment/GooglePlayMusicTools/blob/master/DeleteDuplicatesFromPlaylist.py "DeleteDuplicateLibrarySongs.py") file, which was the catalyst for this little excursion.

# Disclaimer
Use these tools at your own risk. They worked for me at the time but at any point these tools could become deprecated. I assume no responsibility for any issues that you cause to your Google Play account.
