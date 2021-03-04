//
//  VLCHack.h
//  Eriri
//
//  Created by xjbeta on 3/4/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Eriri-Bridging-Header.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCHack : NSObject

- (vlc_object_t *)vlc_object: (libvlc_media_player_t *)mp;

@end

NS_ASSUME_NONNULL_END
