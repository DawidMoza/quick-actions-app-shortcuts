#import "QuickActionsAppShortcutsPlugin.h"
#import "QAASFeedbackHandler.h"

__attribute__((constructor))
static void qaas_constructor(void) {
	// Ensure +load-time style setup even if gdip initialization is delayed.
	[QAASFeedbackHandler installIfNeeded];
}

// Godot's export dummy.cpp declares these as C++ `extern void ...()` (no extern "C"),
// so they must be compiled as C++/ObjC++ — not plain C from a .m file.
void quick_actions_app_shortcuts_init(void) {
	[QAASFeedbackHandler installIfNeeded];
}

void quick_actions_app_shortcuts_deinit(void) {
}
