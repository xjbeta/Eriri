//
//  VLCObject.h
//  Eriri
//
//  Created by xjbeta on 3/4/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Eriri-Bridging-Header.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCObject : NSObject

- (id)initWithMediaPlayer: (libvlc_media_player_t *)mp;
- (id)initWithInputThread: (input_thread_t *)it;
- (id)initWithAudioOutput: (audio_output_t *)ao;



- (vlc_object_t *)vlcObject;

@end

NS_ASSUME_NONNULL_END
