//
//  SLKTextViewControllerStub.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "SLKTextViewControllerStub.h"
#import "NSString+LoremIpsum.h"

@interface SLKTextViewControllerStub ()
@property (nonatomic, strong) NSArray *usernames;
@property (nonatomic, strong) NSArray *searchResult;
@end

@implementation SLKTextViewControllerStub

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    self.usernames = @[@"Allen", @"Anna", @"Alicia", @"Arnold", @"Armando", @"Antonio", @"Brad", @"Catalaya", @"Christoph", @"Emerson", @"Eric", @"Everyone", @"Steve"];
    
    [self registerPrefixesForAutoCompletion:@[@"@"]];
}


#pragma mark - Auto-Completion Methods

- (BOOL)canShowAutoCompletion
{
    NSArray *array = nil;
    NSString *prefix = self.foundPrefix;
    NSString *word = self.foundWord;
    
    self.searchResult = nil;
    
    if ([prefix isEqualToString:@"@"]) {
        if (word.length > 0) {
            array = [self.usernames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.usernames;
        }
    }
    
    if (array.count > 0) {
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult = [[NSArray alloc] initWithArray:array];
    
    return self.searchResult.count > 0;
}

- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.count;
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompletionView]) {
        return self.searchResult.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
        static NSString *cellIdentifier = @"cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        cell.textLabel.text = self.searchResult[indexPath.row];
        
        return cell;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

@end
