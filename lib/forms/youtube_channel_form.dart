import 'package:flutter/material.dart';
import 'package:lms_admin/models/youtube_channel.dart';
import 'package:lms_admin/services/supabase_service.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:lms_admin/mixins/textfields.dart';

class YouTubeChannelForm extends StatefulWidget {
  final YouTubeChannel? channel;
  final VoidCallback onSaved;

  const YouTubeChannelForm({Key? key, this.channel, required this.onSaved})
      : super(key: key);

  @override
  State<YouTubeChannelForm> createState() => _YouTubeChannelFormState();
}

class _YouTubeChannelFormState extends State<YouTubeChannelForm> with TextFields {
  final _formKey = GlobalKey<FormState>();
  final _btnController = RoundedLoadingButtonController();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.channel != null) {
      _nameController.text = widget.channel!.channelName;
      _idController.text = widget.channel!.channelId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.channel == null ? 'Add Channel' : 'Edit Channel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(context,
                  controller: _nameController,
                  hint: 'e.g. BBC Learning English',
                  title: 'Channel Name *',
                  hasImageUpload: false),
              const SizedBox(height: 20),
              buildTextField(context,
                  controller: _idController,
                  hint: 'e.g. UCeTVocttFCYK_wIhqpeqZQA',
                  title: 'Channel ID *',
                  hasImageUpload: false),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          buttonController: _btnController,
          text: widget.channel == null ? 'Save' : 'Update',
          onPressed: _handleSubmit,
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _btnController.start();
      try {
        final name = _nameController.text.trim();
        final id = _idController.text.trim();

        if (widget.channel == null) {
          // Insert
          await SupabaseService().client.from('youtube_channels').insert({
            'channel_name': name,
            'channel_id': id,
          });
        } else {
          // Update
          await SupabaseService()
              .client
              .from('youtube_channels')
              .update({
                'channel_name': name,
                'channel_id': id,
              })
              .eq('id', widget.channel!.id);
        }

        _btnController.success();
        if (mounted) {
          openSuccessToast(
              context,
              widget.channel == null
                  ? 'Channel added successfully!'
                  : 'Channel updated successfully!');
          widget.onSaved(); // Callback to refresh parent
          Navigator.pop(context);
        }
      } catch (e) {
        _btnController.error();
        debugPrint('Error saving channel: $e');
        if (mounted) openFailureToast(context, 'Error: $e');
        Future.delayed(const Duration(seconds: 2), () => _btnController.reset());
      }
    }
  }
}
