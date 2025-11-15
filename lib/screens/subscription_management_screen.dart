import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/subscription.dart';
import '../providers/v2ray_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_snackbar.dart';
import '../utils/app_localizations.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isUpdating = false;
  bool _isEditingDefaultSubscription = false;
  String? _currentSubscriptionId;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'yaml', 'yml'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      // Parse the content as subscription configs
      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final configs = await provider.parseSubscriptionContent(content);

      if (configs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No valid configurations found in file'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.subscriptionManagementEnterName),
            ),
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.subscriptionManagementAddingSubscription,
            ),
          ),
        ),
      );

      // Add configs and display them immediately
      final v2rayProvider = Provider.of<V2RayProvider>(context, listen: false);
      await v2rayProvider.addSubscriptionFromFile(name, configs);

      // Check if there was an error
      if (v2rayProvider.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(v2rayProvider.errorMessage),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        v2rayProvider.clearError();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementSubscriptionAdded,
              ),
            ),
          ),
        );
      }

      // Reset the form
      _resetForm();
    } catch (e) {
      ErrorSnackbar.show(
        context,
        '${context.tr(TranslationKeys.errorUnknown)}: ${e.toString()}',
      );
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _urlController.clear();
      _isUpdating = false;
      _isEditingDefaultSubscription = false;
      _currentSubscriptionId = null;
    });
  }

  void _prepareForUpdate(Subscription subscription) {
    setState(() {
      _nameController.text = subscription.name;
      _urlController.text = subscription.url;
      _isUpdating = true;
      _isEditingDefaultSubscription =
          subscription.name.toLowerCase() == 'default subscription';
      _currentSubscriptionId = subscription.id;
    });
  }

  Future<void> _addOrUpdateSubscription(BuildContext context) async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.subscriptionManagementEnterName),
          ),
        ),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.subscriptionManagementEnterUrl),
          ),
        ),
      );
      return;
    }

    final provider = Provider.of<V2RayProvider>(context, listen: false);

    // Check for duplicate name when adding a new subscription
    if (!_isUpdating) {
      final nameExists = provider.subscriptions.any(
        (sub) => sub.name.toLowerCase() == name.toLowerCase(),
      );
      if (nameExists) {
        // Show error dialog for duplicate name
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.secondaryDark,
            title: Text(
              context.tr(
                TranslationKeys.subscriptionManagementDuplicateNameTitle,
              ),
            ),
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementNameExists,
                parameters: {'name': name},
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr(TranslationKeys.commonOk),
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        );
        return;
      }
    } else if (_currentSubscriptionId != null) {
      // When updating, check if the new name conflicts with any subscription other than the current one
      final nameExists = provider.subscriptions.any(
        (sub) =>
            sub.name.toLowerCase() == name.toLowerCase() &&
            sub.id != _currentSubscriptionId,
      );
      if (nameExists) {
        // Show error dialog for duplicate name
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.secondaryDark,
            title: Text(
              context.tr(
                TranslationKeys.subscriptionManagementDuplicateNameTitle,
              ),
            ),
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementNameExists,
                parameters: {'name': name},
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr(TranslationKeys.commonOk),
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      if (_isUpdating && _currentSubscriptionId != null) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementUpdatingSubscription,
              ),
            ),
          ),
        );

        // Find the subscription to update
        final subscription = provider.subscriptions.firstWhere(
          (sub) => sub.id == _currentSubscriptionId,
        );

        // Create updated subscription
        final updatedSubscription = subscription.copyWith(name: name, url: url);

        // Update the subscription
        await provider.updateSubscriptionInfo(updatedSubscription);

        // Check if there was an error
        if (provider.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearError();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  TranslationKeys.subscriptionManagementSubscriptionUpdated,
                ),
              ),
            ),
          );
        }
      } else {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementAddingSubscription,
              ),
            ),
          ),
        );

        // Add new subscription
        await provider.addSubscription(name, url);

        // Check if there was an error
        if (provider.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearError();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  TranslationKeys.subscriptionManagementSubscriptionAdded,
                ),
              ),
            ),
          );
        }
      }

      // Reset the form
      _resetForm();
    } catch (e) {
      ErrorSnackbar.show(
        context,
        '${context.tr(TranslationKeys.errorUnknown)}: ${e.toString()}',
      );
    }
  }

  Future<void> _deleteSubscription(
    BuildContext context,
    Subscription subscription,
  ) async {
    // Show confirmation dialog
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.secondaryDark,
            title: Text(
              context.tr(
                TranslationKeys.subscriptionManagementDeleteSubscription,
              ),
            ),
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementDeleteConfirmation,
                parameters: {'name': subscription.name},
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.tr(TranslationKeys.commonCancel),
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  context.tr(TranslationKeys.commonDelete),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      final provider = Provider.of<V2RayProvider>(context, listen: false);

      try {
        await provider.removeSubscription(subscription);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.subscriptionManagementSubscriptionDeleted,
              ),
            ),
          ),
        );

        // If we were editing this subscription, reset the form
        if (_isUpdating && _currentSubscriptionId == subscription.id) {
          _resetForm();
        }
      } catch (e) {
        ErrorSnackbar.show(
          context,
          '${context.tr(TranslationKeys.errorUnknown)}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _resetDefaultSubscriptionUrl(
    BuildContext context,
    Subscription subscription,
  ) async {
    // Show confirmation dialog
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.secondaryDark,
            title: Text(
              context.tr(
                TranslationKeys.subscriptionManagementResetDefaultUrlTitle,
              ),
            ),
            content: Text(
              context.tr(
                TranslationKeys
                    .subscriptionManagementResetDefaultUrlConfirmation,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.tr(TranslationKeys.commonCancel),
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  context.tr(TranslationKeys.commonOk),
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      final provider = Provider.of<V2RayProvider>(context, listen: false);

      try {
        // Create updated subscription with default URL
        final updatedSubscription = subscription.copyWith(
          url:
              'https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/refs/heads/main/proxy',
        );

        // Update the subscription
        await provider.updateSubscriptionInfo(updatedSubscription);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.subscriptionManagementDefaultUrlReset),
            ),
          ),
        );

        // If we were editing this subscription, update the form
        if (_isUpdating && _currentSubscriptionId == subscription.id) {
          setState(() {
            _urlController.text = updatedSubscription.url;
          });
        }
      } catch (e) {
        ErrorSnackbar.show(
          context,
          '${context.tr(TranslationKeys.errorUnknown)}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _updateAllSubscriptions(BuildContext context) async {
    final provider = Provider.of<V2RayProvider>(context, listen: false);

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.subscriptionManagementUpdatingAll),
          ),
        ),
      );

      await provider.updateAllSubscriptions();

      // Check if there was an error
      if (provider.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        provider.clearError();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.subscriptionManagementAllUpdated),
            ),
          ),
        );
      }
    } catch (e) {
      ErrorSnackbar.show(
        context,
        '${context.tr(TranslationKeys.errorUnknown)}: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          context.tr(TranslationKeys.subscriptionManagementManageSubs),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: context.tr(TranslationKeys.subscriptionManagementHelp),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _updateAllSubscriptions(context),
            tooltip: context.tr(
              TranslationKeys.subscriptionManagementUpdateAll,
            ),
          ),
        ],
      ),
      body: Consumer<V2RayProvider>(
        builder: (context, provider, _) {
          final subscriptions = provider.subscriptions;

          return Column(
            children: [
              // Add/Edit Subscription Form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: AppTheme.cardDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isUpdating
                              ? context.tr(
                                  TranslationKeys
                                      .subscriptionManagementEditSubscription,
                                )
                              : context.tr(
                                  TranslationKeys
                                      .subscriptionManagementAddSubscription,
                                ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          enabled:
                              !_isUpdating ||
                              (_isUpdating && !_isEditingDefaultSubscription),
                          decoration: InputDecoration(
                            labelText: context.tr(
                              TranslationKeys.subscriptionManagementName,
                            ),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppTheme.secondaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              TranslationKeys.subscriptionManagementUrl,
                            ),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppTheme.secondaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                context.tr(
                                  TranslationKeys
                                      .subscriptionManagementImportFromFile,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: _importFromFile,
                              child: Text(
                                context.tr(
                                  TranslationKeys
                                      .subscriptionManagementImportFromFile,
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isUpdating)
                              TextButton(
                                onPressed: _resetForm,
                                child: Text(
                                  context.tr(
                                    TranslationKeys
                                        .subscriptionManagementCancel,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _addOrUpdateSubscription(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                              child: Text(
                                _isUpdating
                                    ? context.tr(
                                        TranslationKeys
                                            .subscriptionManagementUpdate,
                                      )
                                    : context.tr(
                                        TranslationKeys
                                            .subscriptionManagementAdd,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Subscription List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : subscriptions.isEmpty
                    ? Center(
                        child: Text(
                          context.tr(
                            TranslationKeys
                                .subscriptionManagementNoSubscriptions,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: subscriptions.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final subscription = subscriptions[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppTheme.cardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(subscription.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subscription.url,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${context.tr(TranslationKeys.subscriptionManagementLastUpdated)}${_formatDate(subscription.lastUpdated)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${context.tr(TranslationKeys.subscriptionManagementServers)}${subscription.configIds.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _prepareForUpdate(subscription),
                                    tooltip: context.tr(
                                      TranslationKeys
                                          .subscriptionManagementEdit,
                                    ),
                                  ),
                                  if (subscription.name.toLowerCase() ==
                                      'default subscription')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.restart_alt,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () =>
                                          _resetDefaultSubscriptionUrl(
                                            context,
                                            subscription,
                                          ),
                                      tooltip: context.tr(
                                        TranslationKeys
                                            .subscriptionManagementResetDefaultUrl,
                                      ),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color:
                                          subscription.name.toLowerCase() ==
                                              'default subscription'
                                          ? Colors.grey
                                          : Colors.red,
                                    ),
                                    onPressed:
                                        subscription.name.toLowerCase() ==
                                            'default subscription'
                                        ? null
                                        : () => _deleteSubscription(
                                            context,
                                            subscription,
                                          ),
                                    tooltip:
                                        subscription.name.toLowerCase() ==
                                            'default subscription'
                                        ? context.tr(
                                            TranslationKeys
                                                .subscriptionManagementCannotDeleteDefault,
                                          )
                                        : context.tr(
                                            TranslationKeys
                                                .subscriptionManagementDelete,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? context.tr(TranslationKeys.subscriptionManagementDay) : context.tr(TranslationKeys.subscriptionManagementDays)} ${context.tr(TranslationKeys.subscriptionManagementAgo)}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? context.tr(TranslationKeys.subscriptionManagementHour) : context.tr(TranslationKeys.subscriptionManagementHours)} ${context.tr(TranslationKeys.subscriptionManagementAgo)}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? context.tr(TranslationKeys.subscriptionManagementMinute) : context.tr(TranslationKeys.subscriptionManagementMinutes)} ${context.tr(TranslationKeys.subscriptionManagementAgo)}';
    } else {
      return context.tr(TranslationKeys.subscriptionManagementJustNow);
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 10),
            Text(context.tr(TranslationKeys.subscriptionManagementHowToAdd)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  TranslationKeys.subscriptionManagementUniqueNameForSub,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(
                  TranslationKeys.subscriptionManagementFormatRequirements,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        TranslationKeys.subscriptionManagementV2RayConfigs,
                      ),
                    ),
                    Text(
                      context.tr(
                        TranslationKeys.subscriptionManagementOnePerLine,
                      ),
                    ),
                    Text(
                      context.tr(
                        TranslationKeys.subscriptionManagementSupports,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(context.tr(TranslationKeys.subscriptionManagementExample)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('vless://...'),
                    Text('vmess://...'),
                    Text('ss://...'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(TranslationKeys.subscriptionManagementSteps),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '1. ${context.tr(TranslationKeys.subscriptionManagementUniqueName)}',
              ),
              Text(
                '2. ${context.tr(TranslationKeys.subscriptionManagementUrlWithConfigs)}',
              ),
              Text(
                '3. ${context.tr(TranslationKeys.subscriptionManagementAdd)}',
              ),
              Text('4. ${context.tr(TranslationKeys.commonRefresh)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr(TranslationKeys.subscriptionManagementGotIt),
              style: const TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}
