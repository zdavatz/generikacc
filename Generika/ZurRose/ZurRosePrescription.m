//
//  ZurRosePrescription.m
//  Generika
//
//  Created by b123400 on 2024/11/26.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePrescription.h"
#import "ZurRoseCredential.h"

@interface ZurRosePrescription()<NSURLSessionTaskDelegate>

@end

@implementation ZurRosePrescription

- (DDXMLDocument *)toXML {
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<prescription></prescription>"
                                                               options:0
                                                                 error:&error];
    DDXMLElement *e = [document rootElement];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    [e addAttribute:[DDXMLNode attributeWithName:@"issueDate" stringValue:[formatter stringFromDate:self.issueDate]]];
    [e addAttribute:[DDXMLNode attributeWithName:@"validity" stringValue:[formatter stringFromDate:self.validity]]];
    [e addAttribute:[DDXMLNode attributeWithName:@"user" stringValue:self.user]];
    [e addAttribute:[DDXMLNode attributeWithName:@"password" stringValue:self.password]];
    if (self.prescriptionNr) {
        [e addAttribute:[DDXMLNode attributeWithName:@"prescriptionNr" stringValue:self.prescriptionNr]];
    }
    
    [e addAttribute:[DDXMLNode attributeWithName:@"deliveryType" stringValue:[@(self.deliveryType) stringValue]]];
    
    [e addAttribute:[DDXMLNode attributeWithName:@"ignoreInteractions" stringValue:self.ignoreInteractions ? @"true" : @"false"]];
    [e addAttribute:[DDXMLNode attributeWithName:@"interactionsWithOldPres" stringValue:self.interactionsWithOldPres ? @"true" : @"false"]];
    
    if (self.remark) {
        [e addAttribute:[DDXMLNode attributeWithName:@"remark" stringValue:self.remark]];
    }
    
    if (self.prescriptorAddress) {
        [e addChild:self.prescriptorAddress.toXML];
    }
    if (self.patientAddress) {
        [e addChild:self.patientAddress.toXML];
    }
    
    for (ZurRoseProduct *product in self.products) {
        [e addChild:product.toXML];
    }
    
    NSString *output = [document XMLString];
    return document;
}

- (void)sendToZurRoseWithCompletion:(void (^)(NSHTTPURLResponse* res, NSError* error))callback {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://estudio.zur-rose.ch/estudio/prescriptioncert"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    NSData *xmlData = [[self toXML] XMLData];
    NSLog(@"xml: %@", [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding]);
    [request setHTTPBody:xmlData];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) return;
        callback((NSHTTPURLResponse*)response, error);
    }];
    task.delegate = self;
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        NSString* cacertPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"p12"];

        NSData *p12data = [NSData dataWithContentsOfFile:cacertPath];

        CFDataRef inP12data = (__bridge CFDataRef)p12data;

        SecIdentityRef myIdentity = nil;
        extractIdentity(inP12data, &myIdentity);
        assert(myIdentity != nil);

        NSURLCredential* credential = [NSURLCredential credentialWithIdentity:myIdentity certificates:nil persistence:NSURLCredentialPersistenceNone];
        assert(credential != nil);

        NSLog(@"User: %@, certificates %@ identity:%@", [credential user], [credential certificates], [credential identity]);
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    } else {
      completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

OSStatus extractIdentity(CFDataRef inP12data, SecIdentityRef *identity)
{
  OSStatus securityError = errSecSuccess;

  CFStringRef password = CFSTR(ZURROSE_CERTIFICATE_PASSWORD);
  const void *keys[] = { kSecImportExportPassphrase };
  const void *values[] = { password };

  CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);

  CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
  securityError = SecPKCS12Import(inP12data, options, &items);

  if (securityError == errSecSuccess) {
    CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
    const void *tempIdentity = NULL;
    tempIdentity = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
    *identity = (SecIdentityRef)tempIdentity;

    CFIndex count = CFArrayGetCount(items);
    NSLog(@"Certificates found: %ld",count);
  }

  if (options) {
    CFRelease(options);
  }

  return securityError;
}

@end
