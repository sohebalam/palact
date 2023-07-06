import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:palaction/models/cases_model.dart';
import 'package:palaction/shared/auth_service.dart';
import 'package:palaction/shared/carpark_space_db_helper.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:palaction/shared/functions.dart';
import 'package:palaction/shared/style/contstants.dart';
import 'package:palaction/shared/widgets/loginDialog.dart';
import 'package:palaction/shared/widgets/app_bar.dart';

class RegisterParkingSpace extends StatefulWidget {
  @override
  _RegisterParkingSpaceState createState() => _RegisterParkingSpaceState();
}

class _RegisterParkingSpaceState extends State<RegisterParkingSpace> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _titleController = TextEditingController();
  final _spacesController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDateTimeStart = DateTime.now();
  DateTime _selectedDateTimeEnd = DateTime.now().add(Duration(hours: 1));
  final _postcodeOptions = <String>[];
  final picker = ImagePicker();
  bool _isLoading = false;
  late final Stream<bool> isLoggedInStream;

  File? _image;

  @override
  void initState() {
    super.initState();
    checkCurrentUser();
  }

  void checkCurrentUser() {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      print('User is signed in.');
      print('User UID: ${user.uid}');
    } else {
      print('No user is currently signed in.');
    }
  }

  void _fetchPostcodeOptions(String input) async {
    final url =
        Uri.parse('https://api.postcodes.io/postcodes/$input/autocomplete');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        final options = List<String>.from(data['result']);
        setState(() {
          _postcodeOptions.clear();
          _postcodeOptions.addAll(options);
        });
      }
    }
  }

  Future<void> _getImage() async {
    final action = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;

    final pickedFile = await picker.pickImage(source: action);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    User? user = FirebaseAuth.instance.currentUser;

    void _submitForm() async {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true; // Set loading state
        });
        // Check if user is logged in

        // final user = await authService.getCurrentUser();
        if (user?.uid == null) {
          // User is not logged in, show snackbar message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to register your space'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _isLoading = false; // Reset loading state
          });
          return;
        }
        // User is logged in, continue with form submission
        final postcode = _postcodeController.text;
        final postcodeUrl =
            Uri.parse('https://api.postcodes.io/postcodes/$postcode');
        final postcodeResponse = await http.get(postcodeUrl);
        if (postcodeResponse.statusCode == 200) {
          // Postcode is valid, continue with form submission
          final postcodeData = json.decode(postcodeResponse.body);
          final longitude = postcodeData['result']['longitude'];
          final latitude = postcodeData['result']['latitude'];

          final id =
              FirebaseFirestore.instance.collection('parking_spaces').doc().id;
          final RegisterParkingSpace = CarParkSpaceModel(
            u_id: user!.uid,
            address: _addressController.text,
            postcode: postcode,
            title: _titleController.text,
            description: _descriptionController.text,
            latitude: latitude,
            longitude: longitude,
            p_id: id,
            isPublished: false,
            enddatetime: _selectedDateTimeStart,
            startdatetime: _selectedDateTimeEnd,
          );

          if (_image == null) {
            // Image is not selected, show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select an image'),
                duration: Duration(seconds: 2),
              ),
            );
            setState(() {
              _isLoading = false; // Reset loading state
            });
            return;
          }

          // Upload image to Firebase Storage
          if (_image != null) {
            final storageRef = firebase_storage.FirebaseStorage.instance
                .ref()
                .child('parking_spaces')
                .child(id);
            final uploadTask = storageRef.putFile(_image!);
            final snapshot = await uploadTask.whenComplete(() {});
            final imageUrl = await snapshot.ref.getDownloadURL();
            RegisterParkingSpace.p_image = imageUrl;
          }
          DB_CarPark.create(RegisterParkingSpace);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Case registered successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Postcode is invalid, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid postcode'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }

    return Scaffold(
        appBar: CustomAppBar(
          title: 'Register Court Case',
          isLoggedInStream: isLoggedInStream,
        ),
        body: SingleChildScrollView(
            child: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<bool>(
                  stream: authService.user?.map((user) => user != null),
                  initialData: false,
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Text(
                        'You are logged in ${user?.email}',
                        style: TextStyle(fontSize: 20),
                      );
                    } else {
                      return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                                    child: Center(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await signInFunction();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          minimumSize: Size(150, 60),
                                          textStyle: TextStyle(
                                            fontSize: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            side:
                                                BorderSide(color: Colors.black),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/google.png', // Replace with the path to your local asset image
                                              width: 24,
                                              height: 24,
                                              errorBuilder:
                                                  (BuildContext context,
                                                      Object exception,
                                                      StackTrace? stackTrace) {
                                                print(
                                                    'Error loading image: $exception');
                                                return const Text(
                                                    'Error loading image'); // Display a text error message instead of an icon
                                              },
                                            ),
                                            SizedBox(width: 10),
                                            Text("Sign In with Google"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              CustomLoginDialog(),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 3,
                                        shadowColor:
                                            Colors.black.withOpacity(1),
                                      ),
                                      child: Text(
                                        'Email & Password Login',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ));
                    }
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100.0,
                ),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Location of Action/Title',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter an address';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Dates and Times of the Case',
                  style: const TextStyle(fontSize: 12),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateTimeStart,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );

                        if (picked != null) {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(_selectedDateTimeStart),
                          );

                          if (pickedTime != null) {
                            setState(() {
                              _selectedDateTimeStart = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              _selectedDateTimeEnd = _selectedDateTimeStart
                                  .add(Duration(hours: 1));
                            });
                            // print(_selectedDateTimeEnd);
                          }
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('hh:mm a dd/MM/yy')
                                      .format(_selectedDateTimeStart),
                                ),
                                Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateTimeEnd,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );

                        if (picked != null) {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(_selectedDateTimeEnd),
                          );

                          if (pickedTime != null) {
                            setState(() {
                              _selectedDateTimeEnd = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            'End',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('hh:mm a dd/MM/yy')
                                      .format(_selectedDateTimeEnd),
                                ),
                                Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address of court',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _postcodeController,
                  decoration: InputDecoration(
                    labelText: 'Postcode of court',
                  ),
                  onChanged: (input) {
                    if (input.length > 2) {
                      _fetchPostcodeOptions(input);
                    }
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a postcode';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.0),
                if (_postcodeOptions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _postcodeOptions.length,
                      itemBuilder: (context, index) {
                        final option = _postcodeOptions[index];
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            _postcodeController.text = option;
                            setState(() {
                              _postcodeOptions.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description of case/action',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                GestureDetector(
                  onTap: _getImage,
                  child: Container(
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Select Image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                if (_image != null)
                  Container(
                    height: 200.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: 16.0),
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _submitForm();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants()
                          .primaryColor, // Set a different color for the button
                    ),
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ])));
  }
}
