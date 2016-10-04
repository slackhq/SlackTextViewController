# Change Log

## [Version 1.9.5](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.9.5)

##### Features:
- Migrated the library to be using NSAttributedString underneath. The `text` property on `SLKTextView` uses a NSAttributedString representation based on its font and text color, and doesn't forward to super. By @jacywu07 (https://github.com/slackhq/SlackTextViewController/pull/501)
- As part of the migration to NSAttributedString, new helpers for attributed strings have been added to `SLKTextView+SLKAdditions`.
- Introduced a new API to end users to open the auto-completion mode with a given prefix. By @jacywu07 (https://github.com/slackhq/SlackTextViewController/pull/506)
- Exposed the private `cacheTextView` method. By @acandelaria1 (https://github.com/slackhq/SlackTextViewController/pull/513)

##### Hot Fixes & Enhancements:
- Updated the sample project to Swift 3! By @cyhsutw (https://github.com/slackhq/SlackTextViewController/pull/522) 
- Added a property to allow the user to set how many lines of text SLKTextView's placeholder should have. By @jedmund (https://github.com/slackhq/SlackTextViewController/pull/505)
- Tweaked keyboard height calculations on invert mode. By @ZAndyL (https://github.com/slackhq/SlackTextViewController/pull/512)

## [Version 1.9.4](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.9.4)
##### Hot Fixes & Enhancements:
- Fixed keyboard status updates inconsistencies, causing sometimes the text input bar not to follow the keyboard.
- Fixed bottom margin inconsistencies. Thanks @yury! 💪 
- Fixed an edge case where the caret would jump to the end after double-space completion in middle of text. Thanks @mtackes 
- Improved Carthage support


## [Version 1.9.3](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.9.3)

##### Hot Fixes & Enhancements:
- Fixes a regression causing to trigger auto-completion text processing even if no prefix have been registered. This was causing a crash to many. Sorry about that!
- Ignores keyboard notifications when no valid first responder is detected. This fixes the text input not following the keyboard at times.
- Now `shouldProcessTextForAutoCompletion:` requires calling super.


## [Version 1.9.2](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.9.2)

#### SlackTextViewController is now MIT licensed!

##### Features & Enhancements:
- Better Swift 2.2 support with nullability annotations and shiny new Swift sample code. You rock @weijentu 🙇 
- Introduced `SLKTextInput` protocol: A `UITextInput` extension to decouple all the text processing features related to auto-completion, to reuse in any text component such as UISearchBar, UITextField, UITextView, etc.
- Added a new API `-shouldProcessTextForAutoCompletion` to be able to opt-out from text processing for auto-completion.
- The `registeredPrefixes` property are now of type NSSet (instead of NSArray).
- Added animation to views when switching from a keyboard to a custom input view. Thanks @cyhsutw!
- Made `keyboardStatus` public, making it easier to check for the current keyboard state.

##### Hot Fixes:
- Fixed a use case where the textInput would not follow the keyboard when dismissing.
- Improved text caching from the textInput, specially when moving the app to the background (in case the app crashes while being on the background).
- Fixed misaligned placeholder labels in the textView and out of bounds.
- Fixed the textInput not growing accordantly to the font size. This was a regressions since version  `1.7.1`
- Many, many, many auto-completion bug fixes 💪 


## [Version 1.9.1](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.9.1)

##### Features & Enhancements:
- Renamed public `autoCompleteFormatting` to `formattingEnabled`.
- Doesn't opt-out anymore from the built-in menu menu items **Define**, **Replace** and **Share**.
- Made the collectionView's default background color to white.
- The auto-completion view is now presented above of the table/collection view avoiding to push it up/down every time. Much better UX!
- Stored all key commands in a instance variable, to avoid recreating the array at every character update.

##### Hot Fixes:
- Fixed library from not compiling on iOS 8.
- Fixed the right button from stretching when animating the constrains. This was broken since iOS 9.
- Improved `UITabBar` support by considering `hidesBottomBarWhenPushed` too.
- Fixed crash when double tapping the space bar while the textView was empty.
- Fixed issue causing not to forward all UITextViewDelegate callbacks.


## [Version 1.9](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.9)

##### Deprecations:
- Deprecated the keyboard panning gesture on iOS 9, to drag the keyboard up and down. More information about this in #361
- Deprecated `isLoupeVisible`, which will cause issues when auto-completion mode is active and moving the cursor of the text view. More information about this in #361

##### Features & Enhancements:
- Enabled interaction while the right button and the auto-completion view are being presented animatedly
- Does not scroll to the bottom anymore, if the content size is smaller than its bounds, when `shouldScrollToBottomAfterKeyboardShows` is enabled.

##### Hot Fixes:
- Fixed the keyboard status and custom notifications not being set on the right order.
- Fixed a crash when calling unrecognised selectors internally in the `UITextViewDelegate` method implementation, when using other subclasses of UITextView.
- Fixed `UITabBar` support. This was a regression. Thanks @LHIOUI for the headsup 👊
- Fixed cursor dragging issues when deep pressing on the keyboard's trackpad.
- Fixed the auto-completion layout being busted in 1.8. This was a regression.


## [Version 1.8](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.8)

##### Features & Enhancements:
* Added [Markdown Formatting](https://github.com/slackhq/SlackTextViewController#markdown-formatting) ⚡️📝, a useful and simple way to allow your users to auto-complete any markdown formatting from within the text input. 1 small step to make writing markdown quicker.
* The shake gesture now presents an `UIAlertController` for iOS 8 and above. Still supports the old and good `UIAlertView` for legacy versions.

##### Hot Fixes:
* Fixed some content inset non-sense
* Scrolling to top now really scrolls to top. Not down. Oopsie.
* Scrolling down when the keyboard gets presented is also working now. Yay :tada: !
* The placeholder font now matches the textView font, for real this time.
* Avoids reloading the text view when there is [no key for cache](https://github.com/slackhq/SlackTextViewController/commit/d3730e2a880c9fd8768623f923d5443432829ee9). Thanks @susieyy!
* Removed annoying iOS 8 warnings.


## [Version 1.7.2](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.7.2)

##### Hot Fixes:
* Better [Carthage](https://github.com/Carthage/Carthage) support 🙏
* Fixed the textInput's [right margin not being honored or honoured](https://github.com/slackhq/SlackTextViewController/commit/6ed6b29f3a82ef22b626eda08dfe57ec4ab37df1). Thanks @ikesyo 🙌
* Fixed the textView's contentSize to never be higher than its bounds. Very useful for stuff.


## [Version 1.7.1](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.7.1)

##### Features & Enhancements:
* Changed how the auto-completion API worked: it now allows asynch auto-completion! Have a look at how to set it up / update it](https://github.com/slackhq/SlackTextViewController#autocompletion)
* Added keyboard trackpad detection for iOS 9. Used internally for disables auto-completion while its detected, so we avoid crazy things! 👻
* Improved the magnifying glass detection.
* Gonna get a nice warning to remind you to `super` in `viewDidLoad` now. Fancy! 
* Slowed down bouncy animation by 0.15 seconds
* Disabled `cellLayoutMarginsFollowReadableWidth` on iOS 9 for the auto-completion view. No need for large margins, come on!

##### Hot Fixes:
* Fixed compatibility issues with [Cocoapods](https://github.com/CocoaPods/CocoaPods) 0.39.0 new requirements. All sources are now in the same root level.
* Fixed keyboard presentation when pushing a view controller instance. Thanks @fastred!
* Fixed auto-layout issues on the Edit Mode.
* Fixed `maximumHeightForAutoCompletionView` calculations. Maths!
* Fixed [crash caused by calling `layoutIfNeeded` too early](https://github.com/slackhq/SlackTextViewController/commit/dceedc70393e873d70c82da39c9f2cc9f18fda5a)
* [Removed duplicated declarations](https://github.com/slackhq/SlackTextViewController/commit/f61e4e2cbc03ff30c9391fc86eba2c5ba8674f47), specially causing nightmares to Swifters.
* Removed unused internal methods.
* Better (Carthage)[https://github.com/Carthage/Carthage] support 🙏


## [Version 1.7](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.7)

##### Deprecations:
- Removed `shouldForceTextInputbarAdjustment` and replace it with `-forceTextInputbarAdjustmentForResponder:`
- Renamed `canShowTypeIndicator` and replace it with `canShowTypingIndicator`
- Renamed `editortLeftButton` with `editorLeftButton`, and `editortRightButton` with `editorRightButton`

##### Features & enhancements:
- Added iOS 9 (beta 5) support, with fixes for multi-tasking on iPad and external keyboard shortcut hud support, and many small layout tweaks.
- Added the ability to show/hide the text input bar, with animation support, using `setTextInputbarHidden:animated:`. Thanks @aryaxt!
- Added better Accessibility support with [Dynamic Type](https://github.com/slackhq/SlackTextViewController#dynamic-type)
- [Improved the keyboard panning gesture by dragging the text input bar from the bottom](https://cloud.githubusercontent.com/assets/590579/9448678/5423f254-4a74-11e5-870d-80c377d24937.gif) (feature flagged as it needs more testing)
- Added 2 more `UIScrollViewDelegate` method declarations to SLKTextViewController's header. `super` is required!

##### Hot Fixes:
- Fixed wrong auto-completion view height calculations.
- Fixed a very bad retain cycle reported in #234
- Fixed the keyboard view detection on iOS 9
- Fixed swift compiler warning. Thanks @csjones 


## [Version 1.6](https://github.com/slackhq/SlackTextViewController/releases/tag/v1.6)

##### Features:
- Added support for custom typing indicator, following the same pattern of registering a class using `registerClassForTypingIndicatorView:`, while this class conforms to `SLKTypingIndicatorProtocol`. Please refer to the documentation for more details about the feature. Thanks @sveinhal! (#207)
- Added support for registering longer auto-completion prefixes
- Improved drastically the keyboard panning experience, making it much more smooth now. Awesome stuff @camitox!
- Added the ability to ignore the text inputbar adjustment when the keyboard is presented, using `ignoreTextInputbarAdjustment`. This is generally useful when SLKTVC is used in a custom modal presentation and when you want to manipulate the view's alignment yourself.

##### Hot Fixes:
- No longer overriding the default background color of UITableView. Oupsi! (#205)
- Made sure not to register the same notifications twice.
- Fixes issue where the text input would not adjust on top of the keyboard when presenting an `UIAlertViewController` (`UIAlertView` or `UIActionSheet`) in iOS8


## Previous versions
For more release notes of this project, please visit https://github.com/slackhq/SlackTextViewController/releases
