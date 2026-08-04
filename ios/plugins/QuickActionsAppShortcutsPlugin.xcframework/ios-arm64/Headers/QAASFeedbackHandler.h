#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QAASFeedbackHandler : NSObject

+ (instancetype)shared;
+ (void)installIfNeeded;

// Returns YES when the shortcut was handled (mailto opened or failed gracefully).
+ (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

@end

NS_ASSUME_NONNULL_END
