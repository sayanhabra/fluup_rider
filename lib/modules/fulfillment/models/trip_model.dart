class TripMilestone {
  final String title;
  final String time;
  final bool isCompleted;

  const TripMilestone({
    required this.title,
    required this.time,
    this.isCompleted = true,
  });
}

class TripItem {
  final int orderId;
  final String orderNumber;
  final String dateText;
  final String status; // 'Completed' or 'Cancelled'
  final String earningsText;
  final int tripEarnings;
  final int incentive;
  final List<TripMilestone> milestones;

  const TripItem({
    required this.orderId,
    required this.orderNumber,
    required this.dateText,
    required this.status,
    required this.earningsText,
    required this.tripEarnings,
    required this.incentive,
    required this.milestones,
  });

  bool get isCompleted => status == 'Completed';
  int get totalEarned => tripEarnings + incentive;

  static List<TripItem> getSampleTrips() {
    return [
      const TripItem(
        orderId: 78216,
        orderNumber: '#ORD78216',
        dateText: 'Today, 12:42 PM',
        status: 'Completed',
        earningsText: '₹140',
        tripEarnings: 120,
        incentive: 20,
        milestones: [
          TripMilestone(title: 'Order Accepted', time: '12:01 PM'),
          TripMilestone(title: 'Arrived at Store', time: '12:14 PM'),
          TripMilestone(title: 'Pickup Confirmed', time: '12:18 PM'),
          TripMilestone(title: 'Arrived at Customer', time: '12:35 PM'),
          TripMilestone(title: 'Delivery Completed', time: '12:42 PM'),
        ],
      ),
      const TripItem(
        orderId: 78215,
        orderNumber: '#ORD78215',
        dateText: 'Today, 11:27 AM',
        status: 'Completed',
        earningsText: '₹120',
        tripEarnings: 100,
        incentive: 20,
        milestones: [
          TripMilestone(title: 'Order Accepted', time: '11:00 AM'),
          TripMilestone(title: 'Arrived at Store', time: '11:09 AM'),
          TripMilestone(title: 'Pickup Confirmed', time: '11:13 AM'),
          TripMilestone(title: 'Arrived at Customer', time: '11:22 AM'),
          TripMilestone(title: 'Delivery Completed', time: '11:27 AM'),
        ],
      ),
      const TripItem(
        orderId: 78214,
        orderNumber: '#ORD78214',
        dateText: 'Today, 10:05 AM',
        status: 'Cancelled',
        earningsText: '-',
        tripEarnings: 0,
        incentive: 0,
        milestones: [
          TripMilestone(title: 'Order Accepted', time: '09:50 AM'),
          TripMilestone(title: 'Customer Cancelled', time: '10:05 AM'),
        ],
      ),
      const TripItem(
        orderId: 78213,
        orderNumber: '#ORD78213',
        dateText: 'Today, 9:12 AM',
        status: 'Completed',
        earningsText: '₹160',
        tripEarnings: 130,
        incentive: 30,
        milestones: [
          TripMilestone(title: 'Order Accepted', time: '08:35 AM'),
          TripMilestone(title: 'Arrived at Store', time: '08:48 AM'),
          TripMilestone(title: 'Pickup Confirmed', time: '08:52 AM'),
          TripMilestone(title: 'Arrived at Customer', time: '09:05 AM'),
          TripMilestone(title: 'Delivery Completed', time: '09:12 AM'),
        ],
      ),
    ];
  }
}

