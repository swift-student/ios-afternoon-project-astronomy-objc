//
//  SSSLoadImageOperation.m
//  Astronomy
//
//  Created by Shawn Gee on 5/19/20.
//  Copyright © 2020 Swift Student. All rights reserved.
//

#import "SSSLoadImageOperation.h"
#import "SSSFetchImageOperation.h"

@interface SSSLoadImageOperation ()

@property (class, nonatomic, readonly) NSOperationQueue *loadImageQueue;
@property (class, nonatomic, readonly) NSCache *imageCache;

@property (nonatomic, readonly) SSSFetchImageOperation *fetchImageOperation;
@property (nonatomic, readonly) NSBlockOperation *cacheImageOperation;
@property (nonatomic, readonly) NSBlockOperation *updateImageViewOperation;

@end

@implementation SSSLoadImageOperation

static NSOperationQueue *_loadImageQueue;
static NSCache *_imageCache;

@synthesize updateImageViewOperation = _updateImageViewOperation;
@synthesize cacheImageOperation = _cacheImageOperation;
@synthesize fetchImageOperation = _fetchImageOperation;

// MARK: - Class Properties

+ (NSOperationQueue *)loadImageQueue {
    if (!_loadImageQueue) {
        _loadImageQueue = [[NSOperationQueue alloc] init];
    }
    
    return _loadImageQueue;
}

+ (NSCache *)imageCache {
    if (!_imageCache) {
        _imageCache = [[NSCache alloc] init];
    }
    
    return _imageCache;
}

// MARK: - Init

- (instancetype)initWithURL:(NSURL *)url
                  imageView:(UIImageView *)imageView {
    self = [super init];
    if (!self) { return nil; }
    
    _url = url;
    _imageView = imageView;
    [SSSLoadImageOperation.loadImageQueue addOperation:self];
    
    return self;
}

// MARK: - Operations

- (SSSFetchImageOperation *)fetchImageOperation {
    if (!_fetchImageOperation) {
        _fetchImageOperation = [[SSSFetchImageOperation alloc] initWithImageURL:self.url];
    }
    
    return _fetchImageOperation;
}

- (NSBlockOperation *)cacheImageOperation {
    if (!_cacheImageOperation) {
        _cacheImageOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (self.isCancelled) { return; }
            
            NSData *imageData = self.fetchImageOperation.imageData;
            if (imageData) {
                [SSSLoadImageOperation.imageCache setObject:imageData forKey:self.url.absoluteString cost:imageData.length];
            }
        }];
    }
    
    return _cacheImageOperation;
}

- (NSBlockOperation *)updateImageViewOperation {
    if (!_updateImageViewOperation) {
        _updateImageViewOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (self.isCancelled) { return; }
            
            NSData *imageData = self.fetchImageOperation.imageData;
            self.imageView.image = [UIImage imageWithData:imageData];
        }];
    }
    
    return _updateImageViewOperation;
}

// MARK: - Lifecycle Methods

- (void)main {
    
    // Check for cached image
    NSData *imageData = [SSSLoadImageOperation.imageCache objectForKey:self.url.absoluteString];
    
    if (imageData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [UIImage imageWithData:imageData];
            [self finish];
            return;
        });
    }
    
    [self.updateImageViewOperation addDependency:self.fetchImageOperation];
    [self.cacheImageOperation addDependency:self.fetchImageOperation];
    [NSOperationQueue.currentQueue addOperations:@[self.fetchImageOperation, self.cacheImageOperation] waitUntilFinished:NO];
    [NSOperationQueue.mainQueue addOperations:@[self.updateImageViewOperation] waitUntilFinished:YES];
    [self finish];
}

- (void)cancel {
    [self.fetchImageOperation cancel];
}

@end

