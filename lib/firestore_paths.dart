import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaths {
  FirestorePaths._();

  // Koleksiyon isimleri (tek yerden yönet)
  static const String users = "users";
  static const String businesses = "businesses";
  static const String customers = "customers";

  // Root doc referansları
  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      FirebaseFirestore.instance.collection(users).doc(uid);

  static DocumentReference<Map<String, dynamic>> businessDoc(String businessId) =>
      FirebaseFirestore.instance.collection(businesses).doc(businessId);

  static DocumentReference<Map<String, dynamic>> customerDoc(String customerId) =>
      FirebaseFirestore.instance.collection(customers).doc(customerId);

  // Business alt koleksiyonlar
  static CollectionReference<Map<String, dynamic>> businessDailySlots(String businessId) =>
      businessDoc(businessId).collection("dailySlots");

  static CollectionReference<Map<String, dynamic>> businessDemoRequests(String businessId) =>
      businessDoc(businessId).collection("demoRequests");

  static CollectionReference<Map<String, dynamic>> businessReformers(String businessId) =>
      businessDoc(businessId).collection("reformers");
}
