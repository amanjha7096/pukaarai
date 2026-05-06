import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static User? get currentUser => auth.currentUser;

  static CollectionReference<Map<String, dynamic>> userActivitiesRef(String uid) {
    return firestore.collection('users').doc(uid).collection('activities');
  }
}
