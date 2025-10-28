import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: Get.height * 0.3,
      color: Colors.amber,
      child: Column(
        children: [
          Text("Song name"),
          Text("artis name"),
          Slider(value: 0.0, min: 0.0, max: 100.0, onChanged: (value) {}),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton(onPressed: () {}, icon: Icon(Icons.pause)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
            ],
          ),
        ],
      ),
    );
  }
}
