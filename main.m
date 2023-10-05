#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "CoreUI.h"

static void mkdir_p(NSString *path);
static NSString * getUTFileExtension(NSString *identifier);
static BOOL writeImageAsPNG(CGImageRef image, NSString *path);
static BOOL writeData(NSData *data, NSString *path);

@interface CUINamedImage (Extensions)
- (NSString *)fullyQualifiedImageName;
@end

int run(NSString *input, NSString *output)
{
    NSError *error = nil;
    CUICatalog *catalog = [[CUICatalog alloc] initWithURL:[NSURL fileURLWithPath:input] error:&error];

    for (NSString *name in [catalog allImageNames]) {
        // `images` includes mixed data and images despite the name
        NSArray<CUINamedLookup *> *images = [catalog imagesWithName:name];
        if (images.count == 0) {
            continue;
        }

        // data assets are a single CUINamedData
        if (images.count == 1 && [images[0] isKindOfClass:[CUINamedData class]]) {
            CUINamedData *namedData = (CUINamedData *)images[0];
            NSString *extension = getUTFileExtension(namedData.utiType);
            NSString *filename = [NSString stringWithFormat:@"%@.%@", namedData.name, extension];
            NSString *outputPath = [NSString pathWithComponents:@[output, filename]];
            writeData(namedData.data, outputPath);
            continue;
        }

        for (CUINamedLookup *raw in images) {
            if ([raw isKindOfClass:[CUINamedImage class]]) {
                CUINamedImage *image = (CUINamedImage *)raw;
                NSString *filename = [NSString stringWithFormat:@"%@.png", [image fullyQualifiedImageName]];
                NSString *outputPath = [NSString pathWithComponents:@[output, filename]];
                writeImageAsPNG(image.image, outputPath);
            } else if ([raw isKindOfClass:[CUINamedMultisizeImageSet class]]) {
                // no-op, this is a placeholder
                // `CUINamedImage` instances are in the same list
            } else {
                NSLog(@"UNK - %@ - %@", name, raw);
            }
        }
    }

    return 0;
}

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        if (argc != 3) {
            printf("usage: %s Assets.car output-dir\n", argv[0]);
            exit(1);
        }
        return run(@(argv[1]), @(argv[2]));
    }
}

@implementation CUINamedImage (Extensions)

- (NSString *)fullyQualifiedImageName
{
    return [NSString stringWithFormat:@"%@%@%@%@", self.name, self.idiomSuffix, self.sizeSuffix, self.scaleSuffix];
}

- (NSString *)idiomSuffix
{
    switch (self.idiom) {
        case 0:
            return @"";
        case 1:
            return @"~iphone";
        case 2:
            return @"~ipad";
        case 3:
            return @"~tv";
        case 4:
            return @"~carplay";
        case 5:
            return @"~watch";
        case 6:
            return @"~marketing";
        default:
            return @"~unk";
    }
}

- (NSString *)sizeSuffix
{
    return [NSString stringWithFormat:@"~%dx%d", (int)self.size.width, (int)self.size.height];
}

- (NSString *)scaleSuffix
{
    return (self.scale < 2) ? @"" : [NSString stringWithFormat:@"@%dx", (int)self.scale];
}

@end

static void mkdir_p(NSString *path)
{
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}

static NSString * getUTFileExtension(NSString *identifier)
{
    if (identifier) {
        // sometimes the identifier has a zero-width space in it for some reason
        identifier = [identifier stringByReplacingOccurrencesOfString:@"​" withString:@""];

        UTType *type = [UTType typeWithIdentifier:identifier];
        if (type) {
            return type.preferredFilenameExtension;
        }
        NSArray *parts = [identifier componentsSeparatedByString:@"."];
        if (parts.count == 2 && [parts[0] isEqualToString:@"public"]) {
            return parts[1];
        }
    }
    // cannot determine file extension
    return @"unk";
}

static BOOL writeImageAsPNG(CGImageRef image, NSString *path)
{
    mkdir_p([path stringByDeletingLastPathComponent]);
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
        url, (__bridge CFStringRef)UTTypePNG.identifier, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    BOOL result = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    return result;
}

static BOOL writeData(NSData *data, NSString *path)
{
    return [(data ?: [NSData data]) writeToFile:path atomically:YES];
}
