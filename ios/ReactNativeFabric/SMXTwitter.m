#import "SMXTwitter.h"
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"
#import "RCTBridge.h"
#import <TwitterKit/TwitterKit.h>

@implementation SMXTwitter
@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(login:(RCTResponseSenderBlock)callback)
{
    [[Twitter sharedInstance] logInWithMethods:TWTRLoginMethodWebBased completion:^(TWTRSession *session, NSError *error) {
        if (session) {
            NSDictionary *body = @{@"authToken": session.authToken,
                                   @"authTokenSecret": session.authTokenSecret,
                                   @"userID":session.userID,
                                   @"userName":session.userName};
            // from https://github.com/GoldenOwlAsia/react-native-twitter-signin/blob/f60162618c7ebab4386f4f9965676b80b0c3b66a/ios/TwitterSignin/TwitterSignin.m
            TWTRAPIClient *client = [TWTRAPIClient clientWithCurrentUser];
            NSURLRequest *request = [client URLRequestWithMethod:@"GET"
                       URL:@"https://api.twitter.com/1.1/account/verify_credentials.json"
                       parameters:@{@"include_email": @"true", @"skip_status": @"true"}
                       error:nil];
            [client sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                NSString *email = @"";
                if (json[@"email"]) {
                    email = json[@"email"];
                }
                NSDictionary *body = @{@"authToken": session.authToken,
                                       @"authTokenSecret": session.authTokenSecret,
                                       @"userID":session.userID,
                                       @"email": email,
                                       @"userName":session.userName};
                // merge profile getting here
                [client
                 sendTwitterRequest:request
                 completion:^(NSURLResponse *response,
                              NSData *data,
                              NSError *connectionError) {
                     if (data) {
                         // handle the response data e.g.
                         NSError *jsonError;
                         NSDictionary *json = [NSJSONSerialization
                                               JSONObjectWithData:data
                                               options:0
                                               error:&jsonError];
                         NSDictionary *combined = @{
                            @"auth": body,
                            @"profile": json
                         };
                         callback(@[[NSNull null], combined]);
                     }
                     else {
                         //callback(@[[connectionError localizedDescription]]);
                         callback(@[[NSNull null], body]);
                     }
                 }];
                //
                //callback(@[[NSNull null], body]);
            }];
            //
            //callback(@[[NSNull null], body]);
        } else {
            callback(@[[error localizedDescription]]);
        }
    }];
}

RCT_EXPORT_METHOD(fetchProfile:(RCTResponseSenderBlock)callback)
{
    TWTRAPIClient *client = [[TWTRAPIClient alloc] init];
    TWTRSessionStore *store = [[Twitter sharedInstance] sessionStore];
    
    TWTRSession *lastSession = store.session;
    
    if(lastSession) {
        NSString *showEndpoint = @"https://api.twitter.com/1.1/users/show.json";
        NSDictionary *params = @{@"user_id": lastSession.userID};
        
        NSError *clientError;
        NSURLRequest *request = [client
                                 URLRequestWithMethod:@"GET"
                                 URL:showEndpoint
                                 parameters:params
                                 error:&clientError];
        
        if (request) {
            [client
             sendTwitterRequest:request
             completion:^(NSURLResponse *response,
                          NSData *data,
                          NSError *connectionError) {
                 if (data) {
                     // handle the response data e.g.
                     NSError *jsonError;
                     NSDictionary *json = [NSJSONSerialization
                                           JSONObjectWithData:data
                                           options:0
                                           error:&jsonError];
                     callback(@[[NSNull null], json]);
                 }
                 else {
                     callback(@[[connectionError localizedDescription]]);
                 }
             }];
        }
        else {
            NSLog(@"Error: %@", clientError);
        }
        
    }
}

RCT_EXPORT_METHOD(logOut)
{
    TWTRSessionStore *store = [[Twitter sharedInstance] sessionStore];
    NSString *userID = store.session.userID;
    
    [store logOutUserID:userID];
}


- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

@end