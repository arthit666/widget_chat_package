import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final types.User user;
  final types.User receiver;
  final XFile? xFile;
  final Function(types.Message message) onSendMessage;
  final Future Function(File file, String name) onSendImage;
  final Future Function(File file, PlatformFile platformFile) onSendFile;
  final Stream<List<types.Message>> getMessageStrem;

  const ChatPage({
    super.key,
    required this.user,
    required this.receiver,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendFile,
    required this.getMessageStrem,
    this.xFile,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  XFile? _selectedImage;
  PlatformFile? _selectedFile;
  List<types.Message> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.xFile;
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = result.files.single;
        _selectedImage = null;
      });
    }
  }

  void _handleImageSelection() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      setState(() {
        _selectedImage = result;
        _selectedFile = null;
      });
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    //
  }

  Widget _buildInputField() {
    return Column(
      children: [
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Image.file(
                  File(_selectedImage!.path),
                  height: 150,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        if (_selectedFile != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _handleAttachmentPressed,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleSendMessage,
            ),
          ],
        ),
      ],
    );
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();

    if (text.isNotEmpty || _selectedImage != null || _selectedFile != null) {
      if (_selectedImage != null) {
        sendImage(file: File(_selectedImage!.path), name: _selectedImage!.name);
        _selectedImage = null;
      }

      if (_selectedFile != null) {
        sendFile(file: File(_selectedFile!.path!), platformFile: _selectedFile!);
        _selectedFile = null;
      }

      if (text.isNotEmpty) {
        final textMessage = types.TextMessage(
          author: widget.user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: text,
        );

        sendMessage(textMessage);
      }

      _textController.clear();
      setState(() {});
    }
  }

  sendMessage(types.Message message) async {
    await widget.onSendMessage.call(message);
  }

  sendImage({required File file, required String name}) async {
    await widget.onSendImage.call(file, name);
  }

  sendFile({required File file, required PlatformFile platformFile}) async {
    await widget.onSendFile.call(file, platformFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: widget.getMessageStrem,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('error'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Chat(
                    messages: _messages,
                    onPreviewDataFetched: _handlePreviewDataFetched,
                    onSendPressed: _handleSendPressed,
                    showUserAvatars: true,
                    showUserNames: true,
                    user: widget.user,
                    customBottomWidget: _buildInputField(),
                  );
                }
                _messages = snapshot.data!.toList();
                return Chat(
                  theme: DefaultChatTheme(
                    backgroundColor: Colors.grey[200]!,
                    // secondaryColor: const Color.fromARGB(255, 91, 240, 96),
                  ),
                  messages: _messages,
                  onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: _handleSendPressed,
                  showUserAvatars: true,
                  showUserNames: true,
                  user: widget.user,
                  onMessageTap: (BuildContext context, types.Message p1) {
                    print(p1.type);
                  },
                  customBottomWidget: _buildInputField(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
