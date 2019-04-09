"""
Written by Kyle Salitrik
"""

from LoadClient import load_client
import math


def library_to_playlists(client, max_songs_per_list=900):
    """
    Adds all songs in user's library to playlists with a maximum number of specified songs per list
    900 songs per playlist is recommended. Google Play Music gets finnicky with numbers near 1000 (the hard max)
    :param client: reference to client with API access
    :param max_songs_per_list: maximum songs wanted per playlist, 900 default
    :return: nothing
    """
    print('Getting a list of all songs...')
    all_songs = client.get_all_songs()
    num_playlists = int(math.ceil(len(all_songs) / max_songs_per_list))

    # Create playlists
    for i in range(0, num_playlists):
        start = i * max_songs_per_list
        end = min(start + max_songs_per_list, len(all_songs))
        playlist_name = str(start + 1) + '-' + str(end)
        playlist_id = client.create_playlist(playlist_name)
        songs_to_add = []

        # Build list of songs to add to current playlist
        for song in range(start, end):
            songs_to_add.append(all_songs[song].get('id'))
        client.add_songs_to_playlist(playlist_id, songs_to_add)


if __name__ == '__main__':
    open_client = load_client()
    # max_songs = int(input("Enter the maximum songs per playlist you would like: "))
    # if max_songs > 1000:
    #     max_songs = 1000
    #     print("Maximum number of songs is 1000. \n Setting max songs per playlist to 1000.")
    library_to_playlists(open_client, 900)
