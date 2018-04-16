#!/usr/bin/env python

# created by shuichinet https://gist.github.com/shuichinet
# forked from https://gist.github.com/shuichinet/8159878 21 Nov 2015
# using minor edits by fcrimins https://www.reddit.com/user/fcrimins
# from https://www.reddit.com/r/google/comments/2xzgyv/remove_duplicate_songs_from_google_play_music/csh6mrh
# also using clever edits by Morgan Gothard https://medium.com/@mgothard
# updated for Python 3.5 by John M. Kuchta https://medium.com/@sebvance 22 Nov 2016 (hey I was busy)
# compiled by John M. Kuchta https://medium.com/@sebvance
# thanks to shuichinet, fcrimins and Mr. Gothard for their work

# April 15, 2018: Modified further by Kyle Salitrik to remove duplicates
# from playlists with a term to match


from gmusicapi import Mobileclient
from getpass import getpass
import re

search_term = input('Enter the keyword of playlists you would like to search (use . for all playlists):')
client = Mobileclient()
logged_in = client.login(input('Username:'), getpass(), Mobileclient.FROM_MAC_ADDRESS)

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
