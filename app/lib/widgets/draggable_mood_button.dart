import 'package:flutter/material.dart';

class DraggableMoodButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const DraggableMoodButton({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  _DraggableMoodButtonState createState() => _DraggableMoodButtonState();
}

class _DraggableMoodButtonState extends State<DraggableMoodButton> {
  double top = 0;
  double left = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        top = screenHeight - 400;
        left = 16;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Draggable(
        feedback: FloatingActionButton(
          onPressed: () {},
          child: Icon(widget.icon),
          mini: true,
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            left = details.offset.dx.clamp(0.0, screenWidth - 56.0);
            top = details.offset.dy.clamp(0.0, screenHeight - 56.0);
          });
        },
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          child: Icon(widget.icon),
        ),
      ),
    );
  }
}
