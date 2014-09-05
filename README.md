Slack Chat Kit
=============================================
[![Pod Version](http://img.shields.io/cocoapods/v/SlackChatKit.svg)](https://cocoadocs.org/docsets/SlackChatKit)
[![License](http://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)

A drop-in (and non-hacky) replacement of UITableViewController & UICollectionViewController, with growing text view and many other useful chat features. SCKChatViewController has beeen designed as a template view controller to be subclassed, overriding forward methods for performing additional logic.

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

###Right Button

###Left Button

###Auto-Completion

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
