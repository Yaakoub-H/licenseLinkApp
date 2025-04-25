// import 'package:flutter/material.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'call_screen.dart';

// class IncomingCallScreen extends StatelessWidget {
//   final Call call;
//   final String inviteId;

//   const IncomingCallScreen({
//     super.key,
//     required this.call,
//     required this.inviteId,
//   });

//   Future<void> _acceptCall(BuildContext context) async {
//     await call.join();
//     await Supabase.instance.client
//         .from('call_invites')
//         .update({
//           'status': 'accepted',
//           'accepted_at': DateTime.now().toIso8601String(),
//         })
//         .eq('id', inviteId);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => CallScreen(call: call)),
//     );
//   }

//   Future<void> _rejectCall(BuildContext context) async {
//     await call.leave();
//     await Supabase.instance.client
//         .from('call_invites')
//         .update({
//           'status': 'rejected',
//           'rejected_at': DateTime.now().toIso8601String(),
//         })
//         .eq('id', inviteId);

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black.withOpacity(0.8),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Incoming Call...',
//               style: TextStyle(color: Colors.white, fontSize: 20),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.call_end, color: Colors.red),
//                   onPressed: () => _rejectCall(context),
//                 ),
//                 const SizedBox(width: 40),
//                 IconButton(
//                   icon: const Icon(Icons.call, color: Colors.green),
//                   onPressed: () => _acceptCall(context),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
