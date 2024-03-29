//
//
//  Created by y h on 12-10-9.
//  Copyright (c) 2012年 SKY. All rights reserved.
//

#import "LKDAOBase.h"
#import <objc/runtime.h>
#import "JSONKit.h"
@implementation LKDAOBase
@synthesize columeNames;
@synthesize columeTypes;
@synthesize bindingQueue;
+(const NSString *)getTableName
{
    return @"";
}
+(Class)getBindingModelClass
{
    return [LKModelBase class];
}
-(id)initWithDBQueue:(FMDatabaseQueue *)queue
{
    self = [super init];
    if (self)
    {
        self.bindingQueue = queue;
        
        self.columeNames = [NSMutableArray arrayWithCapacity:16];
        self.columeTypes = [NSMutableArray arrayWithCapacity:16];
        
        //获取绑定的 Model 并 保存 Model 的属性信息
        NSDictionary* dic  = [[self.class getBindingModelClass] getPropertys];
        NSArray* pronames = [dic objectForKey:@"name"];
        NSArray* protypes = [dic objectForKey:@"type"];
        self.propertys = [NSMutableDictionary dictionaryWithObjects:protypes forKeys:pronames];
        for (int i =0; i<pronames.count; i++) {
            [self addColume:[pronames objectAtIndex:i] type:[protypes objectAtIndex:i]];
        }
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            onceCreateTable = [[NSMutableDictionary  alloc]initWithCapacity:8];
        });
        NSString* className = NSStringFromClass(self.class);
        NSNumber* onceToCreate = [onceCreateTable objectForKey:className];
        if(onceToCreate.boolValue == NO)
        {
            [self createTable];
            onceToCreate = [NSNumber numberWithBool:YES];
            [onceCreateTable setObject:onceToCreate forKey:className];
        }
    }
    return self;
    
}
-(void)dealloc
{
    self.bindingQueue = nil;
    self.propertys = nil;
    self.columeNames = nil;
    self.columeTypes = nil;
//    [super dealloc];
}
static NSMutableDictionary* onceCreateTable;
+(void)clearCreateHistory
{
    [onceCreateTable removeAllObjects];
}
-(void)createTable
{
    if([[self.class getTableName] isEmptyWithTrim])
    {
        NSLog(@"LKTableName is None!");
        return;
    }
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* createTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",[self.class getTableName],[self getParameterString]];
         [db executeUpdate:createTable];
     }];
}

-(void)addColume:(NSString *)name type:(NSString *)type
{
//    if ([name isEqualToString:@"Bid" ]) {
//        [columeNames addObject:name];
//        [columeTypes addObject:LKSQLIntPrimaryKey];
//        return;
//    }
    [columeNames addObject:name];
    [columeTypes addObject:[LKDAOBase toDBType:type]];
}

-(void)addColumePrimary:(NSString *)name type:(NSString *)type
{
    [columeNames addObject:name];
    [columeTypes addObject:[NSString stringWithFormat:@"%@ primary key",[LKDAOBase toDBType:type]]];
}

-(NSString *)getParameterString
{
    NSMutableString* pars = [NSMutableString string];
    for (int i=0; i<columeNames.count; i++) {
        [pars appendFormat:@"%@ %@",[columeNames objectAtIndex:i],[columeTypes objectAtIndex:i]];
        if(i+1 !=columeNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

-(void)searchAll:(void(^)(NSArray*))callback{
    [self searchWhere:nil orderBy:nil offset:0 count:15 callback:callback];
}
-(void)searchAllOrderBy:(NSString *)orderBy callback:(void(^)(NSArray*))callback
{
    [bindingQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *query = [NSMutableString stringWithFormat:@"select rowid,* from %@",[self.class getTableName]];
        if (orderBy != nil && ![orderBy isEmptyWithTrim]) {
            [query appendFormat:@" order by %@",orderBy];
        }
        FMResultSet* set =[db executeQuery:query];
        [self executeResult:set block:callback];
    }];
}
-(void)searchWhere:(NSString*)where callback:(void(^)(NSArray*))block{
    [self searchWhere:where orderBy:nil offset:0 count:15 callback:block];
}
-(void)searchWhereDic:(NSDictionary*)where callback:(void(^)(NSArray*))block{
    [self searchWhereDic:where orderBy:nil offset:0 count:15 callback:block];
}
-(void)searchWhere:(NSString *)where orderBy:(NSString *)orderBy offset:(int)offset count:(int)count callback:(void (^)(NSArray *))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@ ",[self.class getTableName]];
         if(where != nil && ![where isEmptyWithTrim])
         {
             [query appendFormat:@" where %@",where];
         }
         [self sqlString:query AddOder:orderBy offset:offset count:count];
         FMResultSet* set =[db executeQuery:query];
         [self executeResult:set block:block];
     }];
}
-(void)searchWhereDic:(NSDictionary*)where orderBy:(NSString *)orderby offset:(int)offset count:(int)count callback:(void (^)(NSArray *))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSMutableString* query = [NSMutableString stringWithFormat:@"select rowid,* from %@ ",[self.class getTableName]];
         
         NSMutableArray* values = [NSMutableArray arrayWithCapacity:0];
         if(where !=nil&& where.count>0)
         {
             NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
             [query appendFormat:@" where %@",wherekey];
         }
         [self sqlString:query AddOder:orderby offset:offset count:count];
        //执行sql
         FMResultSet* set =[db executeQuery:query withArgumentsInArray:values];
         //处理Sql返回值
         [self executeResult:set block:block];
     }];
}

//DESC：降序排序 ASC：升序排序  默认:ASC            //count大于0时，才会有分页查询
-(void)sqlString:(NSMutableString*)sql AddOder:(NSString*)orderby offset:(int)offset count:(int)count
{
    if(orderby != nil && ![orderby isEmptyWithTrim])
    {
        [sql appendFormat:@" order by %@ ",orderby];
    }
    
    if (count>0) {
        [sql appendFormat:@" limit %d offset %d ",count,offset];
    }
    
}


- (void)executeResult:(FMResultSet *)set block:(void (^)(NSArray *))block
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    while ([set next]) {
        NSObject<LKModelBaseInteface>* bindingModel = [[[self.class getBindingModelClass] alloc]init];
        bindingModel.rowid = [set intForColumnIndex:0];
        for (int i=0; i<self.columeNames.count; i++) {
            NSString* columeName = [self.columeNames objectAtIndex:i];
            NSString* columeType = [self.propertys objectForKey:columeName];
            if([@"intfloatdoublelongcharshort" rangeOfString:columeType].location != NSNotFound)
            {
                [bindingModel setValue:[NSNumber numberWithDouble:[set doubleForColumn:columeName]] forKey:columeName];
            }
            else if([columeType isEqualToString:@"NSString"])
            {
                [bindingModel setValue:[set stringForColumn:columeName] forKey:columeName];
            }
            else if([columeType isEqualToString:@"UIImage"])
            {
                NSString* filename = [set stringForColumn:columeName];
                if([SandboxFile IsFileExists:[SandboxFile GetPathForDocuments:filename inDir:@"dbImages"]])
                {
                    UIImage* img = [UIImage imageWithContentsOfFile:[SandboxFile GetPathForDocuments:filename inDir:@"dbImages"]];
                    [bindingModel setValue:img forKey:columeName];
                }
            }
            else if([columeType isEqualToString:@"NSDate"])
            {
                NSString* datestr = [set stringForColumn:columeName];
                [bindingModel setValue:[LKDAOBase dateWithString:datestr] forKey:columeName];
            }
            else if([columeType isEqualToString:@"NSData"])
            {
                NSString* filename = [set stringForColumn:columeName];
                if([SandboxFile IsFileExists:[SandboxFile GetPathForDocuments:filename inDir:@"dbData"]])
                {
                    NSData* data = [NSData dataWithContentsOfFile:[SandboxFile GetPathForDocuments:filename inDir:@"dbData"]];
                    [bindingModel setValue:data forKey:columeName];
                }
            }
            
        }
        [array addObject:bindingModel];
    }
    [set close];
    block(array);
}
-(void)insertToDB:(NSObject<LKModelBaseInteface> *)model callback:(void (^)(BOOL))block{
    
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSDate* date = [NSDate date];
         NSMutableString* insertKey = [NSMutableString stringWithCapacity:0];
         NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
         NSMutableArray* insertValues = [NSMutableArray arrayWithCapacity:self.columeNames.count];
         for (int i=0; i<self.columeNames.count; i++) {
             
             NSString* proname = [self.columeNames objectAtIndex:i];
             [insertKey appendFormat:@"%@,", proname];
             [insertValuesString appendString:@"?,"];
             id value =[self safetyGetModel:model valueKey:proname];
             if([value isKindOfClass:[UIImage class]])
             {
                 NSString* filename = [NSString stringWithFormat:@"img%f",[date timeIntervalSince1970]];
                 [UIImageJPEGRepresentation(value, 1) writeToFile:[SandboxFile GetPathForDocuments:filename inDir:@"dbImages"] atomically:YES];
                 value = filename;
             }
             else if([value isKindOfClass:[NSData class]])
             {
                 NSString* filename = [NSString stringWithFormat:@"data%f",[date timeIntervalSince1970]];
                 [value writeToFile:[SandboxFile GetPathForDocuments:filename inDir:@"dbdata"] atomically:YES];
                 value = filename;
             }
             else if([value isKindOfClass:[NSDate class]])
             {
                 value = [LKDAOBase stringWithDate:value];
             }
             [insertValues addObject:value];
         }
         [insertKey deleteCharactersInRange:NSMakeRange(insertKey.length - 1, 1)];
         [insertValuesString deleteCharactersInRange:NSMakeRange(insertValuesString.length - 1, 1)];
         NSString* insertSQL = [NSString stringWithFormat:@"insert into %@(%@) values(%@)",[self.class getTableName],insertKey,insertValuesString];
         BOOL execute = [db executeUpdate:insertSQL withArgumentsInArray:insertValues];
         model.rowid = db.lastInsertRowId;
         if(block != nil)
         {
             block(execute);
         }
         if(execute == NO)
         {
             NSLog(@"database insert fail %@",NSStringFromClass(model.class));
         }
     }];
}

-(void)updateToDBWithWhere:(NSString *)where columeName:(NSString *)columeName columeValue:(id)columeValue callback:(void(^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* updateSQL =[NSString stringWithFormat:@"update %@ set %@ = '%@' where %@",[self.class getTableName],columeName,columeValue,where];
         BOOL execute = [db executeUpdate:updateSQL];
         if(block != nil)
         {
             block(execute);
         }
         if(execute == NO)
         {
             NSLog(@"database update fail table: %@   ----->columeName: %@",[self.class getTableName],columeName);
         }
     }];
    
}

-(void)fetchToDBWithWhere:(NSString *)where columeName:(NSString *)columeName callback:(void(^)(NSString *))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* updateSQL =[NSString stringWithFormat:@"select %@ from %@ where %@",columeName,[self.class getTableName],where];
         FMResultSet* rs =[db executeQuery:updateSQL];
         while([rs next]){
             block ([rs stringForColumnIndex:0]);
         }
     }];
}


-(void)updateTable:(NSObject<LKModelBaseInteface> *)model callback:(void(^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         //重命名旧表，以便创建同名的新表
         NSString *tmptable =[NSString stringWithFormat:@"tem%@",[self.class getTableName]];
         NSString *renameSql = [NSString stringWithFormat:@"alter table %@ rename to %@",[self.class getTableName],tmptable];
         [db executeUpdate:renameSql];
         
         //重新创建同空表
         NSString* createTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",[self.class getTableName],[self getParameterString]];
         [db executeUpdate:createTable];
         
         //获取旧表中的字段名
         NSString *theSql=[NSString stringWithFormat:@"select * from %@",tmptable];
         FMResultSet *resultSet=[db executeQuery:theSql];
         [resultSet setupColumnNames];
         //拼接sql语句中的老字段
         NSEnumerator *columnNames = [resultSet.columnNameToIndexMap keyEnumerator];
         NSString *tempColumnName= nil;
         NSMutableString* insertKey = [NSMutableString stringWithCapacity:0];
         while ((tempColumnName = [columnNames nextObject]))
         {
             [insertKey appendFormat:@"%@,", tempColumnName];
         }
         [insertKey deleteCharactersInRange:NSMakeRange(insertKey.length - 1, 1)];
         NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@) select %@ from %@",[self.class getTableName],insertKey,insertKey,tmptable];
         //数据迁移
         [db executeUpdate:sql];
         //删除旧表
         [db executeUpdate:[NSString stringWithFormat:@"drop table %@ ;",tmptable]];
     }];
    
}

-(void)updateToDB:(NSObject<LKModelBaseInteface> *)model callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSDate* date = [NSDate date];
         NSMutableString* updateKey = [NSMutableString stringWithCapacity:0];
         NSMutableArray* updateValues = [NSMutableArray arrayWithCapacity:self.columeNames.count];
         for (int i=0; i<self.columeNames.count; i++) {
             
             NSString* proname = [self.columeNames objectAtIndex:i];
             [updateKey appendFormat:@" %@=?,", proname];
             
             id value =[self safetyGetModel:model valueKey:proname];
             if([value isKindOfClass:[UIImage class]])
             {
                 NSString* filename = [NSString stringWithFormat:@"img%f",[date timeIntervalSince1970]];
                 [UIImageJPEGRepresentation(value, 1) writeToFile:[SandboxFile GetPathForDocuments:filename inDir:@"dbImages"] atomically:YES];
                 value = filename;
             }
             else if([value isKindOfClass:[NSData class]])
             {
                 NSString* filename = [NSString stringWithFormat:@"data%f",[date timeIntervalSince1970]];
                 [value writeToFile:[SandboxFile GetPathForDocuments:filename inDir:@"dbdata"] atomically:YES];
                 value = filename;
             }
             else if([value isKindOfClass:[NSDate class]])
             {
                 value = [LKDAOBase stringWithDate:value];
             }
             [updateValues addObject:value];
         }
         [updateKey deleteCharactersInRange:NSMakeRange(updateKey.length - 1, 1)];
         NSString* updateSQL;
         if(model.rowid > 0)
         {
             updateSQL = [NSString stringWithFormat:@"update %@ set %@ where rowid=%d",[self.class getTableName],updateKey,model.rowid];
         }
         else
         {
             //如果不通过 rowid 来 更新数据  那 primarykey 一定要有值
             updateSQL = [NSString stringWithFormat:@"update %@ set %@ where %@=?",[self.class getTableName],updateKey,model.primaryKey];
             [updateValues addObject:[self safetyGetModel:model valueKey:model.primaryKey]];
         }
         BOOL execute = [db executeUpdate:updateSQL withArgumentsInArray:updateValues];
         if(block != nil)
         {
             block(execute);
         }
         if(execute == NO)
         {
             NSLog(@"database update fail %@   ----->rowid: %d",NSStringFromClass(model.class),model.rowid);
         }
     }];
    
    
}
-(void)deleteToDB:(NSObject<LKModelBaseInteface> *)model callback:(void (^)(BOOL))block{
    
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete;
         BOOL result;
         if(model.rowid > 0)
         {
             delete = [NSString stringWithFormat:@"DELETE FROM %@ where rowid=%d",[self.class getTableName],model.rowid];
             result = [db executeUpdate:delete];
         }
         else
         {
             delete = [NSString stringWithFormat:@"DELETE FROM %@ where %@=?",[self.class getTableName],model.primaryKey];
             result = [db executeUpdate:delete,[self safetyGetModel:model valueKey:model.primaryKey]];
         }
         if(block != nil)
         {
             block(result);
         }
     }];
}
-(void)deleteToDBWithWhere:(NSString *)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete = [NSString stringWithFormat:@"DELETE FROM %@ where %@",[self.class getTableName],where];
         BOOL result = [db executeUpdate:delete];
         if(block != nil)
         {
             block(result);
         }
     }];
}
-(NSString*)dictionaryToSqlWhere:(NSDictionary*)dic andValues:(NSMutableArray*)values
{
    NSMutableString* wherekey = [NSMutableString stringWithCapacity:0];
    if(dic != nil && dic.count >0 )
    {
        NSArray* keys = dic.allKeys;
        for (int i=0; i< keys.count;i++) {
            
            NSString* key = [keys objectAtIndex:i];
            id va = [dic objectForKey:key];
            if([va isKindOfClass:[NSArray class]])
            {
                NSArray* vlist = va;
                for (int j=0; j<vlist.count; j++) {
                    id subvalue = [vlist objectAtIndex:j];
                    if(wherekey.length > 0)
                    {
                        if(j >0)
                        {
                            [wherekey appendFormat:@" or %@ = ? ",key];
                        }
                        else{
                            [wherekey appendFormat:@" and %@ = ? ",key];
                        }
                    }
                    else
                    {
                        [wherekey appendFormat:@" %@ = ? ",key];
                    }
                    [values addObject:subvalue];
                }
            }
            else
            {
                if(wherekey.length > 0)
                {
                    [wherekey appendFormat:@" and %@ = ? ",key];
                }
                else
                {
                    [wherekey appendFormat:@" %@ = ? ",key];
                }
                [values addObject:va];
            }
            
        }
    }
    return wherekey;
}
-(void)deleteToDBWithWhereDic:(NSDictionary *)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSMutableArray* values = [NSMutableArray arrayWithCapacity:6];
         NSString* wherekey = [self dictionaryToSqlWhere:where andValues:values];
         NSString* delete = [NSString stringWithFormat:@"DELETE FROM %@ where %@",[self.class getTableName],wherekey];
         BOOL result = [db executeUpdate:delete withArgumentsInArray:values];
         if(block != nil)
         {
             block(result);
         }
     }];
}
-(void)clearTableData
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         NSString* delete = [NSString stringWithFormat:@"DELETE FROM %@",[self.class getTableName]];
         [db executeUpdate:delete];
     }];
}


-(void)isExistsModel:(NSObject<LKModelBaseInteface>*)model callback:(void(^)(BOOL))block{
    //如果有rowid 就肯定存在
    [self isExistsWithWhere:[NSString stringWithFormat:@"%@ = '%@'",model.primaryKey,[self safetyGetModel:model valueKey:model.primaryKey]] callback:block];
}

#pragma mark 查询表中存在的记录个数
-(void)isExistsWithWhere:(NSString *)where callback:(void (^)(BOOL))block
{
    [bindingQueue inDatabase:^(FMDatabase* db)
     {
         //rowid 就不判断了
         NSString* rowCountSql = [NSString stringWithFormat:@"select count(rowid) from %@ where %@",[self.class getTableName],where];
         FMResultSet* resultSet = [db executeQuery:rowCountSql];
         [resultSet next];
         int result =  [resultSet intForColumnIndex:0];
         [resultSet close];
         BOOL exists = (result != 0);
         if(block != nil)
         {
             block(exists);
         }
     }];
}

#pragma mark 获取Model的对应字段值
-(id)safetyGetModel:(NSObject<LKModelBaseInteface>*) model valueKey:(NSString*)valueKey
{
    id value = [model valueForKey:valueKey];
    if(value == nil)
    {
        return @"";
    }
    return value;
}


const static NSString* normaltypestring = @"floatdoublelongcharshort";
const static NSString* blobtypestring = @"NSDataUIImage";
+(NSString *)toDBType:(NSString *)type
{
    if([type isEqualToString:@"int"])
    {
        return LKSQLInt;
    }
    if ([normaltypestring rangeOfString:type].location != NSNotFound) {
        return LKSQLDouble;
    }
    if ([blobtypestring rangeOfString:type].location != NSNotFound) {
        return LKSQLBlob;
    }
    return LKSQLText;
}

#pragma mark-
+(NSDateFormatter*)getDateFormat
{
    static  NSDateFormatter* formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    });
    return formatter;
}
//把Date 转换成String
+(NSString*)stringWithDate:(NSDate*)date
{
    NSDateFormatter* formatter = [self getDateFormat];
    NSString* datestr = [formatter stringFromDate:date];
    return datestr;
}
+(NSDate *)dateWithString:(NSString *)str
{
    NSDateFormatter* formatter = [self getDateFormat];
    NSDate* date = [formatter dateFromString:str];
    return date;
}
@end

#pragma mark 获取model的字段，类型，保存在dic字典中
@implementation NSObject(LKGetPropertys)
+(NSDictionary *)getPropertys
{
    NSMutableArray* pronames = [NSMutableArray array];
    NSMutableArray* protypes = [NSMutableArray array];
    NSDictionary* props = [NSDictionary dictionaryWithObjectsAndKeys:pronames,@"name",protypes,@"type",nil];
    [self getSelfPropertys:pronames protypes:protypes isGetSuper:NO];
    return props;
}
+ (void)getSelfPropertys:(NSMutableArray *)pronames protypes:(NSMutableArray *)protypes isGetSuper:(BOOL)isGetSuper
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if([propertyName isEqualToString:@"primaryKey"]||[propertyName isEqualToString:@"rowid"])
        {
            continue;
        }
        [pronames addObject:propertyName];
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        /*
         c char
         i int
         l long
         s short
         d double
         f float
         @ id //指针 对象
         ...  BOOL 获取到的表示 方式是 char
         .... ^i 表示  int*  一般都不会用到
         */
        
        if ([propertyType hasPrefix:@"T@"]) {
            [protypes addObject:[propertyType substringWithRange:NSMakeRange(3, [propertyType rangeOfString:@","].location-4)]];
        }
        else if ([propertyType hasPrefix:@"Ti"])
        {
            [protypes addObject:@"int"];
        }
        else if ([propertyType hasPrefix:@"Tf"])
        {
            [protypes addObject:@"float"];
        }
        else if([propertyType hasPrefix:@"Td"]) {
            [protypes addObject:@"double"];
        }
        else if([propertyType hasPrefix:@"Tl"])
        {
            [protypes addObject:@"long"];
        }
        else if ([propertyType hasPrefix:@"Tc"]) {
            [protypes addObject:@"char"];
        }
        else if([propertyType hasPrefix:@"Ts"])
        {
            [protypes addObject:@"short"];
        }
        
    }
    free(properties);
    if(isGetSuper && [self superclass] != [NSObject class])
    {
        [[self superclass] getSelfPropertys:pronames protypes:protypes isGetSuper:isGetSuper];
    }
}
@end


@implementation LKModelBase
+(NSDictionary *)getPropertys
{
    NSMutableArray* pronames = [NSMutableArray array];
    NSMutableArray* protypes = [NSMutableArray array];
    NSDictionary* props = [NSDictionary dictionaryWithObjectsAndKeys:pronames,@"name",protypes,@"type",nil];
    [self getSelfPropertys:pronames protypes:protypes isGetSuper:YES];
    return props;
}
-(NSString *)description
{
    NSMutableString* sb = [NSMutableString stringWithCapacity:0];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [sb appendFormat:@"\n %@ : %@ ",propertyName,[self valueForKey:propertyName]];
    }
    free(properties);
    return sb;
}
-(void)dealloc
{
    self.primaryKey = nil;
//    [super dealloc];
}
@end

@implementation NSString(LKisEmpty)
-(BOOL)isEmptyWithTrim
{
    return [[self stringWithTrim] isEqualToString:@""];
}
-(NSString *)stringWithTrim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
@end
