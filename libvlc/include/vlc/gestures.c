/*****************************************************************************
 * gestures.c: control vlc with mouse gestures
 *****************************************************************************
 * Copyright (C) 2004-2009 the VideoLAN team
 *
 * Authors: Sigmund Augdal Helberg <dnumgis@videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

/*****************************************************************************
 * Preamble
 *****************************************************************************/

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#define VLC_MODULE_LICENSE VLC_LICENSE_GPL_2_PLUS
#include <vlc_common.h>
#include <vlc_plugin.h>
#include <vlc_interface.h>
#include <vlc_vout.h>
#include <vlc_player.h>
#include <vlc_playlist.h>
#include <vlc_vector.h>
#include <assert.h>

/*****************************************************************************
 * intf_sys_t: description and status of interface
 *****************************************************************************/

typedef struct VLC_VECTOR(vout_thread_t *) vout_vector;
struct intf_sys_t
{
    vlc_playlist_t         *playlist;
    vlc_player_listener_id *player_listener;
    vlc_mutex_t             lock;
    vout_vector             vout_vector;
    bool                    b_button_pressed;
    int                     i_last_x, i_last_y;
    unsigned int            i_pattern;
    unsigned int            i_num_gestures;
    int                     i_threshold;
    int                     i_button_mask;
};

