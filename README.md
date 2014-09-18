Slack Chat Kit
=============================================
[![Pod Version](http://img.shields.io/cocoapods/v/SlackChatKit.svg)](https://cocoadocs.org/docsets/SlackChatKit)
[![License](http://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)

A drop-in (and non-hacky) replacement of UITableViewController & UICollectionViewController, with growing text view and many other useful chat features. SCKChatViewController has beeen designed as a template view controller to be subclassed, overriding forward methods for performing additional logic.

This library is part of Slack's iOS UI foundations, specially designed and coded to best fit its needs, while still being flexible enough to be reused by others wanting to build great chat clients for iOS.

## Features

### Core
- UITableView/UICollectionView support
- Works completly with Auto-Layout, being flexible enough to any iOS8 Size Classes
- Totally customizable by exposing left and right buttons, text view and tool bar.
- Auto-expanding text view, with lines limit support
- Auto-completion mode by registering any prefix key (@,#,/, and so on)
- Tap gesture for dissmissing text input
- Useful text appending APIs
- External keyboard support for basic commands.
- Auto-orientation support
- Localization support
- iPhone and iPad support
- iOS 7 and 8 compatible

### Optional
- Edition mode
- Typing indicator display (as user name list)
- Panning gesture for gradually dissmissing the text input and keyboard
- Shake gesture for undoing typed text
- Image pasting support
- Left accesorry button
- Inverted mode for displaying cells from bottom (using CATransform)
- bouncing effect in animations

## Installation

Available in [Cocoa Pods](http://cocoapods.org/?q=SlackChatKit)
```
pod 'SlackChatKit'
```

##How to use

###Subclassing
`SCKChatViewController` is meant to be suclassed, like you would normally do with UITableViewController or UICollectionViewController. This pattern is by far the more convinient way of extending a ViewController behaviours, managing all the magic behind the scene while you still being able to intervene with custom behaviours, overriding forwarding methods, and deciding either to call super and  perform additional logic, or not to call super and override default logic.

Start by creating a new instance sublass of `SCKChatViewController`.

In the init overriding method, if you wish to use a the `UITableView` version, call:
```
[super initWithStyle:UITableViewStylePlain]
```

or the `UICollectionView` version:
```
[super initWithCollectionViewLayout:[UICollectionViewFlowLayout new]]
```


Protocols like `UITableViewDelegate` and `UITableViewDataSource` are already setup for you. You will be able to call whathever delegate and data source methods you need for customising your control.

Calling `[super init]` will call by default `[super initWithStyle:UITableViewStylePlain]`.


###Auto-expanding Text View

The text view expands automatically when a new line is requiered, until it reaches its `maxNumberOfLines`value. You may change this property's value in the textView.

By default, the number of lines is set to best fit each device dimensions:
- iPhone 4      (<=480pts): 4 lines
- iPhone 5/6    (>=568pts): 6 lines
- iPad          (>=768pts): 8 lines: 8 lines

On iPhone devices, in landscape orientation, the maximum number of lines is changed to 2 to best fit the limited height.

###Right Button

###Left Button

###Auto-Completion

At Slack we use auto-completion mechanism for many things such as completing user names, channel titles, emoji aliases and more. It is a great tool for users to quickly type repeated thing.

![Auto-Completion](Screenshots/screenshot_auto-completion.png)

Enabling auto-completion for your application is really easy.
Just follow these simple steps:

#### 1. Registration
You must first register all the prefixes you'd like to support for auto-completion detection:
````
[self registerPrefixesForAutoCompletion:@[@"#"]];
````

#### 2. Processing
Every time a new character is inserted in the text view, the nearest word to the caret will be processed and verified if it contains any of the registered prefixes.

Once the prefix has been detected, `-canShowAutoCompletion` will be called. This is the perfect place to populate your data source, and return a BOOL if the auto-completion view should actually be shown. So you must override it in your subclass, to be able to perform additional tasks. Default returns NO.

````
- (BOOL)canShowAutoCompletion
{
    NSString *prefix = self.foundPrefix;
    NSString *word = self.foundWord;
    
    self.searchResult = [[NSArray alloc] initWithArray:self.channels];
    
    if ([prefix isEqualToString:@"#"])
    {
        if (word.length > 0) {
            self.searchResult = [self.searchResult filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@ AND self !=[c] %@", word, word]];
        }
    }

    if (self.searchResult.count > 0) {
        self.searchResult = [self.searchResult sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    return self.searchResult.count > 0;
}
````

The auto-completion view is a UITableView instance, so you will need to use `UITableViewDataSource` to populate its cells. You also have total freedom for customising the UITableViewCells displayed here.

You don't need to call `-reloadData`, since it will be called automatically if you return `YES` in `-canShowAutoCompletion`.

#### 3. Layout

The maximum height of the auto-completion view is set to 140 pts, but you may change the minimum height depending of the amount of cells you are going to display in this tableview.

````
- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.count;
}
````

#### 4. Confirmation

If the user selects any cells presented in the auto-completion view, calling `-tableView:didSelectRowAtIndexPath:`, you must call `-acceptAutoCompletionWithString:` passing the corresponding string matching that item, that you would be insert in the text view.

`````
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
        NSString *item = self.searchResult[indexPath.row];
        
        [self acceptAutoCompletionWithString:item];
    }
}
````

The auto-completion view will automatically be dismissed, and the picked string will be inserted in the view right after the prefix string.

You can always can `-cancelAutoCompletion` for exiting the auto-completion mode.


Auto-completion has been designed to work with local data for now. It hasn't been tested with data being fetched from a remote server.

###Edition Mode

###External Keyboard

###Typing Indicator

###Panning Gesture

###Shake Gesture

###Inverted Mode


## License
(The MIT License)

Copyright (c) 2014 Slack Technologies, Inc. <hello@slack.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
