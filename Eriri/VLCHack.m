//
//  VLCHack.m
//  Eriri
//
//  Created by xjbeta on 3/4/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

#import "VLCHack.h"


@implementation VLCHack

- (vlc_object_t *)vlc_object: (libvlc_media_player_t *)mp
{
    return VLC_OBJECT(mp);
}

@end
