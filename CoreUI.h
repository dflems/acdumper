// A subset of private APIs from CoreUI.framework

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CUINamedLookup: NSObject
- (NSString *)name;
@end

@interface CUICatalog: NSObject
- (instancetype)initWithURL:(NSURL *)url error:(NSError * __autoreleasing *)error;
- (NSArray<NSString *> *)allImageNames;
- (NSArray<CUINamedLookup *> *)imagesWithName:(NSString *)name;
@end

@interface CUINamedData: CUINamedLookup
- (NSData *)data;
- (NSString *)utiType;
@end

@interface CUINamedImage: CUINamedLookup
- (double)scale;
- (long long)idiom;
- (CGSize)size;
- (CGImageRef)image;
@end

@interface CUINamedMultisizeImageSet: CUINamedLookup
@end

NS_ASSUME_NONNULL_END
