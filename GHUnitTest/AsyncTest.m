//
//  AsyncTest.m
//  GoAppTest
//
//  Created by huoshuguang on 14-4-19.
//  Copyright (c) 2014年 sqliteTest. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import "Fraction.h"
#import "DenominatorNotZeroException.h"

#import "Complex.h"
#import "MyRectangle.h"
#import "MySquare.h"
#import "Fraction+FractionMath.h"

#import "Printing.h"

#import "SellTickets.h"

#import "MyOperation.h"

#import "Prisoner.h"
#import "Police.h"

#import "Person.h"
@interface AsyncTest : GHTestCase

@end


@implementation AsyncTest

-(void)testNSlog
{
    NSLog(@"YYYYY");
}

-(void)testFraction
{
    Fraction *frac=[[Fraction alloc] init];
    
    [frac setNumerator: 3 andDenominator: 5];
    [frac print];
    printf("The denominator of Fraction is %d\n",frac->denominator);
    [Fraction t];//调用类方法
           /* [[Fraction class] t];
            Class clazz=[Fraction class];
            [clazz t];
            */
//    [frac m];
//    [frac release];
//    return 0;

}

-(void)testException
{
    @try {
        Fraction *frac = [[Fraction alloc] init];
        [frac setNumerator: 3 andDenominator: 5];
    }@catch (DenominatorNotZeroException *dne) {
//        printf(@"%s\n",[[dne reason]cString]);
        NSLog(@"%@\n",[dne reason]);
    }
    @catch (NSException *exception) {
//        printf(@"%s\n",[[exception name]cString]);
        NSLog(@"&%@\n",[exception name]);
    }
    @finally {
        NSLog(@"finally run!");
    }

}

-(void)testIdPointer
{
    Fraction *frac=[[Fraction alloc] initWithNumerator: 3 andDenominator: 5];
    Complex *comp=[[Complex alloc] initWithReal: 1.5 andImaginary: 3.5];
    id number=frac;
    [number print];
    number=comp;
    [comp print];
}

-(void)testInheritSuper
{
    MyRectangle *rec=[[MyRectangle alloc] initWithWidth: 2 andHeight: 5]; [rec area];
    MySquare *squa=[[MySquare alloc] initWithSize: 6];
    [squa area]; //使用父类的计算面积的方法

}

//动态判定与选择器
-(void)testselector
{
    MyRectangle *rec = [[MyRectangle alloc] initWithWidth:2 andHeight:5];
    [rec area];
    
    MySquare *squa = [[MySquare alloc] initWithSize:6];
    [squa area];
    
    //-(BOOL)isMemberOfClass:(Class)clazz 用于判断对象是否是clazz的实例，但不包含子类的实例
    if ([squa isMemberOfClass:[MyRectangle class]]) {
        NSLog(@"squa isMemberOfClass MyRectangle\n");
    }else{
        NSLog(@"squa not isMemberOfClass MyRectangle\n");
    }
    
    if ([squa isMemberOfClass:[MySquare class]]) {
         NSLog(@"squa isMemberOfClass MySquare \n");
    }else{
        NSLog(@"squa not isMemberOfClass MySquare \n");
    }
    NSLog(@"-------------------------------\n");
    
    //-(BOOL)isKindOfClass:(Class)clazz 用于判断对象是否是clazz的实例或者是clazz子类的实例
   if([squa isKindOfClass: [MyRectangle class]])
    {
        printf("squa isKindOfClass MyRectangle\n");
    }else{
        printf("squa not isKindOfClass MyRectangle\n");
    }
    
    if([squa isKindOfClass: [MySquare class]]){
        printf("squa isKindOfClass MySquare\n");
    }else{
        printf("squa not isKindOfClass MySquare\n");
    }
    
    printf("----------------------------------------------\n");
    
    //-(BOOL)respondsToSelector:(SEL)selector //用于判断对象或者类型是否有能力回应指定的方法，这个方法使用选择器表示
    if([squa respondsToSelector: @selector(initWithSize:)]){
        printf("squa respondsToSelector initWithSize:\n");
    }else{
        printf("squa not respondsToSelector initWithSize:\n");
    }
    
    if([MySquare respondsToSelector: @selector(alloc)]){
        printf("MySquare respondsToSelector alloc\n");
    }else{
        printf("MySquare not respondsToSelector alloc\n");
    }
    if([rec respondsToSelector: @selector(initWithWidth:andHeight:)]){
        printf("rec respondsToSelector initWithWidth:andHeight:\n");
    }else{
        printf("rec not respondsToSelector initWithWidth:andHeight:\n");
    }
    
    printf("----------------------------------------------\n");
    
    //+(BOOL)instancesRespondToSelector:(SEL)selector   用于判断类产生的实例是否是有能力回应指定的方法
    if([MySquare instancesRespondToSelector: @selector(initWithSize:)]){
        printf("MySquare instancesRespondToSelector initWithSize:\n");
    }else{
        printf("MySquare not instancesRespondToSelector initWithSize:\n");
    }
    if([MySquare instancesRespondToSelector: @selector(alloc)]){
        printf("MySquare instancesRespondToSelector alloc\n");
    }else{
        printf("MySquare not instancesRespondToSelector alloc\n");
    }
    
    printf("----------------------------------------------\n");
    
    //-(id)performSelector:(SEL)selector 用于动态调用类或者对象上的一个方法
    id x_id=[rec performSelector: @selector(area)];
    NSLog(@"动态调用area()方法:%@",x_id);
    [MyRectangle performSelector: @selector(alloc)];
    
}

//类别
-(void)testCategory
{
    Fraction *frac1 = [[Fraction alloc] initWithNumerator: 1 andDenominator: 3];
    Fraction *frac2 = [[Fraction alloc] initWithNumerator: 2 andDenominator: 5];
    Fraction *frac3 = [frac1 mul: frac2];
    [frac1 print];
    printf( " * " );
    [frac2 print];
    printf( " = " );
    [frac3 print];
    printf( "\n" );
    Fraction *frac5 = [frac1 add: frac2];
    [frac1 print];
    printf( " + " );
    [frac2 print];
    printf( " = " );
    [frac5 print];
    printf( "\n" );

}

//协议
-(void)testProtocol
{
    Fraction *frac = [[Fraction alloc] initWithNumerator:3 andDenominator:5];
   
   id <Printing1> p1 = frac; //使用protocol类型，相当于Java中使用接口类型作为对象的引用List list=ArrayList的实例。
//        也可以写作 : <Printing1> p1 = frac;
    [p1 print1];
    
    id<Printing1,Printing2,Printing3> p2 = frac;
    [p2 print2];
    [p2 print3];
    
    //-(BOOL)conformsToProtocol:(Protocol *)prot 用于判断对象是否遵从某个protocol
    if ([frac conformsToProtocol:@protocol(Printing1)]
        &&[frac conformsToProtocol:@protocol(Printing2)]
        &&[frac conformsToProtocol:@protocol(Printing3)]) {
        printf("YES");
    }else{
        printf("NO");
    }
}


//NSThread
-(void)testNSThread
{
    SellTickets *st = [[SellTickets alloc] init];
    [st ticket];
    
    //在run方法中使用如下的方法与主线程交互
   // [self performSelectorOnMainThread: @selector(moveText)  withObject: nil waitUntilDone: NO];
}


//NSOperation
-(void)testNSOperation
{
    NSOperation *operation1 = [[MyOperation alloc] initWithNum:1];
    NSOperation *operation2 = [[MyOperation alloc] initWithNum:2];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [queue setMaxConcurrentOperationCount:2];
    // 最多可以并行支持的任务数量，如果超过这个值，则放入等待队列中
    [queue addOperation:operation1]; //将任务添加到队列
    [queue addOperation:operation2];
    [NSThread sleepForTimeInterval:15]; //为了不让主线程结束
    
}


//KVO
-(void)testKVO
{
    Prisoner *prisoner=[[Prisoner alloc] init];
    Police *police=[[Police alloc] init];
    //为犯人添加观察者 ：警察，警察关注犯人的name是否发生变化，如果发生变化就立即通知警察，也就是调用Police中得observeValueForKeyPath方法
    //换句话说就是警察对犯人的名字很感兴趣，他订阅了对犯人的名字变化的事件，这个事件只要发生了，警察就会收到通知。
    
    [prisoner addObserver:police forKeyPath: @"name"
                  options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context: nil];
    //addObserver的调用者是要被监视的对象，第一个参数是监视者，第二个参数是被监视的某个属性（使用KVC机制，也就是KVO基于KVC）,第三个参数是被监视属性值改变的类型，这里监听Old,New,即Cocoa会把name属性改变之前的旧值，与改变之后的新值都传递到Police的处理通知的方法，最后一个参数为暂且传入nil
    
    //注意：如果不小心把forKeyPath的属性名写错(即在prisoner中没有的属性名),那么Cocoa不会报告任何错误。所以当发现处理通知的observeValueForKeyPath没有任何反应时，首先查看这个地方是否写错了
    
    [prisoner setName:@"豆豆"];
    
    //警察取消订阅犯人名字变化的事件
    [prisoner removeObserver:police forKeyPath:@"name"];
    [prisoner setName:@"太郎"];
}


//NSNotification
-(void)testNotification
{
    Prisoner *prisoner=[[Prisoner alloc] init];
    Police *police=[[Police alloc] init];
    [prisoner setName: @"豆豆"];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    //向通知中心发送通知，告知通知中心有一个prisioner_name的事件发生了，并把自己作为事件源传递给通知中心。
    //通知中心随后就会查找是谁监听了prisioner_name,然后执行观察者指定的处理方法，也就是Police中的handleNotification方法被调用
    [nc postNotificationName:@"prisioner_name" object:prisoner];
    
    [nc removeObserver:police];
    [prisoner setName:@"太郎"];
}


//谓词NSPredicate
-(void)testNSPredicate
{
    NSMutableArray *array=[NSMutableArray arrayWithCapacity: 5];
   
    Person *person1=[[Person alloc] init];
    [person1 setPid: 1];
    [person1 setName: @"Name1"];
    [person1 setHeight: 168];
    [array addObject: person1];
  
    Person *person2=[[Person alloc] init];
    [person2 setPid: 2];
    [person2 setName: @"Name2"];
    [person2 setHeight: 178];
    [array addObject: person2];
   
    Person *person3=[[Person alloc] init];
    [person3 setPid: 3];
    [person3 setName: @"Name3"];
    [person3 setHeight: 188];
    [array addObject: person3];

    //创建谓词，条件是pid>1并且height<188.0其实谓词也是基于KVC的，也就是如果pid在person的成员变量xxx中，那么此处要写成xxx.pid>1
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"pid>1 and height < 188.0"];
    int i=0;
    for (; i<[array count]; i++) {
        Person *person = [array objectAtIndex:i];
        //遍历数组，输出符合谓词条件的Pserson的name
        if ([pre evaluateWithObject:person]) {
            NSLog(@"%@",[person name]);
        }
    }
    
}

-(void)testShareData
{
    

}








@end
