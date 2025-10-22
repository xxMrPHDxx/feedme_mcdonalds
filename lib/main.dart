import 'package:feedme_mcdonald/controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => Controller())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Controller controller = context.watch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('List of orders'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 10),
          child: SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                Text(
                  'Available Bot: ${controller.availableBots}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green),
                ),
                Text(
                  'Busy Bot: ${controller.busyBots}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'normal':
                  controller.addOrder(OrderType.normal);
                  break;
                case 'vip':
                  controller.addOrder(OrderType.vip);
                  break;
                case 'add_bot':
                  controller.addBot();
                  break;
                case 'del_bot':
                  controller.removeLatestBot();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'vip', child: Text('New VIP Order')),
              PopupMenuItem(value: 'normal', child: Text('New Normal Order')),
              PopupMenuItem(value: 'add_bot', child: Text('+ Bot')),
              PopupMenuItem(value: 'del_bot', child: Text('- Bot')),
            ],
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              tabs: OrderStatus.values.map((status) => Tab(text: status.name.toUpperCase())).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: OrderStatus.values.map((status) {
                  final items = switch (status) {
                    OrderStatus.pending => controller.pendingOrders,
                    OrderStatus.complete => controller.completedOrders,
                  };
                  return ListView.separated(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final order = items.elementAt(index);
                      return Container(
                        color: order.bot == null ? null : Colors.green.withAlpha(70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(order.toString()),
                            if (order.bot != null) Text('Processing by bot ${order.bot!.uuid}'),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(height: 2),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
