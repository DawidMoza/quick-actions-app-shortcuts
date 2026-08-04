#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Initializes the feedback quick-action handler. Safe to call multiple times.
// Intentionally C++ linkage: Godot's generated dummy.cpp declares these without extern "C".
void quick_actions_app_shortcuts_init(void);
void quick_actions_app_shortcuts_deinit(void);
