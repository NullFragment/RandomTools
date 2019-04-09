"""
April 15, 2018: Modified duplicate deletion script further by Kyle Salitrik to remove duplicates from playlists
"""

from LoadClient import load_client
import re


def remove_playlist_duplicates(search_term, client):
    """
    Removes all duplicates from playlists with the searched regex term
    :param search_term: term for regex to search
    :param client: reference to client to be used
    :return: nothing
    """
    print('Getting all playlists ...')
    all_playlists = client.get_all_user_playlist_contents()

    # Look for duplicate songs in all playlists
    for playlist in all_playlists:
        if re.search(search_term, playlist.get('name')):
            playlist_songs = playlist.get('tracks')
            track_id_list = []
            entries_to_remove = []

            # Find list of duplicate songs
            for song in playlist_songs:
                entry_id = song.get('id')
                track_id = song.get('trackId')
                if track_id not in track_id_list:
                    track_id_list.append(track_id)
                else:
                    entries_to_remove.append(entry_id)

            # Actually remove duplicates
            client.remove_entries_from_playlist(entries_to_remove)


if __name__ == '__main__':
    open_client = load_client()
    term = input('Enter the keyword of playlists you would like to search (use . for all playlists):')
    remove_playlist_duplicates(term, open_client)
