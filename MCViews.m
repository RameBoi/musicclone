#import "MCViews.h"
#import "MCCore.h"

static const CGFloat kSideW = 260;

static UIViewController *MCDetailVC(NSDictionary *g, BOOL artist);
static void MCSongMenu(UIViewController *vc, MCSong *s, UIView *src);

#pragma mark - Alerts / menus

static void MCPromptNewPlaylist(UIViewController *vc, MCSong *s) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"New Playlist" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Playlist name"; }];
    __weak UIAlertController *wa = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        NSString *n = [wa.textFields.firstObject text];
        if (n.length) [[MCLibrary shared] createPlaylist:n withSong:s];
    }]];
    [vc presentViewController:a animated:YES completion:nil];
}

static void MCPickPlaylist(UIViewController *vc, MCSong *s, UIView *src) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Add to Playlist" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *p in [[MCLibrary shared] playlists]) {
        if (![p[@"user"] boolValue]) continue;
        NSString *name = p[@"name"];
        [a addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
            [[MCLibrary shared] addSong:s toPlaylistNamed:name];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"New Playlist\u2026" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { MCPromptNewPlaylist(vc, s); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = src;
    a.popoverPresentationController.sourceRect = src.bounds;
    [vc presentViewController:a animated:YES completion:nil];
}

static NSDictionary *MCFindGroup(NSArray *groups, NSString *name) {
    for (NSDictionary *g in groups) if ([g[@"name"] caseInsensitiveCompare:name] == NSOrderedSame) return g;
    return nil;
}

static void MCSongMenu(UIViewController *vc, MCSong *s, UIView *src) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:s.title message:s.artist preferredStyle:UIAlertControllerStyleActionSheet];
    [a addAction:[UIAlertAction actionWithTitle:@"Play Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { [[MCPlayer shared] playNext:s]; }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Play Last" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { [[MCPlayer shared] playLast:s]; }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Add to Playlist\u2026" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { MCPickPlaylist(vc, s, src); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Go to Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        NSDictionary *g = MCFindGroup([[MCLibrary shared] albums], s.album);
        if (g) [vc.navigationController pushViewController:MCDetailVC(g, NO) animated:YES];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Go to Artist" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        NSDictionary *g = MCFindGroup([[MCLibrary shared] artists], s.artist);
        if (g) [vc.navigationController pushViewController:MCDetailVC(g, YES) animated:YES];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = src;
    a.popoverPresentationController.sourceRect = src.bounds;
    [vc presentViewController:a animated:YES completion:nil];
}

#pragma mark - Row cell (songs, artists, queue)

@interface MCRowCell : UITableViewCell
@property (nonatomic, strong) UIImageView *art;
@property (nonatomic, strong) UILabel *trail;
@property (nonatomic, strong) MCSong *artSong;
@property (nonatomic) BOOL dark;
- (void)title:(NSString *)t sub:(NSString *)s trail:(NSString *)tr art:(MCSong *)a round:(BOOL)r hot:(BOOL)h;
@end

@implementation MCRowCell

- (instancetype)initWithStyle:(UITableViewCellStyle)st reuseIdentifier:(NSString *)rid {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid];
    _art = [[UIImageView alloc] init];
    _art.clipsToBounds = YES;
    _art.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_art];
    _trail = [[UILabel alloc] init];
    _trail.font = MCFont(14, NO);
    _trail.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_trail];
    self.textLabel.font = MCFont(16, NO);
    self.detailTextLabel.font = MCFont(14, NO);
    self.separatorInset = UIEdgeInsetsMake(0, 78, 0, 0);
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width, h = self.contentView.bounds.size.height;
    _art.frame = CGRectMake(16, (h - 48) / 2, 48, 48);
    _trail.frame = CGRectMake(w - 76, 0, 60, h);
    CGRect t = self.textLabel.frame;
    t.origin.x = 78;
    t.size.width = w - 78 - 84;
    self.textLabel.frame = t;
    CGRect d = self.detailTextLabel.frame;
    d.origin.x = 78;
    d.size.width = w - 78 - 84;
    self.detailTextLabel.frame = d;
}

- (void)title:(NSString *)t sub:(NSString *)s trail:(NSString *)tr art:(MCSong *)a round:(BOOL)r hot:(BOOL)h {
    self.backgroundColor = self.dark ? [UIColor clearColor] : [UIColor whiteColor];
    self.textLabel.text = t;
    self.detailTextLabel.text = s;
    self.textLabel.textColor = h ? MCRed : (self.dark ? [UIColor whiteColor] : [UIColor blackColor]);
    self.detailTextLabel.textColor = self.dark ? [UIColor colorWithWhite:1 alpha:0.6] : MCGrayText;
    _trail.textColor = self.dark ? [UIColor colorWithWhite:1 alpha:0.6] : MCGrayText;
    _trail.text = tr;
    _art.layer.cornerRadius = r ? 24 : 5;
    _art.image = MCPlaceholder();
    _artSong = a;
    __weak MCRowCell *w = self;
    [a loadArtwork:^(UIImage *img) { if (w.artSong == a) w.art.image = img; }];
}

@end

#pragma mark - Songs list (library, recent, search, album, artist, playlist)

@interface MCSongsVC : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allSongs;
@property (nonatomic, strong) NSArray *shown;
@property (nonatomic) BOOL searchMode, live, recent, headerRound;
@property (nonatomic, copy) NSString *headerTitle, *headerSub, *playlistName;
@property (nonatomic, strong) MCSong *headerSong;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) UISearchBar *bar;
@property (nonatomic, strong) UISegmentedControl *scope;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIImageView *art;
@property (nonatomic, strong) UILabel *titleL, *subL, *empty;
@property (nonatomic, strong) UIButton *playBtn, *shufBtn;
@end

@implementation MCSongsVC

- (void)loadView {
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 600, 600) style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.rowHeight = 64;
    self.view = self.table;
}

- (UIButton *)pill:(NSString *)t sel:(SEL)s {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:MCRed forState:UIControlStateNormal];
    b.titleLabel.font = MCFont(17, YES);
    b.backgroundColor = MCFill;
    b.layer.cornerRadius = 10;
    [b addTarget:self action:s forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (CGFloat)headerHeight { return self.searchMode ? 92 : (self.headerTitle ? 232 : 70); }

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.live) self.allSongs = self.recent ? [[MCLibrary shared] recentSongs] : [MCLibrary shared].songs;
    self.header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, [self headerHeight])];
    if (self.searchMode) {
        self.bar = [[UISearchBar alloc] init];
        self.bar.delegate = self;
        self.bar.placeholder = @"Search your library";
        self.bar.searchBarStyle = UISearchBarStyleMinimal;
        self.bar.tintColor = MCRed;
        self.scope = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Songs", @"Artists", @"Albums"]];
        self.scope.selectedSegmentIndex = 0;
        self.scope.tintColor = MCRed;
        [self.scope addTarget:self action:@selector(apply) forControlEvents:UIControlEventValueChanged];
        [self.header addSubview:self.bar];
        [self.header addSubview:self.scope];
    } else {
        if (self.headerTitle) {
            self.art = [[UIImageView alloc] init];
            self.art.clipsToBounds = YES;
            self.art.contentMode = UIViewContentModeScaleAspectFill;
            self.art.layer.cornerRadius = self.headerRound ? 95 : 10;
            self.art.image = MCPlaceholder();
            [self.header addSubview:self.art];
            [self.headerSong loadArtwork:^(UIImage *i) { self.art.image = i; }];
            self.titleL = [[UILabel alloc] init];
            self.titleL.font = MCFont(26, YES);
            self.titleL.numberOfLines = 2;
            self.titleL.text = self.headerTitle;
            self.subL = [[UILabel alloc] init];
            self.subL.font = MCFont(18, NO);
            self.subL.textColor = MCRed;
            self.subL.text = self.headerSub;
            [self.header addSubview:self.titleL];
            [self.header addSubview:self.subL];
        }
        self.playBtn = [self pill:@"Play" sel:@selector(playAll)];
        self.shufBtn = [self pill:@"Shuffle" sel:@selector(shuffleAll)];
        [self.header addSubview:self.playBtn];
        [self.header addSubview:self.shufBtn];
    }
    self.table.tableHeaderView = self.header;

    self.empty = [[UILabel alloc] init];
    self.empty.numberOfLines = 0;
    self.empty.textAlignment = NSTextAlignmentCenter;
    self.empty.textColor = MCGrayText;
    self.empty.font = MCFont(16, NO);
    self.empty.text = @"No songs here yet.";

    if (self.playlistName) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deletePlaylist)];
    }
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.table addGestureRecognizer:lp];
    [self apply];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(playerChanged) name:MCPlayerChanged object:nil];
    [nc addObserver:self selector:@selector(libChanged) name:MCLibraryChanged object:nil];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.table.bounds.size.width;
    CGRect hf = self.header.frame;
    if (hf.size.width != w) { hf.size.width = w; self.header.frame = hf; self.table.tableHeaderView = self.header; }
    if (self.searchMode) {
        self.bar.frame = CGRectMake(0, 0, w, 44);
        self.scope.frame = CGRectMake(16, 50, w - 32, 30);
    } else if (self.headerTitle) {
        self.art.frame = CGRectMake(20, 20, 190, 190);
        CGFloat x = 232, cw = w - x - 20;
        self.titleL.frame = CGRectMake(x, 28, cw, 64);
        self.subL.frame = CGRectMake(x, 96, cw, 24);
        self.playBtn.frame = CGRectMake(x, 150, (cw - 12) / 2, 46);
        self.shufBtn.frame = CGRectMake(x + (cw - 12) / 2 + 12, 150, (cw - 12) / 2, 46);
    } else {
        self.playBtn.frame = CGRectMake(16, 12, (w - 48) / 2, 46);
        self.shufBtn.frame = CGRectMake(w / 2 + 8, 12, (w - 48) / 2, 46);
    }
    self.empty.frame = CGRectMake(20, 260, w - 40, 100);
}

- (void)libChanged {
    if (self.live) { self.allSongs = self.recent ? [[MCLibrary shared] recentSongs] : [MCLibrary shared].songs; [self apply]; }
}

- (void)playerChanged { [self.table reloadData]; }

- (void)apply {
    NSString *q = self.bar.text;
    if (q.length == 0) {
        self.shown = self.allSongs ?: @[];
    } else {
        NSInteger sc = self.scope.selectedSegmentIndex;
        NSMutableArray *r = [NSMutableArray array];
        for (MCSong *s in self.allSongs) {
            BOOL t = [s.title rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL a = [s.artist rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL b = [s.album rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound;
            if ((sc == 0 && (t || a || b)) || (sc == 1 && t) || (sc == 2 && a) || (sc == 3 && b)) [r addObject:s];
        }
        self.shown = r;
    }
    self.table.backgroundView = (self.shown.count == 0 && q.length == 0) ? self.empty : nil;
    [self.table reloadData];
}

- (void)searchBar:(UISearchBar *)b textDidChange:(NSString *)t { [self apply]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)b { [b resignFirstResponder]; }

- (void)playAll { [[MCPlayer shared] playSongs:self.shown index:0]; }

- (void)shuffleAll {
    if (!self.shown.count) return;
    [MCPlayer shared].shuffle = YES;
    [[MCPlayer shared] playSongs:self.shown index:(NSInteger)arc4random_uniform((uint32_t)self.shown.count)];
}

- (void)deletePlaylist {
    [[MCLibrary shared] deletePlaylistNamed:self.playlistName];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)longPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    NSIndexPath *ip = [self.table indexPathForRowAtPoint:[g locationInView:self.table]];
    if (!ip) return;
    UITableViewCell *c = [self.table cellForRowAtIndexPath:ip];
    MCSongMenu(self, self.shown[ip.row], c);
}

#pragma mark Table

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return (NSInteger)self.shown.count; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    MCRowCell *c = [tv dequeueReusableCellWithIdentifier:@"s"];
    if (!c) c = [[MCRowCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"s"];
    MCSong *s = self.shown[ip.row];
    [c title:s.title sub:[NSString stringWithFormat:@"%@ \u2014 %@", s.artist, s.album]
       trail:MCTime(s.duration) art:s round:NO hot:([MCPlayer shared].current == s)];
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self.bar resignFirstResponder];
    [[MCPlayer shared] playSongs:self.shown index:ip.row];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)es forRowAtIndexPath:(NSIndexPath *)ip {}

- (NSArray *)tableView:(UITableView *)tv editActionsForRowAtIndexPath:(NSIndexPath *)ip {
    MCSong *s = self.shown[ip.row];
    UITableViewRowAction *last = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Play Last" handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [[MCPlayer shared] playLast:s];
        [tv setEditing:NO animated:YES];
    }];
    last.backgroundColor = [UIColor colorWithRed:1.0 green:0.58 blue:0.0 alpha:1];
    UITableViewRowAction *next = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Play Next" handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [[MCPlayer shared] playNext:s];
        [tv setEditing:NO animated:YES];
    }];
    next.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1];
    return @[last, next];
}

@end

static UIViewController *MCDetailVC(NSDictionary *g, BOOL artist) {
    MCSongsVC *v = [[MCSongsVC alloc] init];
    NSArray *songs = g[@"songs"];
    v.allSongs = songs;
    v.title = g[@"name"];
    v.headerTitle = g[@"name"];
    v.headerSub = artist ? [NSString stringWithFormat:@"%lu song%@", (unsigned long)songs.count, songs.count == 1 ? @"" : @"s"] : g[@"artist"];
    v.headerSong = songs.firstObject;
    v.headerRound = artist;
    if ([g[@"user"] boolValue]) v.playlistName = g[@"name"];
    return v;
}

#pragma mark - Card cell (albums, playlists, artists)

@interface MCCardCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *art;
@property (nonatomic, strong) UILabel *name, *sub;
@property (nonatomic, strong) MCSong *artSong;
@property (nonatomic) BOOL round;
- (void)title:(NSString *)t sub:(NSString *)s art:(MCSong *)a round:(BOOL)r;
@end

@implementation MCCardCell

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    _art = [[UIImageView alloc] init];
    _art.clipsToBounds = YES;
    _art.layer.borderWidth = 0.5;
    _art.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
    _art.contentMode = UIViewContentModeScaleAspectFill;
    _name = [[UILabel alloc] init];
    _name.font = MCFont(16.5, NO);
    _sub = [[UILabel alloc] init];
    _sub.font = MCFont(16.5, NO);
    _sub.textColor = MCGrayText;
    [self.contentView addSubview:_art];
    [self.contentView addSubview:_name];
    [self.contentView addSubview:_sub];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    _art.frame = CGRectMake(0, 0, w, w);
    _art.layer.cornerRadius = self.round ? w / 2 : 7.5;
    CGFloat a = self.round ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    _name.textAlignment = (NSTextAlignment)a;
    _sub.textAlignment = (NSTextAlignment)a;
    _name.frame = CGRectMake(0, w + 8, w, 20);
    _sub.frame = CGRectMake(0, w + 29, w, 20);
}

- (void)title:(NSString *)t sub:(NSString *)s art:(MCSong *)a round:(BOOL)r {
    _round = r;
    _name.text = t;
    _sub.text = s;
    _art.image = MCPlaceholder();
    _artSong = a;
    [self setNeedsLayout];
    __weak MCCardCell *w = self;
    [a loadArtwork:^(UIImage *img) { if (w.artSong == a) w.art.image = img; }];
}

@end

#pragma mark - Grid (Albums / Playlists)

@interface MCGridVC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic) NSInteger kind; // 0 albums, 1 playlists
@property (nonatomic, strong) UICollectionView *cv;
@property (nonatomic, strong) NSArray *groups;
@end

@implementation MCGridVC

- (void)loadView {
    UICollectionViewFlowLayout *l = [[UICollectionViewFlowLayout alloc] init];
    l.sectionInset = UIEdgeInsetsMake(16, 20, 20, 20);
    l.minimumInteritemSpacing = 20;
    l.minimumLineSpacing = 14;
    self.cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 600, 600) collectionViewLayout:l];
    self.cv.backgroundColor = [UIColor whiteColor];
    self.cv.dataSource = self;
    self.cv.delegate = self;
    self.cv.alwaysBounceVertical = YES;
    [self.cv registerClass:[MCCardCell class] forCellWithReuseIdentifier:@"c"];
    self.view = self.cv;
}

- (NSArray *)load { return self.kind == 1 ? [[MCLibrary shared] playlists] : [[MCLibrary shared] albums]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.groups = [self load];
    if (self.kind == 1) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPlaylist)];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libChanged) name:MCLibraryChanged object:nil];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)libChanged { self.groups = [self load]; [self.cv reloadData]; }
- (void)addPlaylist { MCPromptNewPlaylist(self, nil); }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.cv.bounds.size.width;
    NSInteger cols = MAX(2, (NSInteger)floor((w - 20) / 190));
    CGFloat iw = floor((w - 20 * (cols + 1)) / cols);
    UICollectionViewFlowLayout *l = (UICollectionViewFlowLayout *)self.cv.collectionViewLayout;
    CGSize ns = CGSizeMake(iw, iw + 54);
    if (!CGSizeEqualToSize(l.itemSize, ns)) { l.itemSize = ns; [l invalidateLayout]; }
}

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)s { return (NSInteger)self.groups.count; }

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    MCCardCell *c = [cv dequeueReusableCellWithReuseIdentifier:@"c" forIndexPath:ip];
    NSDictionary *g = self.groups[ip.item];
    [c title:g[@"name"] sub:g[@"artist"] art:[g[@"songs"] firstObject] round:NO];
    return c;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    [self.navigationController pushViewController:MCDetailVC(self.groups[ip.item], NO) animated:YES];
}

@end

#pragma mark - Artists list

@interface MCArtistsVC : UITableViewController
@property (nonatomic, strong) NSArray *groups;
@end

@implementation MCArtistsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 64;
    self.groups = [[MCLibrary shared] artists];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libChanged) name:MCLibraryChanged object:nil];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)libChanged { self.groups = [[MCLibrary shared] artists]; [self.tableView reloadData]; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return (NSInteger)self.groups.count; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    MCRowCell *c = [tv dequeueReusableCellWithIdentifier:@"r"];
    if (!c) c = [[MCRowCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"r"];
    NSDictionary *g = self.groups[ip.row];
    NSArray *songs = g[@"songs"];
    [c title:g[@"name"] sub:[NSString stringWithFormat:@"%lu song%@", (unsigned long)songs.count, songs.count == 1 ? @"" : @"s"]
       trail:nil art:songs.firstObject round:YES hot:NO];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self.navigationController pushViewController:MCDetailVC(self.groups[ip.row], YES) animated:YES];
}

@end

#pragma mark - Home / Browse / Radio (shelves)

@interface MCShelfCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *cv;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, copy) void (^pick)(NSDictionary *item);
@end

@implementation MCShelfCell

- (instancetype)initWithStyle:(UITableViewCellStyle)st reuseIdentifier:(NSString *)rid {
    self = [super initWithStyle:st reuseIdentifier:rid];
    UICollectionViewFlowLayout *l = [[UICollectionViewFlowLayout alloc] init];
    l.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    l.itemSize = CGSizeMake(170, 224);
    l.minimumLineSpacing = 18;
    l.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:l];
    _cv.backgroundColor = [UIColor whiteColor];
    _cv.dataSource = self;
    _cv.delegate = self;
    _cv.showsHorizontalScrollIndicator = NO;
    [_cv registerClass:[MCCardCell class] forCellWithReuseIdentifier:@"c"];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:_cv];
    return self;
}

- (void)layoutSubviews { [super layoutSubviews]; _cv.frame = self.contentView.bounds; }

- (void)setItems:(NSArray *)items { _items = items; [_cv reloadData]; }

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)s { return (NSInteger)_items.count; }

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    MCCardCell *c = [cv dequeueReusableCellWithReuseIdentifier:@"c" forIndexPath:ip];
    NSDictionary *it = _items[ip.item];
    id a = it[@"art"];
    [c title:it[@"title"] sub:it[@"sub"] art:[a isKindOfClass:[MCSong class]] ? a : nil round:[it[@"round"] boolValue]];
    return c;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    if (self.pick) self.pick(_items[ip.item]);
}

@end

@interface MCHomeVC : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSInteger mode; // 0 home, 1 browse, 2 radio
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSArray *sections; // @{@"title", @"items"}
@end

@implementation MCHomeVC

- (NSArray *)cardsFrom:(NSArray *)groups artist:(BOOL)a station:(BOOL)st {
    NSMutableArray *o = [NSMutableArray array];
    for (NSDictionary *g in groups) {
        NSArray *songs = g[@"songs"];
        NSString *sub = st ? @"Station" : (a ? [NSString stringWithFormat:@"%lu songs", (unsigned long)songs.count] : g[@"artist"]);
        [o addObject:@{@"title": st ? [g[@"name"] stringByAppendingString:@" Radio"] : g[@"name"], @"sub": sub,
                       @"art": songs.firstObject ?: (id)[NSNull null], @"round": @(a || st), @"group": g,
                       @"artist": @(a), @"station": @(st), @"songs": songs}];
    }
    return o;
}

- (void)build {
    MCLibrary *lib = [MCLibrary shared];
    NSMutableArray *s = [NSMutableArray array];
    NSArray *albums = [lib albums], *artists = [lib artists];
    // newest albums first
    NSArray *recentAlbums = [albums sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *x, NSDictionary *y) {
        NSDate *dx = [NSDate distantPast], *dy = [NSDate distantPast];
        for (MCSong *a in x[@"songs"]) if ([a.added compare:dx] == NSOrderedDescending) dx = a.added;
        for (MCSong *b in y[@"songs"]) if ([b.added compare:dy] == NSOrderedDescending) dy = b.added;
        return [dy compare:dx];
    }];
    NSMutableArray *shuffled = [albums mutableCopy];
    for (NSInteger i = (NSInteger)shuffled.count - 1; i > 0; i--) [shuffled exchangeObjectAtIndex:i withObjectAtIndex:(NSInteger)arc4random_uniform((uint32_t)i + 1)];
    NSDictionary *all = lib.songs.count ? @{@"title": @"Library Shuffle", @"sub": @"All songs", @"art": lib.songs.firstObject, @"round": @NO,
                                           @"station": @YES, @"songs": lib.songs} : nil;
    if (self.mode == 0) {
        [s addObject:@{@"title": @"Recently Added", @"items": [self cardsFrom:[recentAlbums subarrayWithRange:NSMakeRange(0, MIN(20, recentAlbums.count))] artist:NO station:NO]}];
        [s addObject:@{@"title": @"Albums", @"items": [self cardsFrom:albums artist:NO station:NO]}];
        [s addObject:@{@"title": @"Artists", @"items": [self cardsFrom:artists artist:YES station:NO]}];
        NSMutableArray *pl = [NSMutableArray array];
        for (NSDictionary *p in [lib playlists]) [pl addObjectsFromArray:[self cardsFrom:@[p] artist:NO station:NO]];
        [s addObject:@{@"title": @"Playlists", @"items": pl}];
    } else if (self.mode == 1) {
        [s addObject:@{@"title": @"Featured Albums", @"items": [self cardsFrom:[shuffled subarrayWithRange:NSMakeRange(0, MIN(12, shuffled.count))] artist:NO station:NO]}];
        [s addObject:@{@"title": @"Artists To Explore", @"items": [self cardsFrom:artists artist:YES station:NO]}];
    } else {
        [s addObject:@{@"title": @"Library Radio", @"items": all ? @[all] : @[]}];
        [s addObject:@{@"title": @"Artist Stations", @"items": [self cardsFrom:artists artist:NO station:YES]}];
    }
    NSMutableArray *keep = [NSMutableArray array];
    for (NSDictionary *sec in s) if ([sec[@"items"] count]) [keep addObject:sec];
    self.sections = keep;
    [self.table reloadData];
}

- (void)loadView {
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 600, 600) style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.rowHeight = 240;
    self.view = self.table;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self build];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(build) name:MCLibraryChanged object:nil];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return (NSInteger)self.sections.count; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return 1; }
- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s { return 44; }

- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    v.backgroundColor = [UIColor whiteColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 500, 30)];
    l.font = MCFont(22, YES);
    l.text = self.sections[s][@"title"];
    [v addSubview:l];
    return v;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    MCShelfCell *c = [tv dequeueReusableCellWithIdentifier:@"shelf"];
    if (!c) c = [[MCShelfCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"shelf"];
    c.items = self.sections[ip.section][@"items"];
    __weak MCHomeVC *w = self;
    c.pick = ^(NSDictionary *it) {
        if ([it[@"station"] boolValue]) {
            NSArray *songs = it[@"songs"];
            if (!songs.count) return;
            [MCPlayer shared].shuffle = YES;
            [[MCPlayer shared] playSongs:songs index:(NSInteger)arc4random_uniform((uint32_t)songs.count)];
        } else {
            [w.navigationController pushViewController:MCDetailVC(it[@"group"], [it[@"artist"] boolValue]) animated:YES];
        }
    };
    return c;
}

@end

#pragma mark - Now Playing (full screen)

@interface MCNowPlayingVC : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@implementation MCNowPlayingVC {
    UIView *_artWrap;
    UIImageView *_art;
    UILabel *_title, *_artist, *_elapsed, *_remain, *_upHead;
    UISlider *_slider;
    UIButton *_close, *_prev, *_play, *_next, *_shuf, *_rep, *_queueBtn;
    UITableView *_queue;
    MPVolumeView *_vol;
    BOOL _scrub, _showQueue;
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (UILabel *)label:(CGFloat)size bold:(BOOL)b align:(NSTextAlignment)a alpha:(CGFloat)al {
    UILabel *l = [[UILabel alloc] init];
    l.font = MCFont(size, b);
    l.textColor = [UIColor colorWithWhite:1 alpha:al];
    l.textAlignment = a;
    [self.view addSubview:l];
    return l;
}

- (UIButton *)btn:(NSString *)icon size:(CGFloat)s sel:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setImage:MCIcon(icon, s, [UIColor whiteColor]) forState:UIControlStateNormal];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
    return b;
}

- (UIButton *)textBtn:(NSString *)t sel:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:t forState:UIControlStateNormal];
    b.titleLabel.font = MCFont(15, YES);
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
    return b;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor darkGrayColor];
    _artWrap = [[UIView alloc] init];
    _artWrap.layer.shadowColor = [UIColor blackColor].CGColor;
    _artWrap.layer.shadowOpacity = 0.45;
    _artWrap.layer.shadowRadius = 24;
    _artWrap.layer.shadowOffset = CGSizeMake(0, 12);
    [self.view addSubview:_artWrap];
    _art = [[UIImageView alloc] init];
    _art.clipsToBounds = YES;
    _art.layer.cornerRadius = 12;
    _art.contentMode = UIViewContentModeScaleAspectFill;
    [_artWrap addSubview:_art];

    _queue = [[UITableView alloc] init];
    _queue.dataSource = self;
    _queue.delegate = self;
    _queue.backgroundColor = [UIColor clearColor];
    _queue.rowHeight = 60;
    _queue.separatorColor = [UIColor colorWithWhite:1 alpha:0.15];
    _queue.hidden = YES;
    [self.view addSubview:_queue];

    _title = [self label:24 bold:YES align:NSTextAlignmentCenter alpha:1];
    _artist = [self label:19 bold:NO align:NSTextAlignmentCenter alpha:0.7];
    _elapsed = [self label:12 bold:NO align:NSTextAlignmentLeft alpha:0.6];
    _remain = [self label:12 bold:NO align:NSTextAlignmentRight alpha:0.6];

    _slider = [[UISlider alloc] init];
    _slider.minimumTrackTintColor = [UIColor whiteColor];
    _slider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.3];
    UIImage *thumb = MCIcon(@"dot", 14, [UIColor whiteColor]);
    [_slider setThumbImage:thumb forState:UIControlStateNormal];
    [_slider setThumbImage:thumb forState:UIControlStateHighlighted];
    [_slider addTarget:self action:@selector(scrubStart) forControlEvents:UIControlEventTouchDown];
    [_slider addTarget:self action:@selector(scrubMove) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(scrubEnd) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.view addSubview:_slider];

    _close = [self btn:@"down" size:30 sel:@selector(closeMe)];
    _queueBtn = [self btn:@"queue" size:28 sel:@selector(toggleQueue)];
    _prev = [self btn:@"prev" size:34 sel:@selector(doPrev)];
    _play = [self btn:@"play" size:46 sel:@selector(doToggle)];
    _next = [self btn:@"next" size:34 sel:@selector(doNext)];
    _shuf = [self textBtn:@"Shuffle" sel:@selector(doShuffle)];
    _rep = [self textBtn:@"Repeat" sel:@selector(doRepeat)];

    _vol = [[MPVolumeView alloc] init];
    _vol.showsRouteButton = NO;
    [self.view addSubview:_vol];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(refresh) name:MCPlayerChanged object:nil];
    [nc addObserver:self selector:@selector(tick) name:MCPlayerTick object:nil];
    [self refresh];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat colW = MIN(520, W - 60), x = (W - colW) / 2;
    _close.frame = CGRectMake(14, 24, 50, 50);
    _queueBtn.frame = CGRectMake(W - 64, 24, 50, 50);
    CGFloat s = MAX(150, MIN(colW, H - 470));
    CGFloat y = 80;
    _artWrap.bounds = CGRectMake(0, 0, s, s);
    _artWrap.center = CGPointMake(W / 2, y + s / 2);
    _art.frame = _artWrap.bounds;
    _queue.frame = CGRectMake(x, y, colW, s + 60);
    y += s + 26;
    _title.frame = CGRectMake(x, y, colW, 30);
    _artist.frame = CGRectMake(x, y + 32, colW, 24);
    y += 70;
    _slider.frame = CGRectMake(x, y, colW, 30);
    _elapsed.frame = CGRectMake(x, y + 30, 80, 16);
    _remain.frame = CGRectMake(x + colW - 80, y + 30, 80, 16);
    y += 58;
    _prev.frame = CGRectMake(W / 2 - 130, y, 64, 64);
    _play.frame = CGRectMake(W / 2 - 32, y, 64, 64);
    _next.frame = CGRectMake(W / 2 + 66, y, 64, 64);
    y += 70;
    _vol.frame = CGRectMake(x + 20, y, colW - 40, 30);
    y += 38;
    _shuf.frame = CGRectMake(W / 2 - 150, y, 130, 36);
    _rep.frame = CGRectMake(W / 2 + 20, y, 130, 36);
}

- (void)refresh {
    MCPlayer *p = [MCPlayer shared];
    MCSong *s = p.current;
    _title.text = s.title ?: @"Not Playing";
    _artist.text = s.artist;
    [_play setImage:MCIcon(p.playing ? @"pause" : @"play", 46, [UIColor whiteColor]) forState:UIControlStateNormal];
    _shuf.alpha = p.shuffle ? 1.0 : 0.45;
    NSArray *rt = @[@"Repeat", @"Repeat All", @"Repeat One"];
    [_rep setTitle:rt[MIN(MAX(p.repeatMode, 0), 2)] forState:UIControlStateNormal];
    _rep.alpha = p.repeatMode ? 1.0 : 0.45;
    _queueBtn.alpha = _showQueue ? 1.0 : 0.6;
    [UIView animateWithDuration:0.3 animations:^{
        self->_artWrap.transform = p.playing ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.86, 0.86);
    }];
    if (s) {
        [s loadArtwork:^(UIImage *img) {
            if ([MCPlayer shared].current != s) return;
            self->_art.image = img;
            UIColor *c = MCAverageColor(img);
            CGFloat r, g, b, a;
            [c getRed:&r green:&g blue:&b alpha:&a];
            UIColor *dark = [UIColor colorWithRed:r * 0.55 green:g * 0.55 blue:b * 0.55 alpha:1];
            [UIView animateWithDuration:0.35 animations:^{ self.view.backgroundColor = dark; }];
        }];
    } else {
        _art.image = MCPlaceholder();
    }
    [_queue reloadData];
    [self tick];
}

- (void)tick {
    MCPlayer *p = [MCPlayer shared];
    NSTimeInterval d = [p duration], t = [p time];
    if (!_scrub) {
        _slider.value = d > 0 ? (float)(t / d) : 0;
        _elapsed.text = MCTime(t);
        _remain.text = [@"-" stringByAppendingString:MCTime(MAX(0, d - t))];
    }
}

- (void)scrubStart { _scrub = YES; }
- (void)scrubMove {
    NSTimeInterval d = [[MCPlayer shared] duration], t = _slider.value * d;
    _elapsed.text = MCTime(t);
    _remain.text = [@"-" stringByAppendingString:MCTime(MAX(0, d - t))];
}
- (void)scrubEnd {
    [[MCPlayer shared] seek:_slider.value * [[MCPlayer shared] duration]];
    _scrub = NO;
}

- (void)toggleQueue {
    _showQueue = !_showQueue;
    _queue.hidden = !_showQueue;
    _artWrap.hidden = _showQueue;
    _title.hidden = _showQueue;
    _artist.hidden = _showQueue;
    _queueBtn.alpha = _showQueue ? 1.0 : 0.6;
    [_queue reloadData];
}

- (void)closeMe { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)doPrev { [[MCPlayer shared] prev]; }
- (void)doNext { [[MCPlayer shared] next]; }
- (void)doToggle { [[MCPlayer shared] toggle]; }
- (void)doShuffle { [MCPlayer shared].shuffle = ![MCPlayer shared].shuffle; }
- (void)doRepeat { [MCPlayer shared].repeatMode = ([MCPlayer shared].repeatMode + 1) % 3; }

#pragma mark Up Next table

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    MCPlayer *p = [MCPlayer shared];
    return MAX(0, (NSInteger)p.queue.count - p.index - 1);
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return @"Playing Next"; }

- (void)tableView:(UITableView *)tv willDisplayHeaderView:(UIView *)v forSection:(NSInteger)s {
    if ([v isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *h = (UITableViewHeaderFooterView *)v;
        h.textLabel.textColor = [UIColor whiteColor];
        h.textLabel.font = MCFont(18, YES);
        h.contentView.backgroundColor = [UIColor clearColor];
        h.backgroundView.backgroundColor = [UIColor clearColor];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    MCRowCell *c = [tv dequeueReusableCellWithIdentifier:@"q"];
    if (!c) { c = [[MCRowCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"q"]; c.dark = YES; }
    MCPlayer *p = [MCPlayer shared];
    MCSong *s = p.queue[p.index + 1 + ip.row];
    [c title:s.title sub:s.artist trail:MCTime(s.duration) art:s round:NO hot:NO];
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [[MCPlayer shared] playQueueIndex:[MCPlayer shared].index + 1 + ip.row];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)es forRowAtIndexPath:(NSIndexPath *)ip {
    if (es == UITableViewCellEditingStyleDelete) [[MCPlayer shared] removeQueueIndex:[MCPlayer shared].index + 1 + ip.row];
}

@end

#pragma mark - Root (sidebar + top player bar + content)

@implementation MCRootVC {
    UITableView *_side;
    UIView *_bar, *_cap, *_prog, *_dim, *_pop;
    UINavigationController *_nav;
    UIButton *_prev, *_play, *_next;
    UIImageView *_capArt;
    UILabel *_capTitle, *_capSub;
    NSArray *_items, *_sectionTitles;
    BOOL _popupShown;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _items = @[@[@{@"t": @"Search", @"i": @"search", @"k": @"search"}],
               @[@{@"t": @"Home", @"i": @"home", @"k": @"home"},
                 @{@"t": @"Browse", @"i": @"browse", @"k": @"browse"},
                 @{@"t": @"Radio", @"i": @"radio", @"k": @"radio"}],
               @[@{@"t": @"Recently Added", @"i": @"recent", @"k": @"recent"},
                 @{@"t": @"Playlists", @"i": @"playlists", @"k": @"playlists"},
                 @{@"t": @"Artists", @"i": @"artists", @"k": @"artists"},
                 @{@"t": @"Albums", @"i": @"albums", @"k": @"albums"},
                 @{@"t": @"Songs", @"i": @"songs", @"k": @"songs"}]];
    _sectionTitles = @[@"", @"", @"Library"];

    _nav = [[UINavigationController alloc] init];
    _nav.navigationBar.tintColor = MCRed;
    [self addChildViewController:_nav];
    [self.view addSubview:_nav.view];
    [_nav didMoveToParentViewController:self];

    _bar = [[UIView alloc] init];
    _bar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_bar];
    _prev = [self barBtn:@"prev" sel:@selector(doPrev)];
    _play = [self barBtn:@"play" sel:@selector(doToggle)];
    _next = [self barBtn:@"next" sel:@selector(doNext)];

    _cap = [[UIView alloc] init];
    _cap.backgroundColor = MCFill;
    _cap.layer.cornerRadius = 10;
    _cap.clipsToBounds = YES;
    [_cap addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openNowPlaying)]];
    [_bar addSubview:_cap];
    _capArt = [[UIImageView alloc] init];
    _capArt.clipsToBounds = YES;
    _capArt.layer.cornerRadius = 5;
    _capArt.contentMode = UIViewContentModeScaleAspectFill;
    [_cap addSubview:_capArt];
    _capTitle = [[UILabel alloc] init];
    _capTitle.font = MCFont(13, YES);
    _capTitle.textAlignment = NSTextAlignmentCenter;
    [_cap addSubview:_capTitle];
    _capSub = [[UILabel alloc] init];
    _capSub.font = MCFont(12, NO);
    _capSub.textColor = MCGrayText;
    _capSub.textAlignment = NSTextAlignmentCenter;
    [_cap addSubview:_capSub];
    _prog = [[UIView alloc] init];
    _prog.backgroundColor = MCRed;
    [_cap addSubview:_prog];

    _side = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _side.dataSource = self;
    _side.delegate = self;
    _side.backgroundColor = [UIColor colorWithWhite:0.965 alpha:1];
    _side.separatorStyle = UITableViewCellSeparatorStyleNone;
    _side.rowHeight = 44;
    [self.view addSubview:_side];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(sync) name:MCPlayerChanged object:nil];
    [nc addObserver:self selector:@selector(tickBar) name:MCPlayerTick object:nil];
    [nc addObserver:self selector:@selector(libChanged) name:MCLibraryChanged object:nil];

    NSIndexPath *first = [NSIndexPath indexPathForRow:0 inSection:1];
    [_side selectRowAtIndexPath:first animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self showItem:first];
    [self sync];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (UIButton *)barBtn:(NSString *)icon sel:(SEL)s {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setImage:MCIcon(icon, 26, [UIColor blackColor]) forState:UIControlStateNormal];
    [b addTarget:self action:s forControlEvents:UIControlEventTouchUpInside];
    [_bar addSubview:b];
    return b;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat cw = W - kSideW;
    _side.frame = CGRectMake(0, 24, kSideW, H - 24);
    _bar.frame = CGRectMake(kSideW, 20, cw, 52);
    _nav.view.frame = CGRectMake(kSideW, 72, cw, H - 72);
    _prev.frame = CGRectMake(10, 4, 44, 44);
    _play.frame = CGRectMake(56, 4, 44, 44);
    _next.frame = CGRectMake(102, 4, 44, 44);
    CGFloat left = 160, avail = cw - left - 16;
    CGFloat w = MIN(520, avail);
    _cap.frame = CGRectMake(left + (avail - w) / 2, 2, w, 48);
    _capArt.frame = CGRectMake(5, 5, 38, 38);
    _capTitle.frame = CGRectMake(52, 6, w - 104, 18);
    _capSub.frame = CGRectMake(52, 24, w - 104, 16);
    [self tickBar];
    if (_pop) [self layoutPopup];
}

- (void)sync {
    MCPlayer *p = [MCPlayer shared];
    MCSong *s = p.current;
    _capTitle.text = s ? s.title : @"Not Playing";
    _capSub.text = s ? [NSString stringWithFormat:@"%@ \u2014 %@", s.artist, s.album] : @"";
    [_play setImage:MCIcon(p.playing ? @"pause" : @"play", 26, [UIColor blackColor]) forState:UIControlStateNormal];
    if (s) {
        _capArt.image = MCPlaceholder();
        [s loadArtwork:^(UIImage *img) { if ([MCPlayer shared].current == s) self->_capArt.image = img; }];
    } else {
        _capArt.image = nil;
    }
    [self tickBar];
}

- (void)tickBar {
    MCPlayer *p = [MCPlayer shared];
    NSTimeInterval d = [p duration];
    CGFloat f = d > 0 ? (CGFloat)([p time] / d) : 0;
    f = MIN(MAX(f, 0), 1);
    _prog.frame = CGRectMake(0, _cap.bounds.size.height - 2, _cap.bounds.size.width * f, 2);
}

- (void)openNowPlaying {
    if (![MCPlayer shared].current) return;
    [self presentViewController:[[MCNowPlayingVC alloc] init] animated:YES completion:nil];
}

- (void)doPrev { [[MCPlayer shared] prev]; }
- (void)doNext { [[MCPlayer shared] next]; }
- (void)doToggle { [[MCPlayer shared] toggle]; }

- (void)showItem:(NSIndexPath *)ip {
    NSString *k = _items[ip.section][ip.row][@"k"];
    UIViewController *vc = nil;
    if ([k isEqualToString:@"search"]) {
        MCSongsVC *s = [[MCSongsVC alloc] init];
        s.searchMode = YES;
        s.live = YES;
        vc = s;
    } else if ([k isEqualToString:@"home"] || [k isEqualToString:@"browse"] || [k isEqualToString:@"radio"]) {
        MCHomeVC *h = [[MCHomeVC alloc] init];
        h.mode = [k isEqualToString:@"home"] ? 0 : ([k isEqualToString:@"browse"] ? 1 : 2);
        vc = h;
    } else if ([k isEqualToString:@"recent"]) {
        MCSongsVC *s = [[MCSongsVC alloc] init];
        s.live = YES;
        s.recent = YES;
        vc = s;
    } else if ([k isEqualToString:@"playlists"]) {
        MCGridVC *g = [[MCGridVC alloc] init];
        g.kind = 1;
        vc = g;
    } else if ([k isEqualToString:@"artists"]) {
        vc = [[MCArtistsVC alloc] init];
    } else if ([k isEqualToString:@"albums"]) {
        vc = [[MCGridVC alloc] init];
    } else {
        MCSongsVC *s = [[MCSongsVC alloc] init];
        s.live = YES;
        vc = s;
    }
    vc.title = _items[ip.section][ip.row][@"t"];
    [_nav setViewControllers:@[vc] animated:NO];
}

#pragma mark Empty-library popup (permission-style card)

- (void)libChanged {
    if ([MCLibrary shared].songs.count == 0 && !_popupShown) [self showPopup];
    else if ([MCLibrary shared].songs.count > 0) [self hidePopup:nil];
}

- (void)showPopup {
    _popupShown = YES;
    _dim = [[UIView alloc] initWithFrame:self.view.bounds];
    _dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    _dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pop = [[UIView alloc] init];
    _pop.backgroundColor = [UIColor whiteColor];
    _pop.layer.cornerRadius = 7.5;
    [_dim addSubview:_pop];

    UIImageView *icon = [[UIImageView alloc] initWithImage:MCIcon(@"songs", 150, MCRed)];
    icon.contentMode = UIViewContentModeCenter;
    icon.tag = 1;
    [_pop addSubview:icon];
    UILabel *t = [[UILabel alloc] init];
    t.tag = 2;
    t.numberOfLines = 4;
    t.textAlignment = NSTextAlignmentCenter;
    t.font = MCFont(19, YES);
    t.text = @"'Music Clone' couldn't find any music.\nSync songs with iTunes or copy mp3 files to /var/mobile/Media/Music";
    [_pop addSubview:t];

    UIButton *scan = [UIButton buttonWithType:UIButtonTypeCustom];
    scan.tag = 3;
    [scan setTitle:@"SCAN AGAIN" forState:UIControlStateNormal];
    scan.titleLabel.font = MCFont(16, YES);
    scan.backgroundColor = MCRed;
    scan.layer.cornerRadius = 8;
    scan.layer.shadowColor = MCRed.CGColor;
    scan.layer.shadowOpacity = 0.75;
    scan.layer.shadowRadius = 4;
    scan.layer.shadowOffset = CGSizeZero;
    [scan addTarget:self action:@selector(scanAgain) forControlEvents:UIControlEventTouchUpInside];
    [_pop addSubview:scan];
    UIButton *no = [UIButton buttonWithType:UIButtonTypeCustom];
    no.tag = 4;
    [no setTitle:@"NOT NOW" forState:UIControlStateNormal];
    [no setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    no.titleLabel.font = MCFont(16, YES);
    no.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.75];
    no.layer.cornerRadius = 8;
    [no addTarget:self action:@selector(closePopup) forControlEvents:UIControlEventTouchUpInside];
    [_pop addSubview:no];
    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom];
    x.tag = 5;
    x.backgroundColor = [UIColor whiteColor];
    x.layer.cornerRadius = 20;
    x.layer.shadowColor = [UIColor blackColor].CGColor;
    x.layer.shadowOpacity = 0.5;
    x.layer.shadowRadius = 3;
    x.layer.shadowOffset = CGSizeZero;
    [x setImage:MCIcon(@"close", 22, [UIColor blackColor]) forState:UIControlStateNormal];
    [x addTarget:self action:@selector(closePopup) forControlEvents:UIControlEventTouchUpInside];
    [_pop addSubview:x];

    [self.view addSubview:_dim];
    [self layoutPopup];
    _pop.transform = CGAffineTransformMakeScale(0.9, 0.9);
    _dim.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{ self->_dim.alpha = 1; self->_pop.transform = CGAffineTransformIdentity; }];
}

- (void)layoutPopup {
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGAffineTransform tf = _pop.transform;
    _pop.transform = CGAffineTransformIdentity;
    CGFloat pw = MIN(430, W - 60), ph = 470;
    _pop.frame = CGRectMake((W - pw) / 2, (H - ph) / 2, pw, ph);
    [_pop viewWithTag:1].frame = CGRectMake(25, 20, pw - 50, 170);
    [_pop viewWithTag:2].frame = CGRectMake(30, 200, pw - 60, 120);
    [_pop viewWithTag:3].frame = CGRectMake(20, ph - 140, pw - 40, 55);
    [_pop viewWithTag:4].frame = CGRectMake(20, ph - 75, pw - 40, 55);
    [_pop viewWithTag:5].frame = CGRectMake(pw - 25, -15, 40, 40);
    _pop.transform = tf;
}

- (void)scanAgain { [self hidePopup:nil]; _popupShown = NO; [[MCLibrary shared] reload]; }
- (void)closePopup { [self hidePopup:nil]; }

- (void)hidePopup:(id)x {
    if (!_dim) return;
    UIView *d = _dim, *p = _pop;
    _dim = nil;
    _pop = nil;
    [UIView animateWithDuration:0.2 animations:^{ d.alpha = 0; p.transform = CGAffineTransformMakeScale(0.9, 0.9); } completion:^(BOOL f) { [d removeFromSuperview]; }];
}

#pragma mark Sidebar table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return (NSInteger)_items.count; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return (NSInteger)[_items[s] count]; }
- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s { return s == 2 ? 40 : 6; }

- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    UIView *v = [[UIView alloc] init];
    if (s == 2) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 8, 200, 28)];
        l.text = _sectionTitles[s];
        l.font = MCFont(20, YES);
        [v addSubview:l];
    }
    return v;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"side"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"side"];
        c.backgroundColor = [UIColor clearColor];
        c.textLabel.font = MCFont(17, NO);
        UIView *sel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kSideW, 44)];
        UIView *pill = [[UIView alloc] initWithFrame:CGRectMake(10, 2, kSideW - 20, 40)];
        pill.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
        pill.layer.cornerRadius = 9;
        pill.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [sel addSubview:pill];
        c.selectedBackgroundView = sel;
    }
    NSDictionary *it = _items[ip.section][ip.row];
    c.textLabel.text = it[@"t"];
    c.imageView.image = MCIcon(it[@"i"], 22, MCRed);
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip { [self showItem:ip]; }

@end
