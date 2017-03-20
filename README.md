# SlackTextViewController

**IMPORTANT NOTICE: Please update to >= `1.9` to avoid any risk of app rejection.
More details in [#361](https://github.com/slackhq/SlackTextViewController/issues/361)**

[![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](http://opensource.org/licenses/MIT)
[![Pod Version](https://img.shields.io/cocoapods/v/SlackTextViewController.svg?style=flat-square)](http://cocoadocs.org/docsets/SlackTextViewController/1.9/)
[![Carthage compatible](https://img.shields.io/badge/carthage-compatible-F5B369.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Build Status](https://img.shields.io/travis/slackhq/SlackTextViewController.svg?style=flat-square)](https://travis-ci.org/slackhq/SlackTextViewController)

A drop-in UIViewController subclass with a growing text input view and other useful messaging features. Meant to be a replacement for UITableViewController & UICollectionViewController.

![Demo Gif](Screenshots/slacktextviewcontroller_demo.gif)

This library is used in Slack's iOS app. It was built to fit our needs, but is flexible enough to be reused by others wanting to build great messaging apps for iOS.

## Feature List

### Core
- Works out of the box with [UITableView or UICollectionView or UIScrollView](https://github.com/slackhq/SlackTextViewController#subclassing)
- [Growing Text View](https://github.com/slackhq/SlackTextViewController#growing-text-view), with line count limit support
- Flexible UI built with Auto Layout
- Customizable: provides left and right button, and toolbar outlets
- Tap Gesture for dismissing the keyboard
- [External keyboard](https://github.com/slackhq/SlackTextViewController#external-keyboard) commands support
- Undo/Redo (with keyboard commands and UIMenuController)
- Text Appending APIs

### Additional
- [Autocomplete Mode](https://github.com/slackhq/SlackTextViewController#autocompletion) by registering any prefix key (`@`, `#`, `/`)
- [Edit Mode](https://github.com/slackhq/SlackTextViewController#edit-mode)
- [Markdown Formatting](https://github.com/slackhq/SlackTextViewController#markdown-formatting)
- [Typing Indicator](https://github.com/slackhq/SlackTextViewController#typing-indicator) display
- [Shake Gesture](https://github.com/slackhq/SlackTextViewController#shake-gesture) for clearing text view
- Multimedia Pasting (png, gif, mov, etc.)
- [Inverted Mode](https://github.com/slackhq/SlackTextViewController#inverted-mode) for displaying cells upside-down (using CATransform) -- a necessary hack for some messaging apps. `YES`/`true` by default, so beware, your entire cells might be flipped!
- Tap Gesture for dismissing the keyboard
- [Panning Gesture](https://github.com/slackhq/SlackTextViewController#panning-gesture) for sliding down/up the keyboard
- [Hideable TextInputbar](https://github.com/slackhq/SlackTextViewController#hideable-textinputbar)
- [Dynamic Type](https://github.com/slackhq/SlackTextViewController#dynamic-type) for adjusting automatically the text input bar height based on the font size.
- Bouncy Animations

### Compatibility
- Carthage & CocoaPods
- Objective-C & Swift
- iOS 7, 8 & 9
- iPhone & iPad
- [Storyboard](https://github.com/slackhq/SlackTextViewController#storyboard)
- UIPopOverController & UITabBarController
- Container View Controller
- Auto-Rotation
- iPad Multitasking (iOS 9 only)
- Localization

## Installation

###### With [CocoaPods](https://cocoapods.org/):
```ruby
pod "SlackTextViewController"
```

###### With [Carthage](https://github.com/Carthage/Carthage):
```swift
github "slackhq/SlackTextViewController"
```

###### Manually:
There are two ways to do this:
- Copy and drag the `Source/` folder to your project.
- or compile the project located in `Builder/SlackTextViewController.xcodeproj` to create a `SlackTextViewController.framework` package. You could also [link the library into your project](https://developer.apple.com/library/ios/recipes/xcode_help-project_editor/Articles/AddingaLibrarytoaTarget.html#//apple_ref/doc/uid/TP40010155-CH17-SW1).


## How to use

### Subclassing
`SLKTextViewController` is meant to be subclassed, like you would normally do with UITableViewController or UICollectionViewController or UIScrollView. This pattern is a convenient way of extending UIViewController. SlackTextViewController manages a lot behind the scenes while still providing the ability to add custom behaviours. You may override methods, and decide to call super and  perform additional logic, or not to call super and override default logic.

Start by creating a new subclass of `SLKTextViewController`.

In the init overriding method, if you wish to use the `UITableView` version, call:
##### Obj-C
```objc
[super initWithTableViewStyle:UITableViewStylePlain]
```
##### Swift
```swift
super.init(tableViewStyle: .Plain)
```

or the `UICollectionView` version:
##### Obj-C
```objc
[super initWithCollectionViewLayout:[UICollectionViewFlowLayout new]]
```
##### Swift
```swift
super.init(collectionViewLayout: UICollectionViewFlowLayout())
```

or the `UIScrollView` version:
##### Obj-C
```objc
[super initWithScrollView:self.myStrongScrollView]
```
##### Swift
```swift
super.init(scrollView: self.myStrongScrollView)
```

Protocols like `UITableViewDelegate` and `UITableViewDataSource` are already setup for you. You will be able to call whatever delegate and data source methods you need for customising your control.

Calling `[super init]` will call `[super initWithTableViewStyle:UITableViewStylePlain]` by default.

### Storyboard

When using SlackTextViewController with storyboards, instead of overriding the traditional `initWithCoder:` you will need to override any of the two custom methods below. This approach helps preserving the exact same features from the programatic approach, but also limits the edition of the nib of your `SLKTextViewController` subclass since it doesn't layout subviews from the nib (subviews are still initialized and layed out programatically).

if you wish to use the `UITableView` version, call:
##### Obj-C
```objc
+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}
```
##### Swift
```swift
override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
    return .Plain
}
```

or the `UICollectionView` version:
##### Obj-C
```objc
+ (UICollectionViewLayout *)collectionViewLayoutForCoder:(NSCoder *)decoder
{
    return [UICollectionViewFlowLayout new];
}
```
##### Swift
```swift
override class func collectionViewLayoutForCoder(decoder: NSCoder) -> UICollectionViewLayout {
    return UICollectionViewFlowLayout()
}
```

### Sample Project

Check out the sample project,  everything is demo'd there.
There are 2 main examples (different targets) for testing the programatic and storyboard approaches, and a Swift example. Most of the features are implemented for you to quickly start using them.

Feel free to contribute!


## Features


### Growing Text View

![Growing](Screenshots/screenshot_auto-expanding.png)

The text view expands automatically when a new line is required, until it reaches its `maxNumberOfLines`value. You may change this property's value in the textView.

By default, the number of lines is set to best fit each device dimensions:
- iPhone 4      (<=480pts): 4 lines
- iPhone 5/6    (>=568pts): 6 lines
- iPad          (>=768pts): 8 lines

On iPhone devices, in landscape orientation, the maximum number of lines is changed to fit the available space.


### Inverted Mode

Some layouts may require to show from bottom to top and new subviews are inserted from the bottom. To enable this, you must use the `inverted` flag property (default is `YES`/`true`). This will actually invert the entire ScrollView object. Make sure to apply the same transformation to every subview. In the case of UITableView, the best place for adjusting the transformation is in its data source methods like:
##### Obj-C
```objc
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    cell.transform = self.tableView.transform;
}
```
##### Swift
```swift
override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
    if let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) {
        cell.transform = self.tableView.transform
    }
}
```


### Autocompletion

We use autocompletion for many things: names, channels, emoji, and more.

![Autocompletion](Screenshots/screenshot_auto-completion.png)

To set up autocompletion in your app, follow these simple steps:

#### 1. Registration
You must first register all the prefixes you'd like to support for autocompletion detection:
##### Obj-C
```objc
[self registerPrefixesForAutoCompletion:@[@"#"]];
```
##### Swift
```swift
self.registerPrefixesForAutoCompletion(["@", "#"])
```

#### 2. Processing
Every time a new character is inserted in the text view, the nearest word to the caret will be processed and verified if it contains any of the registered prefixes.

Once the prefix has been detected, `didChangeAutoCompletionPrefix:andWord:` will be called. This is the perfect place to populate your data source and show/hide the autocompletion view. So you must override it in your subclass, to be able to perform additional tasks. Default returns NO.
##### Obj-C
```objc
- (void)didChangeAutoCompletionPrefix:(NSString *)prefix andWord:(NSString *)word
{
    NSArray *array = [NSArray arrayWithArray:self.channels];
    
    if ([prefix isEqualToString:@"#"] && word.length > 0) {
        self.searchResult = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c]", word]];
    }
    
    BOOL show = (self.searchResult.count > 0);
    
    [self showAutoCompletionView:show];
}
```
##### Swift
```swift
override func didChangeAutoCompletionPrefix(prefix: String, andWord word: String) {
    
    let array: NSArray = self.channels
    
    if prefix == "#" && word.characters.count > 0 {
        self.searchResult = array.filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
    }
    
    let show = (self.searchResult.count > 0)
    
    self.showAutoCompletionView(show)
}
```

The autocompletion view is a `UITableView` instance, so you will need to use `UITableViewDataSource` to populate its cells. You have complete freedom for customizing the cells.

You don't need to call `reloadData` yourself, since it will be invoked automatically right after calling the `showAutoCompletionView` method.

#### 3. Layout

The maximum height of the autocompletion view is set to 140 pts by default. You can update this value anytime, so the view automatically adjusts based on the amount of displayed cells.
##### Obj-C
```objc
- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = 34.0;
    return cellHeight*self.searchResult.count;
}
```
##### Swift
```swift
override func heightForAutoCompletionView() -> CGFloat {
    let cellHeight:CGFloat = 34
    return cellHeight * CGFloat(self.searchResult.count)
}
```

#### 4. Confirmation

If the user selects any autocompletion view cell on `tableView:didSelectRowAtIndexPath:`, you must call `acceptAutoCompletionWithString:` to commit autocompletion. That method expects a string matching the selected item, that you would like to be inserted in the text view.
##### Obj-C
```objc
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
        NSMutableString *item = [self.searchResult[indexPath.row] mutableCopy];
        [item appendString:@" "]; // Adding a space helps dismissing the auto-completion view
        
        [self acceptAutoCompletionWithString:item keepPrefix:YES];
    }
}
```
##### Swift
```swift
override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    if tableView.isEqual(tableView) {
        var item = self.searchResult[indexPath.row]
        item += " "  // Adding a space helps dismissing the auto-completion view
            
        self.acceptAutoCompletionWithString(item)
    }
}
```

The autocompletion view will automatically be dismissed and the chosen string will be inserted in the text view, replacing the detected prefix and word.

You can always call `cancelAutoCompletion` to exit the autocompletion mode and refresh the UI.


### Edit Mode

![Edit Mode](Screenshots/screenshot_edit-mode.png)

To enable edit mode, you simply need to call `editText:`, and the text input will switch to edit mode, removing both left and right buttons, extending the input bar a bit higher with "Accept" and "Cancel" buttons. Both of this buttons are accessible in the `SLKTextInputbar` instance for customisation.

To capture the "Accept" or "Cancel" events, you must override the following methods.
##### Obj-C
```objc
- (void)didCommitTextEditing:(id)sender
{
    NSString *message = [self.textView.text copy];
    
    [self.messages removeObjectAtIndex:0];
    [self.messages insertObject:message atIndex:0];
    [self.tableView reloadData];
    
    [super didCommitTextEditing:sender];
}

- (void)didCancelTextEditing:(id)sender
{
    [super didCancelTextEditing:sender];
}
```
##### Swift
```swift
override func didCommitTextEditing(sender: AnyObject) {
    
    let message:String = self.textView.text
    
    self.messages.removeAtIndex(0)
    self.messages.insert(message, atIndex: 0)
    
    self.tableView!.reloadData()
    
    super.didCommitTextEditing(sender)
}
 
override func didCancelTextEditing(sender: AnyObject) {
        
    super.didCancelTextEditing(sender)
}
```

Notice that you must call `super` at some point, so the text input exits the edit mode, re-adjusting the layout and clearing the text view.
Use the `editing` property to know if the editing mode is on.


### Markdown Formatting

![Markdown Formatting](Screenshots/screenshot_markdown-formatting.png)

You can register markdown formatting symbols so they can easily be used to wrap a text selection, with the help of the  native contextual menu, aka `UIMenuController`. This feature doesn't take care of the rendering of the markdown: it's sole purpose is to ease the formatting tools to the user.
Optionally, you can enable `autoCompleteFormatting` so any pending markdown closure symbol can be added automatically after double tapping on the keyboard spacebar, just like the native gesture to add a sentence period. The sentence period is still being added as a fallback.

![Markdown Formatting Animated](Screenshots/screenshot_markdown-formatting.gif)


#### 1. Registration

You must first register the formatting symbol and assign a title string to be used in the menu controller item.
##### Obj-C
```objc
[self.textView registerMarkdownFormattingSymbol:@"*" withTitle:@"Bold"];
```
##### Swift
```swift
self.textView.registerMarkdownFormattingSymbol("*", withTitle: "Bold")
```

#### 2. Customisation

Futher more, you can customise some of the behavior for special formatting cases, using the `UITextViewDelegate` methods.
In the following example, we don't present the Quote formatting in the contextual menu when the text selection isn't a paragraph.
##### Obj-C
```objc
- (BOOL)textView:(SLKTextView *)textView shouldOfferFormattingForSymbol:(NSString *)symbol
{
    if ([symbol isEqualToString:@">"]) {
        
        NSRange selection = textView.selectedRange;
        
        // The Quote formatting only applies new paragraphs
        if (selection.location == 0 && selection.length > 0) {
            return YES;
        }
        
        // or older paragraphs too
        NSString *prevString = [textView.text substringWithRange:NSMakeRange(selection.location-1, 1)];
        
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[prevString characterAtIndex:0]]) {
            return YES;
        }

        return NO;
    }
    
    return [super textView:textView shouldOfferFormattingForSymbol:symbol];
}
```

In this other method implementation, we don't want to allow auto-completion for the Quote formatting since it doesn't require a closure.
##### Obj-C
```objc
- (BOOL)textView:(SLKTextView *)textView shouldInsertSuffixForFormattingWithSymbol:(NSString *)symbol prefixRange:(NSRange)prefixRange
{
    if ([symbol isEqualToString:@">"]) {
        return NO;
    }
    
    return [super textView:textView shouldInsertSuffixForFormattingWithSymbol:symbol prefixRange:prefixRange];
}
```


### Typing Indicator

![Typing Indicator](Screenshots/screenshot_typing-indicator.png)

Optionally, you can enable a simple typing indicator, which will be displayed right above the text input. It shows the name of the people that are typing, and if more than 2, it will display "Several are typing" message.

To enable the typing indicator, just call:
##### Obj-C
```objc
[self.typingIndicatorView insertUsername:@"John"];
```
##### Swift
```swift
self.typingIndicatorView?.insertUsername("John")
```

and the view will automatically be animated on top of the text input. After a default interval of 6 seconds, if the same name hasn't been assigned once more, the view will be dismissed with animation.

You can remove names from the list by calling:
##### Obj-C
```objc
[self.typingIndicatorView removeUsername:@"John"];
```
##### Swift
```swift
self.typingIndicatorView?.removeUsername("John")
```

You can also dismiss it by calling:
##### Obj-C
```objc
[self.typingIndicatorView dismissIndicator];
```
##### Swift
```swift
self.typingIndicatorView?.dismissIndicator()
```

### Panning Gesture

Dismissing the keyboard with a panning gesture is enabled by default with the `keyboardPanningEnabled` property. You can always disable it if you'd like. You can extend the `verticalPanGesture` behaviors with the `UIGestureRecognizerDelegate` methods.


### Hideable TextInputbar

Sometimes you may need to hide the text input bar.
Very similar to `UINavigationViewController`'s API, simply do:
##### Obj-C
```objc
[self setTextInputbarHidden:YES animated:YES];
```
##### Swift
```swift
self.setTextInputbarHidden(true, animated: true)
```


### Shake Gesture

![Shake Gesture](Screenshots/screenshot_shake-undo.png)

A shake gesture to clear text is enabled by default with the `undoShakingEnabled` property.

You can optionally override `willRequestUndo`, to implement your UI to ask the users if he would like to clean the text view's text. If there is not text entered, the method will not be called.

If you don't override `willRequestUndo` and `undoShakingEnabled` is set to `YES`/`true`, a system alert will be shown.


### External Keyboard

There a few basic key commands enabled by default:
- cmd + z -> undo
- shift + cmd + z -> redo
- return key -> calls `didPressRightButton:`, or `didCommitTextEditing:` if in edit mode
- shift/cmd + return key -> line break
- escape key -> exits edit mode, or auto-completion mode, or dismisses the keyboard
- up & down arrows -> vertical cursor movement

To add additional key commands, simply override `keyCommands` and append `super`'s array.
##### Obj-C
```objc
- (NSArray *)keyCommands
{
    NSMutableArray *commands = [NSMutableArray arrayWithArray:[super keyCommands]];
    
    // Edit last message
    [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                           modifierFlags:0
                                                   action:@selector(editLastMessage:)]];
    
    return commands;
}
```
##### Swift
```swift
override var keyCommands: [UIKeyCommand]? {
        
    var commands = super.keyCommands
        
    // Edit last message
    let command = UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: .Command, action: "editLastMessage:")
    commands?.append(command)
        
    return commands
}
```

There are also a set of useful flags for keyboard special detections such as `isExternalKeyboardDetected`, `isKeyboardUndocked`, `typingSuggestionEnabled` and `isTrackpadEnabled` (iOS 9 only)


### Dynamic Type

Dynamic Type is enabled by default with the `dynamicTypeEnabled` property. You can always disable it if you'd like, but the text input bar would still adjust to best fit the font size of the text view.

![Dynamic-Type](Screenshots/screenshot_dynamic-type.png)


### Xcode Templates

![Template](Screenshots/screenshot_template.png)

We have prepared a set of useful Xcode templates so you can quickly start using SlackTextViewController.

To install them, open up your terminal and type:
```bash
sh ./SlackTextViewController/File\ Templates/install.sh
```

These templates are also available in [Alcatraz](https://github.com/alcatraz/Alcatraz).
