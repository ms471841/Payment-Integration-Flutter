import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paymentint/provider/auth_provider.dart';
import 'package:paymentint/widgets/drawer.dart';
import 'package:paymentint/widgets/subscriptionCard.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  Future<void> _signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/signup');
  }

  List planList = [499, 999, 1499];
  int selectedIndex = 0;
  int selectedPlan = 499;

  void _handleSelection(int index) {
    setState(() {
      if (selectedIndex == index) {
        selectedIndex = -1; // Deselect if already selected
        selectedPlan = 0;
      } else {
        selectedIndex = index;
        selectedPlan = planList[index];
      }
    });
  }

//
  late Razorpay _razorpay;
  TextEditingController _textEditingController = TextEditingController();
  Future<void> _getUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.getUserData();
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _openCheckout(int amount) async {
    var options = {
      'key': 'rzp_test_CVIB2W4XEdwPyx',
      'amount': amount * 100,
      'name': 'Payment Demo',
      'description': 'but Subcription',
      'prefill': {'contact': '8888888888', 'email': 'test@razorpay.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint(
        'Payment success: Order Id: ${response.orderId}, Payment Id: ${response.paymentId}, Signature: ${response.signature}');
    // Update server with payment success details
    _updatePaymentStatus(response.orderId, response.paymentId, 'success');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
        'Payment error: Code: ${response.code}, Message: ${response.message}');
    // Update server with payment failure details
    // _updatePaymentStatus('', '', 'failure');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  void _updatePaymentStatus(
      String? orderId, String? paymentId, String status) async {
    final startDate = DateTime.now();
    final endDate = startDate
        .add(const Duration(days: 30)); // Example: 30-day subscription period

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'subscriptionId': paymentId,
      'isSubscribed': true,
      'subscriptionAmount': selectedPlan,
      'subscriptionStartDate': startDate,
      'subscriptionEndDate': endDate,
    });
  }

  void _initiateRefund(String paymentId, double amount) async {
    // Make an API call to initiate a refund
    // Replace 'YOUR_API_ENDPOINT' with your actual API endpoint
    var url = Uri.parse('YOUR_API_ENDPOINT');
    var response = await http.post(
      url,
      body: {
        'paymentId': paymentId,
        'amount': amount.toString(),
      },
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
// Handle the response from your server
// Example: display a success message or perform additional actions
      debugPrint('Refund initiated: ${responseData['message']}');
    } else {
// Handle the error case
      debugPrint('Failed to initiate refund: ${response.statusCode}');
    }
  }

//

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, value, child) {
      return Scaffold(
        drawer:  MyDrawer(),
        appBar: AppBar(
          title: Text('Payment'),
          actions: [
            IconButton(onPressed: _signout, icon: Icon(Icons.logout_rounded))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Row(
              //   children: [
              //     Expanded(
              //       child: Container(
              //         width: MediaQuery.of(context).size.width / 3,
              //         child: SelectablePlan(
              //           plan: 'Fixed',
              //           index: 0,
              //           isSelected: selectedIndex == 0,
              //           onTap: _handleSelection,
              //         ),
              //       ),
              //     ),
              //     Expanded(
              //       child: Container(
              //         width: MediaQuery.of(context).size.width / 3,
              //         child: SelectablePlan(
              //           plan: 'Custom',
              //           index: 0,
              //           isSelected: selectedIndex == 0,
              //           onTap: _handleSelection,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3,
                      child: SubscriptionCard(
                        plan: 'Weekly',
                        price: '499',
                        index: 0,
                        isSelected: selectedIndex == 0,
                        onTap: _handleSelection,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3,
                      child: SubscriptionCard(
                        plan: 'Monthly',
                        price: '999',
                        index: 1,
                        isSelected: selectedIndex == 1,
                        onTap: _handleSelection,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3,
                      child: SubscriptionCard(
                        plan: 'Yearly',
                        price: '1499',
                        index: 2,
                        isSelected: selectedIndex == 2,
                        onTap: _handleSelection,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You pay',
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        'Rs${selectedPlan ?? 0}',
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ),
                  Container(
                    width: 230,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedPlan != null && selectedPlan > 0) {
                          _openCheckout(selectedPlan);
                        } else {
                          debugPrint('Invalid amount');
                        }
                      },
                      child: Text('Subscribe now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
