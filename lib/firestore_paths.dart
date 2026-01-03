import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaths {
  FirestorePaths._();

  // Root collections
  static const String users = "users";
  static const String businesses = "businesses";

  // Root docs
  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      FirebaseFirestore.instance.collection(users).doc(uid);

  static DocumentReference<Map<String, dynamic>> businessDoc(String businessId) =>
      FirebaseFirestore.instance.collection(businesses).doc(businessId);


  static CollectionReference<Map<String, dynamic>> businessDailySlots(
          String businessId) =>
      businessDoc(businessId).collection("daily_slots");

  // Reformers
  static CollectionReference<Map<String, dynamic>> businessReformers(
          String businessId) =>
      businessDoc(businessId).collection("reformers");
}
