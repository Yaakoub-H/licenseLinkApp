// import 'package:flutter/material.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';

// class CallScreen extends StatefulWidget {
//   final Call call;

//   const CallScreen({Key? key, required this.call}) : super(key: key);

//   @override
//   State<CallScreen> createState() => _CallScreenState();
// }

// class _CallScreenState extends State<CallScreen> {
//   bool _isCallActive = false;

//   @override
//   void initState() {
//     super.initState();
//     _isCallActive = true;
//   }

//   @override
//   void dispose() {
//     _isCallActive = false;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamCallContainer(
//         call: widget.call,
//         callContentBuilder: (
//           BuildContext context,
//           Call call,
//           CallState callState,
//         ) {
//           return StreamCallContent(
//             call: call,
//             callState: callState,
//             callControlsBuilder: (
//               BuildContext context,
//               Call call,
//               CallState callState,
//             ) {
//               final localParticipant = callState.localParticipant!;
//               return StreamCallControls(
//                 options: [
//                   ToggleMicrophoneOption(
//                     call: call,
//                     localParticipant: localParticipant,
//                   ),
//                   LeaveCallOption(
//                     call: call,
//                     onLeaveCallTap: () {
//                       call.leave();
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
