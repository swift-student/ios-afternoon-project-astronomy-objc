//
//  SSSConcurrentOperation.h
//  Astronomy
//
//  Created by Shawn Gee on 5/19/20.
//  Copyright © 2020 Swift Student. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SSSConcurrentOperationState) {
    SSSConcurrentOperationStateReady,
    SSSConcurrentOperationStateExecuting,
    SSSConcurrentOperationStateFinished
};

NS_ASSUME_NONNULL_BEGIN

@interface SSSConcurrentOperation : NSOperation

@property SSSConcurrentOperationState state;

- (void)finish;

@end

NS_ASSUME_NONNULL_END
