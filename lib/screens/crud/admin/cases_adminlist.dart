import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palaction/screens/crud/cases/edit_cases.dart';
import 'package:palaction/screens/crud/cases/view_case.dart';
import 'package:palaction/shared/auth_service.dart';
import 'package:palaction/shared/widgets/app_bar.dart';

class ParkingAdminListPage extends StatefulWidget {
  ParkingAdminListPage();

  @override
  _ParkingAdminListPageState createState() => _ParkingAdminListPageState();
}

class _ParkingAdminListPageState extends State<ParkingAdminListPage> {
  late Stream<QuerySnapshot> _ParkingStream;
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isPublished = true;
  late CollectionReference<Map<String, dynamic>> parkingSpacesCollection;

  @override
  void initState() {
    super.initState();
    parkingSpacesCollection =
        FirebaseFirestore.instance.collection('parking_spaces');
    _ParkingStream =
        FirebaseFirestore.instance.collection('parking_spaces').snapshots();
  }

  togglePublishStatus([parkingId]) {
    setState(() {
      isPublished = !isPublished;
    });

    bool status = isPublished ? true : false;
    print('Status: $status');
    print('Status: $parkingId');
    parkingSpacesCollection.doc(parkingId).update({'isPublished': isPublished});
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Case Details', isLoggedInStream: isLoggedInStream),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ParkingStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final Parking = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: Parking.length,
              itemBuilder: (BuildContext context, int index) {
                final parking = Parking[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Address: ${parking['address']}'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewParkingSpace(
                                      parking: parking,
                                      user: currentUser!,
                                    ),
                                  ),
                                );
                              },
                              child: Text('View'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditParkingSpace(
                                      parking: parking,
                                      user: currentUser!,
                                    ),
                                  ),
                                );
                              },
                              child: Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () {
                                print('Address: ${parking['p_id']}');
                                String parkingId = parking['p_id'];
                                _deleteParking(context, parkingId);
                              },
                              child: Text('Delete'),
                            ),
                            SizedBox(width: 7),
                            TextButton(
                              onPressed: () {
                                togglePublishStatus(parking['p_id']);
                              },
                              child: Text(parking['isPublished']
                                  ? 'Unpublish'
                                  : 'Publish'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _deleteParking(BuildContext context, String parkingId) async {
    try {
      // Delete the parking space from the 'parking_spaces' collection
      await FirebaseFirestore.instance
          .collection('parking_spaces')
          .doc(parkingId)
          .delete();

      // Show a success message
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Parking deleted successfully'),
        ),
      );
    } catch (error) {
      // Show an error message
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error deleting the Parking: $error'),
        ),
      );
    }
  }
}
