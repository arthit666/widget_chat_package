import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_package/pages/chat_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MyChatWidget extends StatefulWidget {
  final Widget widget;
  final types.User user;
  final types.User receiver;
  final Function(types.Message message) onSendMessage;
  final Future Function(File file, String name) onSendImage;
  final Future Function(File file, PlatformFile platformFile) onSendFile;
  final Stream<List<types.Message>> getMessageStrem;
  final bool? isShowWidget;

  const MyChatWidget({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendFile,
    required this.getMessageStrem,
    required this.user,
    required this.receiver,
    required this.widget,
    this.isShowWidget = true,
  });

  @override
  State<MyChatWidget> createState() => _MyChatWidgetState();
}

class _MyChatWidgetState extends State<MyChatWidget> {
  ScreenshotController screenshotController = ScreenshotController();

  Future<XFile> convertUint8ListToXFile(Uint8List uint8List) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/screenshot_image.png');
    await file.writeAsBytes(uint8List);
    return XFile(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Screenshot(
          controller: screenshotController,
          child: widget.widget,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Visibility(
            visible: widget.isShowWidget ?? true,
            child: SpeedDial(
              icon: Icons.shortcut_outlined,
              overlayOpacity: 0,
              tooltip: 'Chat',
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.screenshot_monitor_outlined),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  label: 'screenshot ',
                  onTap: () => {
                    screenshotController.capture().then(
                      (Uint8List? image) async {
                        if (image == null) return;
                        XFile xFile = await convertUint8ListToXFile(image);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              xFile: xFile,
                              user: widget.user,
                              receiver: widget.receiver,
                              onSendMessage: widget.onSendMessage,
                              onSendImage: widget.onSendImage,
                              onSendFile: widget.onSendFile,
                              getMessageStrem: widget.getMessageStrem,
                            ),
                          ),
                        );
                      },
                    ).catchError(
                      (onError) {
                        print(onError);
                      },
                    )
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.chat_sharp),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  label: 'Chat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          user: widget.user,
                          receiver: widget.receiver,
                          onSendMessage: widget.onSendMessage,
                          onSendImage: widget.onSendImage,
                          onSendFile: widget.onSendFile,
                          getMessageStrem: widget.getMessageStrem,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
