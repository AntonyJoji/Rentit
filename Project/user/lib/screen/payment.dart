import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:user/main.dart';
import 'package:user/screen/success.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int id;
  const PaymentGatewayScreen({super.key, required this.id});

  @override
  _PaymentGatewayScreenState createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> checkout() async {
    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_status': 2}).eq('booking_id', widget.id);
      await supabase
          .from('tbl_booking')
          .update({'booking_status': 2}).eq('booking_id', widget.id);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(),
          ));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueAccent.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Credit Card Preview
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CreditCardWidget(
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cardHolderName: cardHolderName,
                    cvvCode: cvvCode,
                    showBackView: isCvvFocused,
                    onCreditCardWidgetChange: (creditCardBrand) {},
                    isHolderNameVisible: true,
                    enableFloatingCard: true,
                    cardBgColor: Colors.blueAccent,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Payment Form
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CreditCardForm(
                            cardNumber: cardNumber,
                            expiryDate: expiryDate,
                            cardHolderName: cardHolderName,
                            cvvCode: cvvCode,
                            isHolderNameVisible: true,
                            onCreditCardModelChange: (creditCardModel) {
                              setState(() {
                                cardNumber = creditCardModel.cardNumber;
                                expiryDate = creditCardModel.expiryDate;
                                cardHolderName = creditCardModel.cardHolderName;
                                cvvCode = creditCardModel.cvvCode;
                                isCvvFocused = creditCardModel.isCvvFocused;
                              });
                            },
                            formKey: formKey,
                            cardNumberValidator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'This field is required';
                              }
                              if (value.length != 19) {
                                return 'Invalid card number';
                              }
                              return null;
                            },
                            expiryDateValidator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'This field is required';
                              }
                              if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                return 'Invalid expiry date format';
                              }
                              final List<String> parts = value.split('/');
                              final int month = int.tryParse(parts[0]) ?? 0;
                              final int year = int.tryParse(parts[1]) ?? 0;
                              final DateTime now = DateTime.now();
                              final int currentYear = now.year % 100;
                              final int currentMonth = now.month;
                              if (month < 1 || month > 12) {
                                return 'Invalid month';
                              }
                              if (year < currentYear ||
                                  (year == currentYear && month < currentMonth)) {
                                return 'Card has expired';
                              }
                              return null;
                            },
                            cvvValidator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'This field is required';
                              }
                              if (value.length < 3) {
                                return 'Invalid CVV';
                              }
                              return null;
                            },
                            cardHolderValidator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'This field is required';
                              }
                              if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                                return 'Invalid cardholder name';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 124, 135, 153),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                checkout();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill in all fields correctly!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
