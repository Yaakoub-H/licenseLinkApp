// import 'package:flutter/material.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
// import 'package:uuid/uuid.dart';
// import 'call_screen.dart';

// class JoinCallPage extends StatelessWidget {
//   const JoinCallPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Start Call')),
//       body: Center(
//         child: ElevatedButton(
//           child: const Text('Join Call'),
//           onPressed: () async {
//             try {
//               final callId = const Uuid().v4(); // generate unique call ID
//               final call = StreamVideo.instance.makeCall(
//                 callType: StreamCallType.audioRoom(),
//                 id: callId,
//               );

//               await call.getOrCreate();

//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => CallScreen(call: call)),
//               );
//             } catch (e) {
//               debugPrint('Error joining or creating call: $e');
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
