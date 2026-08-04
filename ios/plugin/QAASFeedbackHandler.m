#import "QAASFeedbackHandler.h"
#import <objc/runtime.h>
#import <sys/utsname.h>

static NSString *const kQAASShortcutType =
	@"org.godotengine.plugin.quickactionsappshortcuts.feedback";
static NSString *const kQAASRecipientKey = @"QAASFeedbackRecipient";

static IMP qaas_original_scene_will_connect = NULL;
static IMP qaas_original_window_scene_perform = NULL;
static IMP qaas_original_application_perform = NULL;
static BOOL qaas_hooks_installed = NO;
static BOOL qaas_hook_install_in_progress = NO;
static const int kQAASMaxHookInstallAttempts = 200;
static const NSTimeInterval kQAASHookRetryDelay = 0.05;

static void qaas_install_hooks_with_retry(int attempt);

@implementation QAASFeedbackHandler

+ (instancetype)shared {
	static QAASFeedbackHandler *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[QAASFeedbackHandler alloc] init];
	});
	return instance;
}

+ (void)installIfNeeded {
	[[QAASFeedbackHandler shared] install];
}

- (void)install {
	dispatch_block_t installBlock = ^{
		if (qaas_hooks_installed || qaas_hook_install_in_progress) {
			return;
		}
		qaas_hook_install_in_progress = YES;
		qaas_install_hooks_with_retry(0);
		NSLog(@"[QAAS] Feedback quick-action handler install requested");
	};

	if (NSThread.isMainThread) {
		installBlock();
	} else {
		dispatch_async(dispatch_get_main_queue(), installBlock);
	}
}

+ (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem {
	if (shortcutItem == nil) {
		return NO;
	}
	if (![shortcutItem.type isEqualToString:kQAASShortcutType]) {
		return NO;
	}

	NSDictionary *info = NSBundle.mainBundle.infoDictionary;
	NSString *recipient = [[info objectForKey:kQAASRecipientKey] description];
	recipient = [recipient stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	if (recipient.length == 0) {
		NSLog(@"[QAAS] Missing QAASFeedbackRecipient in Info.plist");
		return NO;
	}

	// Prefer export-generated Localizable.strings; retain safe English fallbacks.
	NSString *subjectTemplate = NSLocalizedString(@"QAAS_SUBJECT_TEMPLATE", @"");
	if (subjectTemplate.length == 0 || [subjectTemplate isEqualToString:@"QAAS_SUBJECT_TEMPLATE"]) {
		subjectTemplate = @"Feedback for {{APP_NAME}}";
	}

	NSString *bodyTemplate = NSLocalizedString(@"QAAS_BODY_TEMPLATE", @"");
	if (bodyTemplate.length == 0 || [bodyTemplate isEqualToString:@"QAAS_BODY_TEMPLATE"]) {
		bodyTemplate =
			@"Please share your feedback above this line.\n\nApp: {{APP_NAME}}\nVersion: {{APP_VERSION}}\nOS: {{OS_VERSION}}\nDevice: {{DEVICE_MODEL}}";
	}

	NSDictionary *values = qaas_diagnostic_values();

	NSString *subject = qaas_apply_template(subjectTemplate, values);
	NSString *body = qaas_apply_template(bodyTemplate, values);
	NSURL *mailto = qaas_build_mailto(recipient, subject, body);
	if (mailto == nil) {
		NSLog(@"[QAAS] Failed to build mailto URL");
		return NO;
	}

	UIApplication *app = UIApplication.sharedApplication;
	if (![app canOpenURL:mailto]) {
		NSLog(@"[QAAS] No mail client can open mailto URL");
		return NO;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[app openURL:mailto options:@{} completionHandler:^(BOOL success) {
			NSLog(@"[QAAS] openURL mailto success=%@", success ? @"YES" : @"NO");
		}];
	});
	return YES;
}

#pragma mark - Helpers

static NSDictionary *qaas_diagnostic_values(void) {
	NSDictionary *info = NSBundle.mainBundle.infoDictionary;
	NSString *appName = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: @"";
	NSString *version = info[@"CFBundleShortVersionString"] ?: @"";
	NSString *osVersion = [NSString stringWithFormat:@"iOS %@", UIDevice.currentDevice.systemVersion ?: @""];

	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding]
		?: UIDevice.currentDevice.model;

	return @{
		@"{{APP_NAME}}" : appName ?: @"",
		@"{{APP_VERSION}}" : version ?: @"",
		@"{{OS_VERSION}}" : osVersion ?: @"",
		@"{{DEVICE_MODEL}}" : deviceModel ?: @"",
	};
}

static NSString *qaas_apply_template(NSString *template, NSDictionary *values) {
	__block NSString *result = template ?: @"";
	[values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
		result = [result stringByReplacingOccurrencesOfString:key withString:value ?: @""];
	}];
	return result;
}

static NSString *qaas_url_encode(NSString *value) {
	NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
		@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"];
	return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

static NSURL *qaas_build_mailto(NSString *recipient, NSString *subject, NSString *body) {
	NSString *urlString = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",
		recipient,
		qaas_url_encode(subject ?: @""),
		qaas_url_encode(body ?: @"")];
	return [NSURL URLWithString:urlString];
}

#pragma mark - Hooks

static void qaas_scene_will_connect(id self, SEL _cmd, UIScene *scene, UISceneSession *session,
	UISceneConnectionOptions *connectionOptions) {
	UIApplicationShortcutItem *item = connectionOptions.shortcutItem;
	if (item != nil) {
		[QAASFeedbackHandler handleShortcutItem:item];
	}
	if (qaas_original_scene_will_connect) {
		((void (*)(id, SEL, UIScene *, UISceneSession *, UISceneConnectionOptions *))
			qaas_original_scene_will_connect)(self, _cmd, scene, session, connectionOptions);
	}
}

static void qaas_window_scene_perform(id self, SEL _cmd, UIWindowScene *windowScene,
	UIApplicationShortcutItem *shortcutItem, void (^completionHandler)(BOOL)) {
	BOOL handled = [QAASFeedbackHandler handleShortcutItem:shortcutItem];
	if (handled) {
		if (completionHandler) {
			completionHandler(YES);
		}
		return;
	}
	if (qaas_original_window_scene_perform) {
		((void (*)(id, SEL, UIWindowScene *, UIApplicationShortcutItem *, void (^)(BOOL)))
			qaas_original_window_scene_perform)(self, _cmd, windowScene, shortcutItem, completionHandler);
	} else if (completionHandler) {
		completionHandler(NO);
	}
}

static void qaas_application_perform(id self, SEL _cmd, UIApplication *application,
	UIApplicationShortcutItem *shortcutItem, void (^completionHandler)(BOOL)) {
	BOOL handled = [QAASFeedbackHandler handleShortcutItem:shortcutItem];
	if (handled) {
		if (completionHandler) {
			completionHandler(YES);
		}
		return;
	}
	if (qaas_original_application_perform) {
		((void (*)(id, SEL, UIApplication *, UIApplicationShortcutItem *, void (^)(BOOL)))
			qaas_original_application_perform)(self, _cmd, application, shortcutItem, completionHandler);
	} else if (completionHandler) {
		completionHandler(NO);
	}
}

static void qaas_add_or_swizzle(Class cls, SEL selector, IMP newImp, const char *types, IMP *outOriginal) {
	Method existing = class_getInstanceMethod(cls, selector);
	if (existing) {
		*outOriginal = method_setImplementation(existing, newImp);
	} else {
		*outOriginal = NULL;
		class_addMethod(cls, selector, newImp, types);
	}
}

static void qaas_install_hooks_with_retry(int attempt) {
	if (qaas_hooks_installed) {
		return;
	}

	Class appDelegateClass = NSClassFromString(@"GDTApplicationDelegate");
	if (appDelegateClass == Nil) {
		appDelegateClass = NSClassFromString(@"GodotApplicationDelegate");
	}
	if (appDelegateClass == Nil) {
		if (attempt < kQAASMaxHookInstallAttempts) {
			dispatch_after(dispatch_time(
				DISPATCH_TIME_NOW,
				(int64_t)(kQAASHookRetryDelay * NSEC_PER_SEC)
			),
				dispatch_get_main_queue(), ^{
					qaas_install_hooks_with_retry(attempt + 1);
				});
		} else {
			qaas_hook_install_in_progress = NO;
			NSLog(@"[QAAS] Godot app delegate class not found; iOS shortcut handling unavailable");
		}
		return;
	}

	qaas_add_or_swizzle(
		appDelegateClass,
		@selector(scene:willConnectToSession:options:),
		(IMP)qaas_scene_will_connect,
		"v@:@@@",
		&qaas_original_scene_will_connect
	);
	qaas_add_or_swizzle(
		appDelegateClass,
		@selector(windowScene:performActionForShortcutItem:completionHandler:),
		(IMP)qaas_window_scene_perform,
		"v@:@@@?",
		&qaas_original_window_scene_perform
	);
	qaas_add_or_swizzle(
		appDelegateClass,
		@selector(application:performActionForShortcutItem:completionHandler:),
		(IMP)qaas_application_perform,
		"v@:@@@?",
		&qaas_original_application_perform
	);

	qaas_hooks_installed = YES;
	qaas_hook_install_in_progress = NO;
	NSLog(@"[QAAS] Installed shortcut handlers on %@", NSStringFromClass(appDelegateClass));
}

@end
