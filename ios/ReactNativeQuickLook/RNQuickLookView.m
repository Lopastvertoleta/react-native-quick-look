//
//  RNQuickLookView.m
//
//  Created by Rahul Jiresal on 7/15/16.
//  Copyright © 2016 Air Computing Inc. All rights reserved.
//

#import "RNQuickLookView.h"
#import <QuickLook/QuickLook.h>

@interface RNQuickLookView () <QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property UIView* previewView;
@property QLPreviewController* previewCtrl;
@property NSURL* fileURL;
@end

@implementation RNQuickLookView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
    
}

- (instancetype)initWithPreviewItemUrl:(NSString*)url {
    NSAssert(url != nil, @"Preview Item URL cannot be nil");
    self = [super init];
    if (self) {
        _url = url;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.previewCtrl = [[QLPreviewController alloc] init];
    self.previewCtrl.delegate = self;
    self.previewCtrl.dataSource = self;
    self.previewView = self.previewCtrl.view;
    self.clipsToBounds = YES;
    [self addSubview:self.previewCtrl.view];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.previewView setFrame:self.frame];
}

- (void)setUrl:(NSString *)urlString {
    _url = [urlString stringByRemovingPercentEncoding];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSURL* remoteFileURL = [NSURL URLWithString:[_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (!remoteFileURL) {
            return;
        }
        NSString* fileName = [[_url lastPathComponent] stringByReplacingOccurrencesOfString:@"?dl=1" withString:@""];
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docPath_ = [paths objectAtIndex:0];
        NSString* filePath = [docPath_ stringByAppendingPathComponent:fileName];
        
        NSURL* fileURL = [NSURL fileURLWithPath:filePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) [[NSData dataWithContentsOfURL:remoteFileURL] writeToURL:fileURL atomically:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setFileURL:fileURL];
            [[self previewCtrl] refreshCurrentPreviewItem];
        });
    });
}

- (void)setAssetFileName:(NSString*)filename {
    _url = [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
    [self.previewCtrl refreshCurrentPreviewItem];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    
    return [self fileURL];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

@end
