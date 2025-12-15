import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parent Safe GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  void _authenticate() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Safe GPS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _authenticate,
              child: Text(_isLogin ? 'Login' : 'Sign Up'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _isLogin = !_isLogin);
              },
              child: Text(_isLogin ? 'Create Account' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Set<Marker> _markers = {};
  bool _isCalling = false;
  bool _isMicOn = true;
  bool _isCameraOn = true;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _startLocationTracking();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    if (status == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((position) {
      setState(() => _currentPosition = position);
      _updateMarker();
      _sendLocationToFirebase();
    });
  }

  void _updateMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        );
      });
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _sendLocationToFirebase() async {
    if (_currentPosition != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('locations').doc(userId).set({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'timestamp': DateTime.now(),
        'accuracy': _currentPosition!.accuracy,
        'speed': _currentPosition!.speed,
      });
    }
  }

  void _emergencySOS() {
    setState(() => _isCalling = true);
    _showSOSDialog();
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('EMERGENCY SOS ALERT'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Emergency call initiated!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Live Camera Feed:'),
              const SizedBox(height: 10),
              Container(
                height: 200,
                color: Colors.black,
                child: _isCameraOn
                    ? const Center(
                        child: Icon(Icons.videocam, color: Colors.white, size: 50),
                      )
                    : const Center(
                        child: Icon(Icons.videocam_off, color: Colors.grey, size: 50),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isCameraOn = !_isCameraOn),
                    icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isMicOn = !_isMicOn),
                    icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Two-Way Audio Call Active',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isCalling = false);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('End Call'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Safe GPS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 15,
                    ),
                    markers: _markers,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: _emergencySOS,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.phone, color: Colors.white),
                      ),
                      FloatingActionButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CameraScreen()),
                        ),
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.videocam),
                      ),
                      FloatingActionButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GeofenceScreen()),
                        ),
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.location_on),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Camera Feed')),
      body: Center(
        child: Container(
          color: Colors.black,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, color: Colors.white, size: 100),
              SizedBox(height: 20),
              Text('Live Camera Feed',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              SizedBox(height: 20),
              Text('(Real camera integration needed)',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({Key? key}) : super(key: key);

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geofence Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Define Safe Zones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Home'),
              subtitle: const Text('Radius: 500m'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Hospital'),
              subtitle: const Text('Radius: 1km'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Market'),
              subtitle: const Text('Radius: 800m'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
