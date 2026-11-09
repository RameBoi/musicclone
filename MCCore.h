#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define MCRed [UIColor colorWithRed:0.99 green:0.235 blue:0.267 alpha:1]
#define MCGrayText [UIColor colorWithWhite:0.56 alpha:1]
#define MCFill [UIColor colorWithWhite:0.95 alpha:1]

extern NSString *const MCPlayerChanged;
extern NSString *const MCPlayerTick;
extern NSString *const MCLibraryChanged;

UIFont *MCFont(CGFloat size, BOOL bold);
NSString *MCTime(NSTimeInterval t);
UIImage *MCScale(UIImage *img, CGFloat maxSide);
UIColor *MCAverageColor(UIImage *img);
UIImage *MCPlaceholder(void);
UIImage *MCIcon(NSString *kind, CGFloat size, UIColor *color);

@interface MCSong : NSObject
@property (nonatomic, copy) NSString *title, *artist, *album;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) MPMediaItem *item;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSInteger track;
@property (nonatomic, strong) NSDate *added;
- (void)loadArtwork:(void (^)(UIImage *img))done;
@end

@interface MCLibrary : NSObject
+ (instancetype)shared;
@property (nonatomic, strong) NSArray *songs;
- (void)reload;
// each group: @{@"name", @"artist", @"songs"}
- (NSArray *)albums;
- (NSArray *)artists;
- (NSArray *)recentSongs;
// each: @{@"name", @"artist"(curator), @"songs", @"user"(NSNumber BOOL)}
- (NSArray *)playlists;
- (void)createPlaylist:(NSString *)name withSong:(MCSong *)s;
- (void)addSong:(MCSong *)s toPlaylistNamed:(NSString *)name;
- (void)deletePlaylistNamed:(NSString *)name;
@end

@interface MCPlayer : NSObject
+ (instancetype)shared;
@property (nonatomic, readonly) MCSong *current;
@property (nonatomic, readonly) BOOL playing;
@property (nonatomic) BOOL shuffle;
@property (nonatomic) NSInteger repeatMode; // 0 off, 1 all, 2 one
@property (nonatomic, readonly) NSInteger index;
- (NSArray *)queue;
- (void)playSongs:(NSArray *)songs index:(NSInteger)i;
- (void)playNext:(MCSong *)s;
- (void)playLast:(MCSong *)s;
- (void)playQueueIndex:(NSInteger)i;
- (void)removeQueueIndex:(NSInteger)i;
- (void)toggle;
- (void)next;
- (void)prev;
- (void)seek:(NSTimeInterval)t;
- (NSTimeInterval)time;
- (NSTimeInterval)duration;
@end
