// import 'package:betteru/core/shared/widgets/buttons.dart';
// import 'package:betteru/core/shared/widgets/gap.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '../../config/app_router.dart';

// final ratingValueProvider = StateProvider.autoDispose<double>((ref) {
//   return 0.0;
// });

// class NotificationPermissionBottomSheet extends StatelessWidget {
//   const NotificationPermissionBottomSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Gap(30),
//         // Close Button
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             IconButton(
//               onPressed: () {},
//               icon: const Icon(Icons.close),
//             ),
//             const Gap(32),
//           ],
//         ),
//         // picture
//         onboarding_03,
//         const Text(
//           "Enable notifications",
//           style: TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 24,
//           ),
//         ),
//         const Gap(8),
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 51),
//           child: Text(
//             "We'll let you know when you've made a payment and earned cash rewards.",
//             style: TextStyle(),
//             textAlign: TextAlign.center,
//           ),
//         ),
//         const Gap(38),
//         SecondaryButton(
//           text: 'Allow notifications',
//           onPressed: () {
//             context.goNamed(RouteName.reward);
//           },
//         ),
//         const Gap(48),
//         AppButton(
//           onPressed: () {
//             context.goNamed(RouteName.reward);
//           },
//           child: const Text("No thanks"),
//         ),
//         const Gap(24),
//       ],
//     );
//   }
// }

// class VipMembershipTierBottomSheet extends StatelessWidget {
//   const VipMembershipTierBottomSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 30, 16, 50),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               IconButton(
//                 onPressed: () {
//                   context.pop();
//                 },
//                 icon: const Icon(Icons.close),
//               ),
//             ],
//           ),
//           // logo
//           Container(
//             width: 100,
//             height: 100,
//             padding: const EdgeInsets.all(14),
//             decoration: const BoxDecoration(
//                 shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
//             child: vipMembershipLogo,
//           ),
//           const Gap(29),
//           const Text(
//             'VIP Membership Tiers',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
//           ),
//           const Gap(13),
//           const Padding(
//             padding: EdgeInsets.only(right: 20),
//             child: Text(
//               'Share your unique invite link with a friend',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w400,
//                 color: Color(0xFF191919),
//               ),
//             ),
//           ),
//           const Gap(23),
//           const Text(
//             'Give your friends \$10 off their first order of \$75 at Washington Vapes and get \$10 Cash Reward for each successful referral as a thank you',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//           const Gap(38),
//           const PointersContainer(
//             title: 'How to use your reward',
//             titleStyle: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//             points: [
//               "Visit The Vitamin Store and pay with talitu",
//               "We'll automatically discount your Cash Reward from the total price",
//               "Earn another Cash Reward to spend on your next visit",
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ReviewBottomSheet extends StatelessWidget {
//   const ReviewBottomSheet({super.key});
//   @override
//   Widget build(BuildContext context) {
//     var bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
//     bottomPadding == 0 ? 50 : bottomPadding;
//     return Padding(
//       padding: EdgeInsets.fromLTRB(16, 30, 16, bottomPadding),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 IconButton(
//                   onPressed: () {
//                     context.pop();
//                   },
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//             // logo
//             Container(
//               width: 100,
//               height: 100,
//               padding: const EdgeInsets.all(16),
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Color(0xFFF5F5F5),
//               ),
//               child: reviewStarLogo,
//             ),
//             const Gap(29),
//             const Text(
//               'Write a review',
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
//             ),
//             const Gap(10),
//             const Padding(
//               padding: EdgeInsets.only(right: 20),
//               child: Text(
//                 'Washington Vapes',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//             ),
//             const Gap(25),
//             // -- Review Stars --
//             Consumer(builder: (context, ref, child) {
//               return RatingStars(
//                 starCount: 5,
//                 maxValue: 5,
//                 valueLabelVisibility: false,
//                 starSize: 38,
//                 starColor: const Color(0xFFFFB000),
//                 value: ref.watch(ratingValueProvider),
//                 onValueChanged: (value) {
//                   ref
//                       .read(ratingValueProvider.notifier)
//                       .update((state) => state = value);
//                 },
//               );
//             }),
//             const Gap(45),
//             // -- Review TextField --
//             const AppTextField(
//               hint: 'Write your review...',
//               label: Text('Write your review'),
//               maxLines: 20,
//               minLines: 5,
//               borderRadius: 8,
//               keyboardType: TextInputType.multiline,
//             ),
//             // -- Submit Review Button --
//             const Gap(28),
//             SecondaryButton(
//               text: 'Submit review',
//               onPressed: () {
//                 // TODO: call submit review api..
//               },
//             ),
//             const Gap(50)
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ReferAFriendBottomSheet extends StatelessWidget {
//   const ReferAFriendBottomSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 30, 16, 50),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               IconButton(
//                 onPressed: () {
//                   context.pop();
//                 },
//                 icon: const Icon(Icons.close),
//               ),
//             ],
//           ),
//           // logo
//           Container(
//             width: 100,
//             height: 100,
//             padding: const EdgeInsets.all(12.36),
//             decoration: const BoxDecoration(
//                 shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
//             child: referLogo,
//           ),
//           const Gap(29),
//           const Text(
//             'Refer a friend.\nGive \$10, Get \$10',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
//           ),
//           const Gap(22),
//           const Padding(
//             padding: EdgeInsets.only(right: 20),
//             child: Text(
//               'Share your unique invite link with a friend',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//             ),
//           ),
//           const Gap(22),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 17),
//             child: Text(
//               'Give your friends \$10 off their first order of \$75 at Washington Vapes and get \$10 Cash Reward for each successful referral as a thank you',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//             ),
//           ),
//           const Gap(86),
//           AppButton(
//             onPressed: () {
//               // sharing referal link
//               Share.share(
//                 'Check out Talitu App for amazing coupons & offers https://talitu.com',
//               );
//             },
//             radius: 100,
//             color: Colors.black,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 shareIcon,
//                 const Gap(13.56),
//                 const Text(
//                   'Share invite link',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w500),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
