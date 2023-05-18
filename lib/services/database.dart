import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paymentint/data/models/user.dart';

class Database {
  // save user data when signin
  Future<void> saveUserData(String uid, MyUser user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    print(userRef);
    await userRef.set(user.toFirestore());
  }

  // get user data

  Future<MyUser?> getUserData(String uid) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return MyUser.fromFirestore(snapshot);
  }

//get user by  id

  Future<MyUser?> findUserById(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        // User document exists
        MyUser user = MyUser.fromFirestore(snapshot);
        return user;
      } 
        // User document does not exist
        return null;
      
    } catch (e) {
      print('Error retrieving user: $e');
      return null;
    }
  }

// update user amount

  Future<void> updateAmount(String userId, double newAmount) async {
    // Deduct the game entry fee from the user's amount field
    MyUser myUser;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final userData = await userDoc.get();
    final currentAmount = userData.get('amount') as double;
    final updatedAmount = currentAmount - newAmount;
    await userDoc.update({'amount': FieldValue.increment(-newAmount)});
    // return  myUser.copyWith(amount: updatedAmount);
  }
}
