#import "MCCore.h"

NSString *const MCPlayerChanged = @"MCPlayerChanged";
NSString *const MCPlayerTick = @"MCPlayerTick";
NSString *const MCLibraryChanged = @"MCLibraryChanged";

#pragma mark - Helpers

UIFont *MCFont(CGFloat size, BOOL bold) {
    if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
        return [UIFont systemFontOfSize:size weight:bold ? 0.3 : 0.0];
    return bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
}

NSString *MCTime(NSTimeInterval t) {
    if (isnan(t) || t < 0) t = 0;
    NSInteger s = (NSInteger)(t + 0.5);
    return [NSString stringWithFormat:@"%ld:%02ld", (long)(s / 60), (long)(s % 60)];
}

UIImage *MCScale(UIImage *img, CGFloat maxSide) {
    if (!img) return nil;
    CGSize sz = img.size;
    CGFloat m = MAX(sz.width, sz.height);
    if (m <= maxSide) return img;
    CGFloat k = maxSide / m;
    CGSize ns = CGSizeMake(floor(sz.width * k), floor(sz.height * k));
    UIGraphicsBeginImageContextWithOptions(ns, NO, 1);
    [img drawInRect:CGRectMake(0, 0, ns.width, ns.height)];
    UIImage *r = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return r;
}

UIColor *MCAverageColor(UIImage *img) {
    if (!img || !img.CGImage) return [UIColor darkGrayColor];
    unsigned char px[4] = {0, 0, 0, 0};
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef c = CGBitmapContextCreate(px, 1, 1, 8, 4, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextSetInterpolationQuality(c, kCGInterpolationMedium);
    CGContextDrawImage(c, CGRectMake(0, 0, 1, 1), img.CGImage);
    CGContextRelease(c);
    CGColorSpaceRelease(cs);
    return [UIColor colorWithRed:px[0] / 255.0 green:px[1] / 255.0 blue:px[2] / 255.0 alpha:1];
}

UIImage *MCPlaceholder(void) {
    static UIImage *p;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(300, 300), YES, 1);
        [[UIColor colorWithWhite:0.9 alpha:1] setFill];
        UIRectFill(CGRectMake(0, 0, 300, 300));
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentCenter;
        [@"\u266A" drawInRect:CGRectMake(0, 70, 300, 200)
               withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:150],
                                NSForegroundColorAttributeName: [UIColor colorWithWhite:0.72 alpha:1],
                                NSParagraphStyleAttributeName: ps}];
        p = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return p;
}

UIImage *MCIcon(NSString *kind, CGFloat s, UIColor *col) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s, s), NO, 0);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGFloat lw = MAX(1.5, s / 12);
    [col setFill];
    [col setStroke];
    CGContextSetLineWidth(c, lw);
    CGContextSetLineCap(c, kCGLineCapRound);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    if ([kind isEqualToString:@"play"]) {
        CGContextMoveToPoint(c, s * .25, s * .12);
        CGContextAddLineToPoint(c, s * .88, s * .5);
        CGContextAddLineToPoint(c, s * .25, s * .88);
        CGContextFillPath(c);
    } else if ([kind isEqualToString:@"pause"]) {
        CGContextFillRect(c, CGRectMake(s * .2, s * .15, s * .2, s * .7));
        CGContextFillRect(c, CGRectMake(s * .6, s * .15, s * .2, s * .7));
    } else if ([kind isEqualToString:@"next"]) {
        CGContextMoveToPoint(c, s * .08, s * .2);
        CGContextAddLineToPoint(c, s * .7, s * .5);
        CGContextAddLineToPoint(c, s * .08, s * .8);
        CGContextFillPath(c);
        CGContextFillRect(c, CGRectMake(s * .74, s * .2, s * .14, s * .6));
    } else if ([kind isEqualToString:@"prev"]) {
        CGContextMoveToPoint(c, s * .92, s * .2);
        CGContextAddLineToPoint(c, s * .3, s * .5);
        CGContextAddLineToPoint(c, s * .92, s * .8);
        CGContextFillPath(c);
        CGContextFillRect(c, CGRectMake(s * .12, s * .2, s * .14, s * .6));
    } else if ([kind isEqualToString:@"search"]) {
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .12, s * .12, s * .55, s * .55));
        CGContextMoveToPoint(c, s * .6, s * .6);
        CGContextAddLineToPoint(c, s * .88, s * .88);
        CGContextStrokePath(c);
    } else if ([kind isEqualToString:@"albums"]) {
        UIBezierPath *r = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(s * .1, s * .1, s * .8, s * .8) cornerRadius:s * .14];
        r.lineWidth = lw;
        [r stroke];
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .32, s * .32, s * .36, s * .36));
    } else if ([kind isEqualToString:@"artists"]) {
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .34, s * .1, s * .32, s * .32));
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .16, s * .56, s * .68, s * .7));
    } else if ([kind isEqualToString:@"songs"]) {
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentCenter;
        [@"\u266A" drawInRect:CGRectMake(0, -s * .12, s, s * 1.3)
               withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:s * .95],
                                NSForegroundColorAttributeName: col,
                                NSParagraphStyleAttributeName: ps}];
    } else if ([kind isEqualToString:@"down"]) {
        CGContextMoveToPoint(c, s * .2, s * .38);
        CGContextAddLineToPoint(c, s * .5, s * .66);
        CGContextAddLineToPoint(c, s * .8, s * .38);
        CGContextStrokePath(c);
    } else if ([kind isEqualToString:@"home"]) {
        CGContextMoveToPoint(c, s * .1, s * .5);
        CGContextAddLineToPoint(c, s * .5, s * .12);
        CGContextAddLineToPoint(c, s * .9, s * .5);
        CGContextMoveToPoint(c, s * .22, s * .44);
        CGContextAddLineToPoint(c, s * .22, s * .88);
        CGContextAddLineToPoint(c, s * .78, s * .88);
        CGContextAddLineToPoint(c, s * .78, s * .44);
        CGContextStrokePath(c);
    } else if ([kind isEqualToString:@"browse"]) {
        for (int i = 0; i < 4; i++) {
            UIBezierPath *r = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(s * (i % 2 ? .54 : .12), s * (i / 2 ? .54 : .12), s * .34, s * .34) cornerRadius:s * .07];
            r.lineWidth = lw;
            [r stroke];
        }
    } else if ([kind isEqualToString:@"radio"]) {
        CGContextFillEllipseInRect(c, CGRectMake(s * .42, s * .42, s * .16, s * .16));
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .26, s * .26, s * .48, s * .48));
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .1, s * .1, s * .8, s * .8));
    } else if ([kind isEqualToString:@"recent"]) {
        CGContextStrokeEllipseInRect(c, CGRectMake(s * .1, s * .1, s * .8, s * .8));
        CGContextMoveToPoint(c, s * .5, s * .28);
        CGContextAddLineToPoint(c, s * .5, s * .5);
        CGContextAddLineToPoint(c, s * .68, s * .6);
        CGContextStrokePath(c);
    } else if ([kind isEqualToString:@"playlists"] || [kind isEqualToString:@"queue"]) {
        for (int i = 0; i < 3; i++) {
            CGContextMoveToPoint(c, s * .1, s * (.26 + i * .24));
            CGContextAddLineToPoint(c, s * (i == 2 ? .55 : .9), s * (.26 + i * .24));
        }
        CGContextStrokePath(c);
    } else if ([kind isEqualToString:@"close"]) {
        CGContextMoveToPoint(c, s * .28, s * .28);
        CGContextAddLineToPoint(c, s * .72, s * .72);
        CGContextMoveToPoint(c, s * .72, s * .28);
        CGContextAddLineToPoint(c, s * .28, s * .72);
        CGContextStrokePath(c);
    } else if ([kind isEqualToString:@"dot"]) {
        CGContextFillEllipseInRect(c, CGRectMake(0, 0, s, s));
    }
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - Song

static NSCache *MCArtCache(void) {
    static NSCache *c;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ c = [[NSCache alloc] init]; c.countLimit = 150; });
    return c;
}

static dispatch_queue_t MCArtQueue(void) {
    static dispatch_queue_t q;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ q = dispatch_queue_create("musicclone.art", DISPATCH_QUEUE_SERIAL); });
    return q;
}

@implementation MCSong

- (void)loadArtwork:(void (^)(UIImage *))done {
    NSString *key = self.url.absoluteString ?: @"";
    UIImage *hit = [MCArtCache() objectForKey:key];
    if (hit) { done(hit); return; }
    dispatch_async(MCArtQueue(), ^{
        UIImage *img = nil;
        if (self.item) {
            MPMediaItemArtwork *a = [self.item valueForProperty:MPMediaItemPropertyArtwork];
            img = [a imageWithSize:CGSizeMake(300, 300)];
        }
        if (!img) {
            AVURLAsset *as = [AVURLAsset URLAssetWithURL:self.url options:nil];
            for (AVMetadataItem *m in as.commonMetadata) {
                if ([m.commonKey isEqualToString:AVMetadataCommonKeyArtwork]) {
                    id v = m.value;
                    NSData *d = nil;
                    if ([v isKindOfClass:[NSData class]]) d = v;
                    else if ([v isKindOfClass:[NSDictionary class]]) d = v[@"data"];
                    if (d) img = [UIImage imageWithData:d];
                    break;
                }
            }
        }
        img = MCScale(img, 300) ?: MCPlaceholder();
        [MCArtCache() setObject:img forKey:key];
        dispatch_async(dispatch_get_main_queue(), ^{ done(img); });
    });
}

@end

#pragma mark - Library

static NSString *MCTag(AVURLAsset *a, NSString *ck) {
    for (AVMetadataItem *m in a.commonMetadata) {
        if ([m.commonKey isEqualToString:ck]) {
            id v = m.value;
            if ([v isKindOfClass:[NSString class]] && [(NSString *)v length]) return v;
        }
    }
    return nil;
}

// Folders scanned for loose audio files. Edit this list to add your own.
static NSArray *MCScanFolders(void) {
    NSMutableArray *f = [NSMutableArray arrayWithObjects:
        @"/var/mobile/Media/Music", @"/var/mobile/Music", @"/var/mobile/Documents", nil];
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (docs && ![f containsObject:docs]) [f addObject:docs];
    return f;
}

@implementation MCLibrary {
    BOOL _loading;
    NSDictionary *_byURL;
}

+ (instancetype)shared {
    static MCLibrary *l;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ l = [[MCLibrary alloc] init]; l.songs = @[]; });
    return l;
}

- (void)reload {
    if (_loading) return;
    _loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *all = [NSMutableArray array];

        // 1. Music synced through iTunes
        for (MPMediaItem *it in [MPMediaQuery songsQuery].items) {
            NSURL *u = [it valueForProperty:MPMediaItemPropertyAssetURL];
            if (!u) continue;
            MCSong *s = [[MCSong alloc] init];
            s.url = u;
            s.item = it;
            s.title = [it valueForProperty:MPMediaItemPropertyTitle] ?: @"Unknown";
            s.artist = [it valueForProperty:MPMediaItemPropertyArtist] ?: @"Unknown Artist";
            s.album = [it valueForProperty:MPMediaItemPropertyAlbumTitle] ?: @"Unknown Album";
            s.duration = [[it valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
            s.track = [[it valueForProperty:MPMediaItemPropertyAlbumTrackNumber] integerValue];
            s.added = [it valueForProperty:MPMediaItemPropertyDateAdded] ?: [NSDate distantPast];
            [all addObject:s];
        }

        // 2. Loose files
        NSSet *exts = [NSSet setWithObjects:@"mp3", @"m4a", @"aac", @"wav", @"aif", @"aiff", @"caf", nil];
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *dir in MCScanFolders()) {
            NSDirectoryEnumerator *en = [fm enumeratorAtPath:dir];
            for (NSString *rel in en) {
                if (![exts containsObject:[[rel pathExtension] lowercaseString]]) continue;
                @autoreleasepool {
                    NSString *path = [dir stringByAppendingPathComponent:rel];
                    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
                    MCSong *s = [[MCSong alloc] init];
                    s.url = a.URL;
                    s.title = MCTag(a, AVMetadataCommonKeyTitle) ?: [[rel lastPathComponent] stringByDeletingPathExtension];
                    s.artist = MCTag(a, AVMetadataCommonKeyArtist) ?: @"Unknown Artist";
                    s.album = MCTag(a, AVMetadataCommonKeyAlbumName) ?: @"Unknown Album";
                    double d = CMTimeGetSeconds(a.duration);
                    s.duration = isnan(d) ? 0 : d;
                    s.added = [[fm attributesOfItemAtPath:path error:nil] fileCreationDate] ?: [NSDate distantPast];
                    [all addObject:s];
                }
            }
        }

        [all sortUsingComparator:^NSComparisonResult(MCSong *x, MCSong *y) {
            return [x.title caseInsensitiveCompare:y.title];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.songs = all;
            NSMutableDictionary *by = [NSMutableDictionary dictionary];
            for (MCSong *s in all) by[s.url.absoluteString] = s;
            self->_byURL = by;
            self->_loading = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:MCLibraryChanged object:nil];
        });
    });
}

- (NSArray *)groupsByAlbum:(BOOL)byAlbum {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    NSMutableArray *order = [NSMutableArray array];
    for (MCSong *s in self.songs) {
        NSString *n = byAlbum ? s.album : s.artist;
        NSString *k = [n lowercaseString];
        NSMutableDictionary *g = d[k];
        if (!g) {
            g = [@{@"name": n, @"artist": s.artist, @"songs": [NSMutableArray array]} mutableCopy];
            d[k] = g;
            [order addObject:g];
        } else if (byAlbum && ![g[@"artist"] isEqualToString:s.artist]) {
            g[@"artist"] = @"Various Artists";
        }
        [g[@"songs"] addObject:s];
    }
    [order sortUsingComparator:^NSComparisonResult(NSDictionary *x, NSDictionary *y) {
        return [x[@"name"] caseInsensitiveCompare:y[@"name"]];
    }];
    if (byAlbum) {
        for (NSMutableDictionary *g in order) {
            [g[@"songs"] sortUsingComparator:^NSComparisonResult(MCSong *x, MCSong *y) {
                if (x.track > 0 && y.track > 0 && x.track != y.track) return x.track < y.track ? NSOrderedAscending : NSOrderedDescending;
                return [x.title caseInsensitiveCompare:y.title];
            }];
        }
    }
    return order;
}

- (NSArray *)albums { return [self groupsByAlbum:YES]; }
- (NSArray *)artists { return [self groupsByAlbum:NO]; }

- (NSArray *)recentSongs {
    return [self.songs sortedArrayUsingComparator:^NSComparisonResult(MCSong *x, MCSong *y) {
        return [y.added compare:x.added];
    }];
}

static NSString *const MCStoreKey = @"MCUserPlaylists";

- (NSArray *)store { return [[NSUserDefaults standardUserDefaults] arrayForKey:MCStoreKey] ?: @[]; }

- (void)saveStore:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:MCStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:MCLibraryChanged object:nil];
}

- (NSArray *)playlists {
    NSMutableArray *out = [NSMutableArray array];
    for (MPMediaPlaylist *pl in [MPMediaQuery playlistsQuery].collections) {
        NSMutableArray *songs = [NSMutableArray array];
        for (MPMediaItem *it in pl.items) {
            NSURL *u = [it valueForProperty:MPMediaItemPropertyAssetURL];
            MCSong *s = u ? _byURL[u.absoluteString] : nil;
            if (s) [songs addObject:s];
        }
        if (songs.count) [out addObject:@{@"name": [pl valueForProperty:MPMediaPlaylistPropertyName] ?: @"Playlist",
                                          @"artist": @"iTunes", @"songs": songs, @"user": @NO}];
    }
    for (NSDictionary *d in [self store]) {
        NSMutableArray *songs = [NSMutableArray array];
        for (NSString *u in d[@"urls"]) { MCSong *s = _byURL[u]; if (s) [songs addObject:s]; }
        [out addObject:@{@"name": d[@"name"], @"artist": @"You", @"songs": songs, @"user": @YES}];
    }
    return out;
}

- (void)createPlaylist:(NSString *)name withSong:(MCSong *)s {
    NSMutableArray *st = [[self store] mutableCopy];
    NSMutableArray *urls = [NSMutableArray array];
    if (s) [urls addObject:s.url.absoluteString];
    [st addObject:@{@"name": name, @"urls": urls}];
    [self saveStore:st];
}

- (void)addSong:(MCSong *)s toPlaylistNamed:(NSString *)name {
    NSMutableArray *st = [[self store] mutableCopy];
    for (NSUInteger i = 0; i < st.count; i++) {
        if ([st[i][@"name"] isEqualToString:name]) {
            NSMutableArray *urls = [st[i][@"urls"] mutableCopy];
            if (![urls containsObject:s.url.absoluteString]) [urls addObject:s.url.absoluteString];
            st[i] = @{@"name": name, @"urls": urls};
        }
    }
    [self saveStore:st];
}

- (void)deletePlaylistNamed:(NSString *)name {
    NSMutableArray *st = [[self store] mutableCopy];
    for (NSUInteger i = 0; i < st.count; i++) if ([st[i][@"name"] isEqualToString:name]) { [st removeObjectAtIndex:i]; break; }
    [self saveStore:st];
}

@end

#pragma mark - Player

@interface MCPlayer ()
@property (nonatomic, strong) AVPlayer *av;
@property (nonatomic, strong) NSMutableArray *q;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL playing;
@end

@implementation MCPlayer

+ (instancetype)shared {
    static MCPlayer *p;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ p = [[MCPlayer alloc] init]; });
    return p;
}

- (instancetype)init {
    self = [super init];
    _av = [[AVPlayer alloc] init];
    _q = [NSMutableArray array];
    [_av addPeriodicTimeObserverForInterval:CMTimeMake(1, 4) queue:dispatch_get_main_queue() usingBlock:^(CMTime t) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MCPlayerTick object:nil];
    }];
    MPRemoteCommandCenter *rc = [MPRemoteCommandCenter sharedCommandCenter];
    [rc.playCommand addTarget:self action:@selector(remotePlay:)];
    [rc.pauseCommand addTarget:self action:@selector(remotePause:)];
    [rc.togglePlayPauseCommand addTarget:self action:@selector(remoteToggle:)];
    [rc.nextTrackCommand addTarget:self action:@selector(remoteNext:)];
    [rc.previousTrackCommand addTarget:self action:@selector(remotePrev:)];
    return self;
}

- (MPRemoteCommandHandlerStatus)remotePlay:(MPRemoteCommandEvent *)e { if (!self.playing) [self toggle]; return MPRemoteCommandHandlerStatusSuccess; }
- (MPRemoteCommandHandlerStatus)remotePause:(MPRemoteCommandEvent *)e { if (self.playing) [self toggle]; return MPRemoteCommandHandlerStatusSuccess; }
- (MPRemoteCommandHandlerStatus)remoteToggle:(MPRemoteCommandEvent *)e { [self toggle]; return MPRemoteCommandHandlerStatusSuccess; }
- (MPRemoteCommandHandlerStatus)remoteNext:(MPRemoteCommandEvent *)e { [self next]; return MPRemoteCommandHandlerStatusSuccess; }
- (MPRemoteCommandHandlerStatus)remotePrev:(MPRemoteCommandEvent *)e { [self prev]; return MPRemoteCommandHandlerStatusSuccess; }

- (NSArray *)queue { return self.q; }

- (MCSong *)current {
    if (self.index < 0 || self.index >= (NSInteger)self.q.count) return nil;
    return self.q[self.index];
}

- (NSTimeInterval)time {
    double t = CMTimeGetSeconds(self.av.currentTime);
    return isnan(t) ? 0 : t;
}

- (NSTimeInterval)duration {
    if (self.current.duration > 0) return self.current.duration;
    double d = CMTimeGetSeconds(self.av.currentItem.duration);
    return isnan(d) ? 0 : d;
}

- (void)playSongs:(NSArray *)songs index:(NSInteger)i {
    if (!songs.count) return;
    self.q = [songs mutableCopy];
    [self startIndex:MIN(MAX(i, 0), (NSInteger)songs.count - 1)];
}

- (void)playNext:(MCSong *)s {
    if (!self.current) { [self playSongs:@[s] index:0]; return; }
    [self.q insertObject:s atIndex:self.index + 1];
    [self changed];
}

- (void)playLast:(MCSong *)s {
    if (!self.current) { [self playSongs:@[s] index:0]; return; }
    [self.q addObject:s];
    [self changed];
}

- (void)playQueueIndex:(NSInteger)i {
    if (i >= 0 && i < (NSInteger)self.q.count) [self startIndex:i];
}

- (void)removeQueueIndex:(NSInteger)i {
    if (i <= self.index || i >= (NSInteger)self.q.count) return;
    [self.q removeObjectAtIndex:i];
    [self changed];
}

- (void)startIndex:(NSInteger)i {
    self.index = i;
    AVPlayerItem *it = [AVPlayerItem playerItemWithURL:self.current.url];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ended:) name:AVPlayerItemDidPlayToEndTimeNotification object:it];
    [self.av replaceCurrentItemWithPlayerItem:it];
    [self.av play];
    self.playing = YES;
    [self changed];
}

- (void)ended:(NSNotification *)n {
    if (self.repeatMode == 2) {
        [self.av seekToTime:kCMTimeZero];
        [self.av play];
    } else {
        [self next];
    }
}

- (void)toggle {
    if (!self.current) return;
    if (self.playing) [self.av pause]; else [self.av play];
    self.playing = !self.playing;
    [self changed];
}

- (void)next {
    NSInteger n = (NSInteger)self.q.count;
    if (!n) return;
    NSInteger t;
    if (self.shuffle && n > 1) {
        do { t = (NSInteger)arc4random_uniform((uint32_t)n); } while (t == self.index);
    } else {
        t = self.index + 1;
    }
    if (t >= n) {
        if (self.repeatMode == 1) t = 0;
        else {
            [self.av seekToTime:kCMTimeZero];
            [self.av pause];
            self.playing = NO;
            [self changed];
            return;
        }
    }
    [self startIndex:t];
}

- (void)prev {
    if (!self.q.count) return;
    if ([self time] > 3 || self.index == 0) { [self seek:0]; return; }
    [self startIndex:self.index - 1];
}

- (void)seek:(NSTimeInterval)t {
    [self.av seekToTime:CMTimeMakeWithSeconds(t, 600)];
    [self updateInfo];
}

- (void)setShuffle:(BOOL)s { _shuffle = s; [[NSNotificationCenter defaultCenter] postNotificationName:MCPlayerChanged object:nil]; }
- (void)setRepeatMode:(NSInteger)r { _repeatMode = r; [[NSNotificationCenter defaultCenter] postNotificationName:MCPlayerChanged object:nil]; }

- (void)changed {
    [self updateInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:MCPlayerChanged object:nil];
}

- (void)updateInfo {
    MCSong *s = self.current;
    MPNowPlayingInfoCenter *c = [MPNowPlayingInfoCenter defaultCenter];
    if (!s) { c.nowPlayingInfo = nil; return; }
    c.nowPlayingInfo = @{MPMediaItemPropertyTitle: s.title ?: @"",
                         MPMediaItemPropertyArtist: s.artist ?: @"",
                         MPMediaItemPropertyAlbumTitle: s.album ?: @"",
                         MPMediaItemPropertyPlaybackDuration: @([self duration]),
                         MPNowPlayingInfoPropertyElapsedPlaybackTime: @([self time]),
                         MPNowPlayingInfoPropertyPlaybackRate: @(self.playing ? 1.0 : 0.0)};
    __weak MCPlayer *w = self;
    [s loadArtwork:^(UIImage *img) {
        if (w.current != s) return;
        NSMutableDictionary *m = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
        if (!m) return;
        m[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:img];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = m;
    }];
}

@end
