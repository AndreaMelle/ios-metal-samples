//
//  OBJModel.h
//  UpAndRunning3D
//
//  Created by Warren Moore on 9/11/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBJGroup;

@interface OBJModel : NSObject

- (instancetype)initWithContentsOfURL:(NSURL *)fileURL generateNormals:(BOOL)generateNormals;

// Index 0 corresponds to an unnamed group that collects all the geometry
// declared outside of explicit "g" statements. Therefore, if your file
// contains explicit groups, you'll probably want to start from index 1,
// which will be the group defined starting at the first group statement.
@property (nonatomic, readonly) NSArray *groups;

@end
