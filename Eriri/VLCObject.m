//
//  VLCObject.m
//  Eriri
//
//  Created by xjbeta on 3/4/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

#import "VLCObject.h"



@interface VLCObject ()
{
    vlc_object_t *vlc_object;
}
@end

@implementation VLCObject


- (id)initWithMediaPlayer: (libvlc_media_player_t *)mp
{
    self = [super init];
    vlc_object = VLC_OBJECT(mp);
    return(self);
}


- (id)initWithInputThread: (input_thread_t *)it
{
    self = [super init];
    vlc_object = VLC_OBJECT(it);
    return(self);
}

- (id)initWithAudioOutput: (audio_output_t *)ao
{
    self = [super init];
    vlc_object = VLC_OBJECT(ao);
    return(self);
}



- (vlc_object_t *)vlcObject
{
    return vlc_object_hold(vlc_object);
}

//UnsafeMutablePointer<input_thread_t>?


@end
