#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class PDF21MDImageElement;

/**
 * Manages the extraction and saving of assets (images) from PDF documents.
 * Thread-safe for concurrent image saving operations.
 */
@interface PDF21MDAssetManager : NSObject

/**
 * The base folder path where assets will be saved.
 */
@property (nonatomic, copy, readonly) NSString *assetsFolderPath;

/**
 * Initializes the asset manager with a folder path.
 * Creates the folder if it doesn't exist.
 *
 * @param folderPath The path where assets will be saved
 * @return A new instance, or nil if folder creation fails
 */
- (nullable instancetype)initWithAssetFolder:(NSString *)folderPath NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Saves an image to the assets folder with automatic format selection.
 *
 * @param image The CGImage to save
 * @param isVectorSource Whether this image originated from vector graphics
 * @param baseName The base filename (without extension)
 * @return The relative path to the saved file, or nil on failure
 */
- (nullable NSString *)saveImage:(CGImageRef)image
                  isVectorSource:(BOOL)isVectorSource
                    withBaseName:(NSString *)baseName;

/**
 * Saves an image element to the assets folder.
 * Updates the element's assetRelativePath property on success.
 *
 * @param imageElement The image element to save
 * @param baseName The base filename (without extension)
 * @return The relative path to the saved file, or nil on failure
 */
- (nullable NSString *)saveImageElement:(PDF21MDImageElement *)imageElement
                           withBaseName:(NSString *)baseName;


/**
 * Gets the next available filename for the given base name.
 * Handles conflicts by appending numbers.
 *
 * @param baseName The desired base filename
 * @param extension The file extension (without dot)
 * @return A unique filename
 */
- (NSString *)uniqueFilenameForBaseName:(NSString *)baseName
                          withExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END