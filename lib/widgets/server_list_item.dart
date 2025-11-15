import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2ray_config.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';

class ServerListItem extends StatefulWidget {
  final V2RayConfig config;

  const ServerListItem({Key? key, required this.config}) : super(key: key);

  @override
  State<ServerListItem> createState() => _ServerListItemState();
}

class _ServerListItemState extends State<ServerListItem> {
  @override
  void initState() {
    super.initState();
    // Ping functionality removed
  }

  @override
  void didUpdateWidget(ServerListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ping functionality removed
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<V2RayProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, _) {
        final isActive = provider.activeConfig?.id == widget.config.id;
        final isSelected = provider.selectedConfig?.id == widget.config.id;

        return Directionality(
          textDirection: languageProvider.textDirection,
          child: _buildServerItem(context, provider, isActive, isSelected),
        );
      },
    );
  }

  Widget _buildServerItem(
    BuildContext context,
    V2RayProvider provider,
    bool isActive,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () async {
          await provider.selectConfig(widget.config);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.config.remark,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                context.tr(
                                  TranslationKeys
                                      .serverListItemDeleteConfiguration,
                                ),
                              ),
                              content: Text(
                                context.tr(
                                  TranslationKeys
                                      .serverListItemDeleteConfirmation,
                                  parameters: {'server': widget.config.remark},
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    context.tr(TranslationKeys.commonCancel),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.removeConfig(widget.config);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    context.tr(
                                      TranslationKeys.serverListItemDelete,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: context.tr(
                          TranslationKeys.serverListItemDeleteTooltip,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.config.address}:${widget.config.port}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfigTypeColor(widget.config.configType),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.config.configType.toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getSubscriptionName(context),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    ElevatedButton(
                      onPressed: isActive
                          ? () async => await provider.disconnect()
                          : () async => await provider.connectToServer(
                              widget.config,
                              provider.isProxyMode,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isActive
                            ? context.tr(
                                TranslationKeys.serverListItemDisconnect,
                              )
                            : context.tr(TranslationKeys.serverListItemConnect),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfigTypeColor(String configType) {
    switch (configType.toString().toLowerCase()) {
      case 'vmess':
        return Colors.blue;
      case 'vless':
        return Colors.green;
      case 'shadowsocks':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSubscriptionName(BuildContext context) {
    final provider = Provider.of<V2RayProvider>(context, listen: false);
    final subscriptions = provider.subscriptions;

    // Find which subscription this config belongs to
    String subscriptionName = context.tr(
      TranslationKeys.serverListItemDefaultSubscription,
    );
    for (var subscription in subscriptions) {
      if (subscription.configIds.contains(widget.config.id)) {
        subscriptionName = subscription.name;
        break;
      }
    }

    return subscriptionName;
  }
}
