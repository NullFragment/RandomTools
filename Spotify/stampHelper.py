import requests
import textwrap


def getAlbumsFromPlaylist(authKey, playlistId):
    albumIds = []
    offset = 0
    stepSize = 100
    moreTracks = True
    totalTracksInPlaylist = int(
        requests.get(
            'https://api.spotify.com/v1/playlists/' + playlistId +
            '/tracks?fields=total',
            headers={
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + authKey
            }).json().get('total'))

    while (moreTracks):
        print("Getting tracks " + str(offset + 1) + " to " +
              str(min(offset + stepSize, totalTracksInPlaylist)) + " of " +
              str(totalTracksInPlaylist) + " total.")
        getPlaylistTracksRequest = requests.get(
            'https://api.spotify.com/v1/playlists/' + playlistId +
            '/tracks?fields=items(track(album(id)))%2Cnext&limit=' +
            str(stepSize) + '&offset=' + str(offset),
            headers={
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + authKey
            }).json()
        for track in getPlaylistTracksRequest.get('items'):
            albumIds.append(track.get('track').get('album').get('id'))

        if (not getPlaylistTracksRequest.get('next')):
            moreTracks = False
        else:
            offset = offset + stepSize
    albumIds = list(dict.fromkeys(albumIds))
    print("Obtained " + str(len(albumIds)) + " albums from " +
          str(totalTracksInPlaylist) + " tracks in the playlist.")
    return albumIds


def getLibrary(authKey):
    moreAlbums = True
    offset = 0
    stepSize = 50
    albums = []
    trackIds = []
    albumIds = []
    artistIds = []
    while (moreAlbums):
        print("Getting albums from " + str(offset + 1) + " up to " +
              str(offset + stepSize))

        getAlbumsResponse = requests.get(
            "https://api.spotify.com/v1/me/albums?limit=50&offset=" +
            str(offset),
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "Bearer " + authKey
            }).json()
        for album in getAlbumsResponse.get('items'):
            albums.append(album.get('album'))
        if (not getAlbumsResponse.get('next')):
            moreAlbums = False
        else:
            offset = offset + stepSize
    for album in albums:
        albumIds.append(album.get('id'))
        for track in album.get('tracks').get('items'):
            trackIds.append(track.get('id'))
        for artist in album.get('artists'):
            artistIds.append(artist.get('id'))

    print("Got " + str(len(trackIds)) + " tracks from " + str(len(albumIds)) +
          " albums by " + str(len(artistIds)) + " artists.")

    return trackIds, artistIds


def followArtists(authKey, artistIds):
    followedArtists = []
    offset = 0
    stepSize = 50
    while offset <= len(artistIds):
        print("Following artists " + str(offset + 1) + " to " +
              str(min(offset + stepSize, len(artistIds))) + " of " +
              str(len(artistIds)) + " total.")
        artistsToLike = artistIds[offset:offset + stepSize]
        putArtistsResponse = requests.put(
            "https://api.spotify.com/v1/me/following?type=artist&ids=" +
            ",".join(artistsToLike),
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "Bearer " + authKey
            })
        if (putArtistsResponse.status_code == 204):
            print("Success")
            followedArtists.extend(artistsToLike)
        else:
            print("Something went wrong...")
            exit()
        offset = offset + stepSize
    print(
        "Checking that the list of followed artists is the same as the list obtained earlier... "
        + str(followedArtists == artistIds))


def likeTracks(authKey, trackIds):
    likedTracks = []
    offset = 0
    stepSize = 50
    while offset <= len(trackIds):
        print("Liking tracks " + str(offset + 1) + " to " +
              str(min(offset + stepSize, len(trackIds))) + " of " +
              str(len(trackIds)) + " total.")
        tracksToLike = trackIds[offset:offset + stepSize]
        putTracksResponse = requests.put(
            "https://api.spotify.com/v1/me/tracks?ids=" +
            ",".join(tracksToLike),
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "Bearer " + authKey
            })
        if (putTracksResponse.status_code == 200):
            print("Success")
            likedTracks.extend(tracksToLike)
        else:
            print("Something went wrong...")
            exit()
        offset = offset + stepSize
    print(
        "Checking that the list of liked tracks is the same as the list obtained earlier... "
        + str(likedTracks == trackIds))


def likeAlbums(authKey, albumIds):
    likedAlbums = []
    offset = 0
    stepSize = 50
    while offset <= len(albumIds):
        print("Liking albums " + str(offset + 1) + " to " +
              str(min(offset + stepSize, len(albumIds))) + " of " +
              str(len(albumIds)) + " total.")
        albumsToLike = albumIds[offset:offset + stepSize]
        print(albumsToLike)
        putAlbumsResponse = requests.put(
            "https://api.spotify.com/v1/me/albums?ids=" +
            ",".join(albumsToLike),
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "Bearer " + authKey
            })
        print(putAlbumsResponse)
        if (putAlbumsResponse.status_code == 200
                or putAlbumsResponse.status_code == 201):
            print("Success")
            likedAlbums.extend(albumsToLike)
        else:
            print("Something went wrong...")
            exit()
        offset = offset + stepSize
    print(
        "Checking that the list of liked albums is the same as the list obtained earlier... "
        + str(likedAlbums == albumIds))


def query_yes_no(question, default="yes"):
    """Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    """
    valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        print(question + prompt)
        choice = input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            print("Please respond with 'yes' or 'no' " "(or 'y' or 'n').\n")


print(
    textwrap.fill(
        "This will obtain all of the albums from a playlist transferred by stamp and add them to your library. "
        +
        "It can then optionally add all of the tracks and like all artists from all of the albums in your library.",
        width=80) + "\n")

print(
    textwrap.fill(
        "The reason this is not all done at once is because stamp will sometimes confuse albums, "
        +
        "so it is best to take a look through the albums added and ensure you want to keep all of them.",
        width=80))

if (not query_yes_no("Do you want to continue?")):
    exit()

print("You can find the ID for the playlist one of two ways:" +
      "\n\t - From the desktop app, right click and copy the playlist link" +
      "\n\t - From a browser, copy and paste the link")
print("Enter the URL for the source playlist: ")
playlistId = input()

print(
    "Before proceeding you must obtain an authorization key with the following permissions:"
    + "\n\t - user-follow-modify" + "\n\t - user-library-read" +
    "\n\t - user-library-modify" + "\n\t - playlist-read-private")
print(
    "To obtain the authorization key, go to the following link and click \"get token\": \n"
    + "https://developer.spotify.com/console/get-current-user/")
print("Please enter your authorization key: ")
authKey = input().split('/')[-1].split('?')[0]

albumIds = getAlbumsFromPlaylist(authKey, '5DS4dwgnyeBq4M6f9XMUjJ')
likeAlbums(authKey, albumIds)

print("You should go check that you want to keep all of the liked albums in your library.")
if (query_yes_no(
        "Do you want to follow all of the artists and tracks from your liked albums?"
)):
    print("Getting a list of all liked albums.")
    trackIds, artistIds = getLibrary(authKey)

    if (query_yes_no("Do you want to follow all of the artists found?")):
        print("Following all artists")
        followArtists(authKey, artistIds)
    if (query_yes_no("Do you want to like all of the tracks found?")):
        print("Liking all tracks")
        likeTracks(authKey, trackIds)
