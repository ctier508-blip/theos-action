// Tweak.x - Code complet pour le tweak iOS Agar.io (Objective-C)
// Utilisation de NSURLSessionWebSocketTask à la place de la classe "WebSocket"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface AgarIoBotTweak : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *webSocketSession;
@property (nonatomic, strong) NSURLSessionWebSocketTask *activeWebSocketTask;
@property (nonatomic, assign) BOOL isMenuVisible;
@property (nonatomic, strong) UIView *botMenu;
@property (nonatomic, strong) UIView *gameView; // Stockage de la vue du jeu
@end

@implementation AgarIoBotTweak

+ (instancetype)sharedInstance {
  static AgarIoBotTweak *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    // Initialisation de la connexion WebSocket vers le serveur PC
    NSURL *url = [NSURL URLWithString:@"ws://192.168.1.183:8080"];
    
    // Configuration de la session URLSession
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.webSocketSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    // Création du task WebSocket
    self.activeWebSocketTask = [self.webSocketSession webSocketTaskWithURL:url];
    [self.activeWebSocketTask resume]; // Démarrage de la connexion
    
    // Menu des bots caché par défaut
    self.isMenuVisible = NO;
  }
  return self;
}

// Configuration du bouton flottant
- (void)setupFloatingButtonInView:(UIView *)view {
  self.gameView = view;
  
  // Bouton circulaire semi-transparent
  UIButton *floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
  floatingButton.frame = CGRectMake(0, 0, 60, 60);
  floatingButton.layer.cornerRadius = 30;
  floatingButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.4];
  
  // Positionnement en haut à droite
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat screenWidth = CGRectGetWidth(screenBounds);
  floatingButton.center = CGPointMake(screenWidth - 40, 50);
  
  // Action au clic
  [floatingButton addTarget:self action:@selector(toggleBotMenu:) forControlEvents:UIControlEventTouchUpInside];
  
  // Ajout à la vue principale
  [view addSubview:floatingButton];
}

// Création du menu des bots (UIView transparent)
- (void)setupBotMenu {
  if (!self.botMenu) {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = CGRectGetHeight(screenBounds);
    CGFloat screenWidth = CGRectGetWidth(screenBounds);
    
    self.botMenu = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight - 120, screenWidth, 100)];
    self.botMenu.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    
    // Bouton VENIR
    UIButton *btnVenir = [UIButton buttonWithType:UIButtonTypeCustom];
    btnVenir.frame = CGRectMake(20, 25, 90, 40);
    btnVenir.backgroundColor = [UIColor systemBlueColor];
    btnVenir.layer.cornerRadius = 5;
    [btnVenir setTitle:@"VENIR" forState:UIControlStateNormal];
    [btnVenir addTarget:self action:@selector(sendComeAction) forControlEvents:UIControlEventTouchUpInside];
    
    // Bouton FEED
    UIButton *btnFeed = [UIButton buttonWithType:UIButtonTypeCustom];
    btnFeed.frame = CGRectMake(130, 25, 90, 40);
    btnFeed.backgroundColor = [UIColor systemGreenColor];
    btnFeed.layer.cornerRadius = 5;
    [btnFeed setTitle:@"FEED" forState:UIControlStateNormal];
    [btnFeed addTarget:self action:@selector(sendFeedAction) forControlEvents:UIControlEventTouchUpInside];
    
    // Bouton SPLIT
    UIButton *btnSplit = [UIButton buttonWithType:UIButtonTypeCustom];
    btnSplit.frame = CGRectMake(240, 25, 90, 40);
    btnSplit.backgroundColor = [UIColor systemRedColor];
    btnSplit.layer.cornerRadius = 5;
    [btnSplit setTitle:@"SPLIT" forState:UIControlStateNormal];
    [btnSplit addTarget:self action:@selector(sendSplitAction) forControlEvents:UIControlEventTouchUpInside];
    
    // Ajout des boutons au menu
    [self.botMenu addSubview:btnVenir];
    [self.botMenu addSubview:btnFeed];
    [self.botMenu addSubview:btnSplit];
  }
  
  if (self.gameView) {
    [self.gameView addSubview:self.botMenu];
  }
}

// Gestion de la visibilité du menu (toggle)
- (void)toggleBotMenu:(UIButton *)sender {
  self.isMenuVisible = !self.isMenuVisible;
  
  if (self.isMenuVisible) {
    [self setupBotMenu]; // Afficher le menu
  } else {
    if (self.botMenu) {
      [self.botMenu removeFromSuperview];
    }
  }
}

// Envoi d'actions via NSURLSessionWebSocketTask
- (void)sendActionToServer:(NSDictionary *)actionDict {
  if (self.activeWebSocketTask) {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:actionDict options:0 error:&error];
    if (!error) {
      NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:jsonString];
      [self.activeWebSocketTask sendMessage:message completionHandler:^(NSError * _Nullable sendError) {
        if (sendError) {
          NSLog(@"[Tweak] Erreur d'envoi d'action: %@", sendError.localizedDescription);
        }
      }];
    }
  }
}

- (void)sendComeAction {
  [self sendActionToServer:@{@"action": @"venir"}];
}

- (void)sendFeedAction {
  [self sendActionToServer:@{@"action": @"feed"}];
}

- (void)sendSplitAction {
  [self sendActionToServer:@{@"action": @"split"}];
}

// Envoi des mouvements tactiles
- (void)sendLocationToServer:(CGPoint)location {
  if (self.activeWebSocketTask) {
    NSDictionary *data = @{
      @"x": @(location.x),
      @"y": @(location.y)
    };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if (!error) {
      NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:jsonString];
      [self.activeWebSocketTask sendMessage:message completionHandler:nil];
    }
  }
}

@end

// Injection (Hook) dans l'application Agar.io
%hook UIView 

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  %orig; // Laisse le jeu d'origine fonctionner normalement
  
  // Initialisation du bouton flottant au premier mouvement tactile détecté
  static dispatch_once_t onceButtonToken;
  dispatch_once(&onceButtonToken, ^{
    [[AgarIoBotTweak sharedInstance] setupFloatingButtonInView:self];
  });
  
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self];
  
  // Envoi des coordonnées de ton doigt vers ton PC
  [[AgarIoBotTweak sharedInstance] sendLocationToServer:location];
}

%end
