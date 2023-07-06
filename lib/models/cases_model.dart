import 'package:cloud_firestore/cloud_firestore.dart';

class CarParkSpaceModel {
  String? id;
  String p_id;
  String u_id;
  String postcode;
  String address;
  String title;
  String description;
  DateTime startdatetime;
  DateTime enddatetime;
  String? phoneNumber;
  double latitude;
  double longitude;
  String? p_image;
  DateTime? reg_date;
  bool isPublished;

  CarParkSpaceModel(
      {this.id,
      required this.enddatetime,
      required this.startdatetime,
      required this.p_id,
      required this.u_id,
      required this.postcode,
      required this.address,
      required this.title,
      required this.description,
      this.phoneNumber,
      required this.latitude,
      required this.longitude,
      this.p_image,
      this.reg_date,
      required this.isPublished});

  static CarParkSpaceModel fromMap(Map<String, dynamic> map) {
    return CarParkSpaceModel(
        id: map['id'],
        p_id: map['p_id'],
        u_id: map['u_id'],
        postcode: map['postcode'],
        address: map['address'] ?? "",
        title: map['title'] ?? "",
        description: map['description'] ?? "",
        phoneNumber: map['phoneNumber'],
        latitude: map['latitude'] ?? 0.00,
        longitude: map['longitude'] ?? 0.00,
        p_image: map['p_image'] ?? "",
        reg_date: map['reg_date'].toDate(),
        isPublished: map['isPublished'] ?? false,
        enddatetime: map['startdatetime'] != null
            ? map['startdatetime'].toDate()
            : DateTime.now(),
        startdatetime: map['enddatetime'] != null
            ? map['enddatetime'].toDate()
            : DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'p_id': p_id,
      'u_id': u_id,
      'postcode': postcode,
      'address': address,
      'title': title,
      'description': description,
      'phoneNumber': phoneNumber ?? "",
      'latitude': latitude,
      'longitude': longitude,
      'p_image': p_image,
      'reg_date': reg_date,
      'isPublished': isPublished,
      'startdatetime': startdatetime,
      'enddatetime': enddatetime,
    };
  }

  static CarParkSpaceModel fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> e) {
    final data = e.data();
    return CarParkSpaceModel(
      id: e.id,
      p_id: data['p_id'],
      u_id: data['u_id'],
      postcode: data['postcode'],
      address: data['address'] ?? "",
      title: data['title'] ?? "",
      description: data['description'] ?? "",
      phoneNumber: data['phoneNumber'],
      latitude: data['latitude'] ?? 0.00,
      longitude: data['longitude'] ?? 0.00,
      p_image: data['p_image'] ?? "",
      reg_date: data['reg_date']?.toDate(),
      isPublished: data['isPublished'] ?? false,
      enddatetime: data['enddatetime'] ?? data['enddatetime'].toDate(),
      startdatetime: data['startdatetime'] ?? data['startdatetime'].toDate(),
    );
  }
}
