import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/forms/youtube_channel_form.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/models/youtube_channel.dart';
import 'package:lms_admin/services/supabase_service.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/utils/toasts.dart';

class YouTubeChannelsTab extends StatefulWidget {
  const YouTubeChannelsTab({Key? key}) : super(key: key);

  @override
  State<YouTubeChannelsTab> createState() => _YouTubeChannelsTabState();
}

class _YouTubeChannelsTabState extends State<YouTubeChannelsTab> {
  // Using a FutureBuilder for simplicity in this MVP
  late Future<List<YouTubeChannel>> _channelsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _channelsFuture = _fetchChannels();
    });
  }

  Future<List<YouTubeChannel>> _fetchChannels() async {
    try {
      final response = await SupabaseService()
          .client
          .from('youtube_channels')
          .select()
          .order('created_at', ascending: false);
      final List data = response as List;
      return data.map((e) => YouTubeChannel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching channels: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'YouTube Channels', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Add Channel',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(
                  context,
                  widget: YouTubeChannelForm(onSaved: _refresh),
                );
              },
            ),
          ]),
          Expanded(
            child: FutureBuilder<List<YouTubeChannel>>(
              future: _channelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final channels = snapshot.data ?? [];

                if (channels.isEmpty) {
                  return const Center(child: Text('No curated channels found.'));
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Name'), size: ColumnSize.L),
                      DataColumn(label: Text('Channel ID')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: channels.map((channel) {
                      return DataRow(cells: [
                        DataCell(Text(channel.channelName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(channel.channelId)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                CustomDialogs.openResponsiveDialog(
                                  context,
                                  widget: YouTubeChannelForm(
                                    channel: channel,
                                    onSaved: _refresh,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteChannel(channel),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteChannel(YouTubeChannel channel) async {
    // Simple confirmation could be added here
    try {
      await SupabaseService()
          .client
          .from('youtube_channels')
          .delete()
          .eq('id', channel.id);
      openSuccessToast(context, 'Channel deleted');
      _refresh();
    } catch (e) {
      openFailureToast(context, 'Error deleting: $e');
    }
  }
}
