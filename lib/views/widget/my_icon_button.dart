import 'package:flutter/material.dart';


class MyIconButton {
  Widget expandedIconButton(
      {@required IconData icon,
      @required String text,
      @required VoidCallback function}) {
    return Expanded(
      child: FlatButton.icon(
        onPressed: function,
        icon: Icon(icon, size: 16,),
        height: 45,
        color: Colors.white,
        highlightColor: Colors.white10,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(text, style: TextStyle(fontSize: 12),),
      ),
    );
  }
}
