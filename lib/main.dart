import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tenjin_plugin/tenjin_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    final apiKey = Platform.isAndroid ? 'MHSWZJVZ4N7USYL9BZZBKY2TDVWVY9CC' : "BRBUDHDPRSZSDVZVXVRUYXS1QZDYJA5C";

    TenjinSDK.instance.init(apiKey: apiKey);
    TenjinSDK.instance.optIn();
    TenjinSDK.instance.registerAppForAdNetworkAttribution();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Tenjin SDK')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  debugPrint("calling connect");
                  TenjinSDK.instance.connect();
                  debugPrint("connect called");
                },
                child: Text('connect'),
              ),
              TextButton(
                onPressed: () =>
                    TenjinSDK.instance.eventWithName('swipe_right'),
                child: Text('eventWithName'),
              ),
              TextButton(
                onPressed: () =>
                    TenjinSDK.instance.eventWithNameAndValue('item', 100),
                child: Text('eventWithNameAndValue'),
              ),
              if (Platform.isIOS)
                TextButton(
                  onPressed: () {
                    TenjinSDK.instance.requestTrackingAuthorization();
                  },
                  child: Text('Request Tracking Authorization'),
                ),
              TextButton(
                onPressed: () {
                  TenjinSDK.instance.transactionWithReceipt(
                    productId: 'productId',
                    currencyCode: 'USD',
                    quantity: 1,
                    unitPrice: 3.80,
                    iosReceipt: 'iosReceipt',
                    iosTransactionId: 'transactionId',
                    androidDataSignature: 'androidDataSignature',
                    androidPurchaseData: 'androidPurchaseData',
                  );
                },
                child: Text('Transaction with Receipt'),
              ),
              TextButton(
                onPressed: () {
                  TenjinSDK.instance.transaction('productId', 'USD', 1, 3.80);
                },
                child: Text('Transaction'),
              ),
              TextButton(
                onPressed: () {
                  TenjinSDK.instance.updatePostbackConversionValue(3);
                },
                child: Text('Update SKAN'),
              ),
              TextButton(
                onPressed: () {
                  TenjinSDK.instance.setCustomerUserId('test_user_id');
                },
                child: Text('Set customer userId'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    String? userId = await TenjinSDK.instance.getCustomerUserId();
                    if (userId != null) {
                      print(userId);
                    } else {
                      print('Failed to get customer user id');
                    }
                  } catch (e) {
                    print('Error: $e');
                  }
                },
                child: Text('Get user id'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
