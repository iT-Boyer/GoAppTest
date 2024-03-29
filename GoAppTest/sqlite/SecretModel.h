//
//  SecretModel.h
//  GoAppTest
//
//  Created by pengyucheng on 14-3-24.
//  Copyright (c) 2014年 sqliteTest. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LKDaoBase.h"

@interface SecretModelBase : LKDAOBase

@end


@interface SecretModel : LKModelBase

@property int rowid;
//@property(nonatomic,assign)NSInteger Bid;
@property(nonatomic,copy)NSString *logName;
@property(nonatomic,copy)NSString *fileName;
@property(nonatomic,copy)NSString *makeTime;
@property(nonatomic,copy)NSString *fileType;
@property(nonatomic,copy)NSString *filePath;
@end