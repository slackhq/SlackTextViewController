/*
 *        __                                 ____
 *       / /   ____  ________  ____ ___     /  _/___  _______  ______ ___
 *      / /   / __ \/ ___/ _ \/ __ `__ \    / // __ \/ ___/ / / / __ `__ \
 *     / /___/ /_/ / /  /  __/ / / / / /  _/ // /_/ (__  ) /_/ / / / / / /
 *    /_____/\____/_/   \___/_/ /_/ /_/  /___/ .___/____/\__,_/_/ /_/ /_/
 *                                          /_/
 *
 *                                 LoremIpsum.h
 *                   http://github.com/lukaskubanek/LoremIpsum
 *             2013-2014 (c) Lukas Kubanek (http://lukaskubanek.com)
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

typedef NS_ENUM(NSInteger, LIPlaceholderImageService)
{
    LIPlaceholderImageServiceLoremPixel,
    LIPlaceholderImageServiceHhhhold,
    LIPlaceholderImageServiceDummyImage,
    LIPlaceholderImageServicePlaceKitten,
    LIPlaceholderImageServiceDefault = LIPlaceholderImageServiceLoremPixel
};

@interface LoremIpsum : NSObject

///-------------------------------
/// @name Texts
///-------------------------------

/**
 * Generates a random single word.
 */
+ (NSString *)word;

/**
 * Generates random words separated by a space character.
 *
 * @param numberOfWords The number of generated words.
 */
+ (NSString *)wordsWithNumber:(NSInteger)numberOfWords;

/**
 * Generates a random sentence.
 */
+ (NSString *)sentence;

/**
 * Generates random concatenated sentences.
 *
 * @param numberOfSentences The number of generated sentences.
 */
+ (NSString *)sentencesWithNumber:(NSInteger)numberOfSentences;

/**
 * Generates a random paragraph with multiple sentences.
 */
+ (NSString *)paragraph;

/**
 * Generates random paragraphs joined by a new line character.
 *
 * @param numberOfParagraphs The number of generated paragraphs.
 */
+ (NSString *)paragraphsWithNumber:(NSInteger)numberOfParagraphs;

/**
 * Generates a random title.
 */
+ (NSString *)title;

///-------------------------------
/// @name Misc Data
///-------------------------------

/**
 * Generates a random name consisting of a first and a last name.
 */
+ (NSString *)name;

/**
 * Generates a random first name.
 */
+ (NSString *)firstName;

/**
 * Generates a random last name.
 */
+ (NSString *)lastName;

/**
 * Generates a random email address.
 */
+ (NSString *)email;

/**
 * Generates a random URL address with the HTTP prefix.
 */
+ (NSURL *)URL;

/**
 * Generates a sample tweet with 140 characters.
 */
+ (NSString *)tweet;

/**
 * Generates a random date and time within the last 4 years.
 */
+ (NSDate *)date;

///-------------------------------
/// @name Images
///-------------------------------

#if TARGET_OS_IPHONE

/**
 * Returns an URL for a placeholder image with the given size.
 *
 * @param size The desired size of the image.
 */
+ (NSURL *)URLForPlaceholderImageWithSize:(CGSize)size;

/**
 * Returns an URL for a placeholder image from the given image service and with the given size.
 *
 * @param service The image service.
 * @param size The desired size of the image.
 */
+ (NSURL *)URLForPlaceholderImageFromService:(LIPlaceholderImageService)service
                                    withSize:(CGSize)size;

/**
 * Returns a placeholder image with the given size.
 *
 * @param size The desired size of the image.
 */
+ (UIImage *)placeholderImageWithSize:(CGSize)size;

/**
 * Returns a placeholder image from the given image service and with the given size.
 *
 * @param service The image service.
 * @param size The desired size of the image.
 */
+ (UIImage *)placeholderImageFromService:(LIPlaceholderImageService)service
                                withSize:(CGSize)size;

/**
 * Asynchronously loads a placeholder image with the given size and executes the completion block.
 *
 * @param size The desired size of the image.
 * @param completion The completion block which is executed asynchronously after the loading the image.
 */
+ (void)asyncPlaceholderImageWithSize:(CGSize)size
                           completion:(void (^)(UIImage *image))completion;

/**
 * Asynchronously loads a placeholder image from the given image service with the given size
 * and executes the completion block.
 *
 * @param service The image service.
 * @param size The desired size of the image.
 * @param completion The completion block which is executed asynchronously after the loading the image.
 */
+ (void)asyncPlaceholderImageFromService:(LIPlaceholderImageService)service
                                withSize:(CGSize)size
                              completion:(void (^)(UIImage *image))completion;

#elif TARGET_OS_MAC

/**
 * Returns an URL for a placeholder image with the given size.
 *
 * @param size The desired size of the image.
 */
+ (NSURL *)URLForPlaceholderImageWithSize:(NSSize)size;

/**
 * Returns an URL for a placeholder image from the given image service and with the given size.
 *
 * @param service The image service.
 * @param size The desired size of the image.
 */
+ (NSURL *)URLForPlaceholderImageFromService:(LIPlaceholderImageService)service
                                    withSize:(NSSize)size;

/**
 * Returns a placeholder image with the given size.
 *
 * @param size The desired size of the image.
 */
+ (NSImage *)placeholderImageWithSize:(NSSize)size;

/**
 * Returns a placeholder image from the given image service and with the given size.
 *
 * @param service The image service.
 * @param size The desired size of the image.
 */
+ (NSImage *)placeholderImageFromService:(LIPlaceholderImageService)service
                                withSize:(NSSize)size;

/**
 * Asynchronously loads a placeholder image with the given size and executes the completion block.
 *
 * @param size The desired size of the image.
 * @param completion The completion block which is executed asynchronously after the loading the image.
 */
+ (void)asyncPlaceholderImageWithSize:(NSSize)size
                           completion:(void (^)(NSImage *image))completion;

/**
 * Asynchronously loads a placeholder image from the given image service with the given size
 * and executes the completion block.
 *
 * @param service The image service.
 * @param size The desired size of the image.
 * @param completion The completion block which is executed asynchronously after the loading the image.
 */
+ (void)asyncPlaceholderImageFromService:(LIPlaceholderImageService)service
                                withSize:(NSSize)size
                              completion:(void (^)(NSImage *image))completion;

#endif

@end
