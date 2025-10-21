import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum OrderType {
  normal(0),
  vip(1);

  final int value;
  const OrderType(this.value);
}

enum OrderStatus { pending, complete }

class Order {
  static final _uuid = Uuid();
  final String uuid;
  final int id;
  final OrderType type;
  final DateTime date;
  OrderStatus status;
  Bot? bot;

  Order({required this.id, required this.type, required this.status, DateTime? date})
    : uuid = _uuid.v4(),
      date = date ?? DateTime.now();

  @override
  String toString() {
    return 'Order(id=$id, type=${type.name}, uuid=$uuid)';
  }
}

class Bot {
  static final _uuid = Uuid();
  final String uuid;
  Order? order;

  Bot() : uuid = _uuid.v4();

  @override
  String toString() {
    return 'Bot(uuid=$uuid)';
  }
}

class Controller extends ChangeNotifier {
  final List<Order> _vipOrders = [];
  final List<Order> _normalOrders = [];

  List<Order> get vipOrders => _vipOrders;
  List<Order> get normalOrders => _normalOrders;

  final List<Bot> _bots = [];
  final Map<Bot, Timer> _tasks = {};

  Iterable<Order> get pendingOrders {
    final orders = <Order>[];
    for (final order in _vipOrders) {
      if (order.status == OrderStatus.pending) orders.add(order);
    }
    for (final order in _normalOrders) {
      if (order.status == OrderStatus.pending) orders.add(order);
    }
    return orders;
  }

  Iterable<Order> get completedOrders {
    final orders = <Order>[];
    for (final order in _vipOrders) {
      if (order.status == OrderStatus.complete) orders.add(order);
    }
    for (final order in _normalOrders) {
      if (order.status == OrderStatus.complete) orders.add(order);
    }
    return orders;
  }

  Iterable<Order> get unassignedPendingOrders {
    return pendingOrders.where((order) => order.bot == null);
  }

  int get availableBots => _bots.where((bot) => bot.order == null).length;
  int get busyBots => _bots.where((bot) => bot.order != null).length;

  void addOrder(OrderType type) {
    final orders = switch (type) {
      OrderType.vip => _vipOrders,
      OrderType.normal => _normalOrders,
    };
    final order = Order(id: orders.length + 1, type: type, status: OrderStatus.pending);
    orders.add(order);
    _assignBotToPendingOrders(order: order);
    notifyListeners();
  }

  void _assignBotToPendingOrders({Order? order}) {
    // Try to find one pending order if no order given
    final Order pendingOrder;
    try {
      pendingOrder = order ?? unassignedPendingOrders.first;
    } on StateError catch (_) {
      debugPrint('No pending order');
      return;
    }
    bool found = false;
    for (final bot in _bots) {
      if (bot.order != null || _tasks.containsKey(bot)) {
        // bot is not idle, skip
        continue;
      }
      found = true;
      bot.order = pendingOrder;
      pendingOrder.bot = bot;
      _tasks[bot] = Timer(Duration(seconds: 10), () {
        pendingOrder.status = OrderStatus.complete;
        bot.order = null;
        _tasks.remove(bot)?.cancel();
        _assignBotToPendingOrders();
        notifyListeners();
      });
      notifyListeners();
      break;
    }
    if (found) {
      debugPrint('Found 1 bot and assigned order $order');
      return;
    }
    debugPrint('No idle bot available.');
  }

  void addBot() {
    final bot = Bot();
    _bots.add(bot);
    notifyListeners();
    _assignBotToPendingOrders();
  }

  void removeLatestBot() {
    if (_bots.isEmpty) return; // Ignore if empty
    final bot = _bots.last;
    if (bot.order != null) {
      // Stop the timer & unpair the bot and the order
      final order = bot.order!;
      _tasks.remove(bot)?.cancel();
      bot.order = null;
      order.bot = null;
    }
    _bots.remove(bot);
    notifyListeners();
  }
}
