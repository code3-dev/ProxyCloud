import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Helper class for easy translation access throughout the app
class AppLocalizations {
  final LanguageProvider _languageProvider;

  AppLocalizations(this._languageProvider);

  /// Get translation for a key
  String translate(String key, {Map<String, String>? parameters}) {
    return _languageProvider.translate(key, parameters: parameters);
  }

  /// Alias for translate method
  String tr(String key, {Map<String, String>? parameters}) {
    return translate(key, parameters: parameters);
  }

  /// Get current language
  String get currentLanguageCode => _languageProvider.currentLanguage.code;

  /// Get current language name
  String get currentLanguageName => _languageProvider.currentLanguage.name;

  /// Check if current language is RTL
  bool get isRtl => _languageProvider.isRtl;

  /// Get text direction
  TextDirection get textDirection => _languageProvider.textDirection;

  /// Get locale
  Locale get locale => _languageProvider.locale;

  /// Get instance from context
  static AppLocalizations of(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    return AppLocalizations(languageProvider);
  }

  /// Get instance from context with listen capability
  static AppLocalizations watch(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: true,
    );
    return AppLocalizations(languageProvider);
  }

  /// Check if translation exists
  bool hasTranslation(String key) {
    return _languageProvider.hasTranslation(key);
  }
}

/// Extension on BuildContext for easy access to translations
extension LocalizationExtension on BuildContext {
  /// Get AppLocalizations instance
  AppLocalizations get loc => AppLocalizations.of(this);

  /// Get AppLocalizations instance with listen
  AppLocalizations get locWatch => AppLocalizations.watch(this);

  /// Quick translation access
  String tr(String key, {Map<String, String>? parameters}) {
    return loc.translate(key, parameters: parameters);
  }

  /// Check if translation exists
  bool hasTranslation(String key) {
    return loc.hasTranslation(key);
  }

  /// Get current language code
  String get currentLanguageCode => loc.currentLanguageCode;

  /// Check if current language is RTL
  bool get isRtl => loc.isRtl;

  /// Get text direction
  TextDirection get textDirection => loc.textDirection;
}

/// Widget extension for easy localization
mixin LocalizedStateMixin<T extends StatefulWidget> on State<T> {
  AppLocalizations get loc => AppLocalizations.of(context);

  String tr(String key, {Map<String, String>? parameters}) {
    return loc.translate(key, parameters: parameters);
  }

  bool hasTranslation(String key) {
    return loc.hasTranslation(key);
  }
}

/// Stateless widget mixin for localization
mixin LocalizedStatelessMixin {
  AppLocalizations loc(BuildContext context) => AppLocalizations.of(context);

  String tr(
    BuildContext context,
    String key, {
    Map<String, String>? parameters,
  }) {
    return loc(context).translate(key, parameters: parameters);
  }

  bool hasTranslation(BuildContext context, String key) {
    return loc(context).hasTranslation(key);
  }
}

/// Common translation keys as constants for better IDE support
class TranslationKeys {
  // App
  static const String appTitle = 'app.title';
  static const String appSubtitle = 'app.subtitle';

  // Navigation
  static const String navVpn = 'navigation.vpn';
  static const String navProxy = 'navigation.proxy';
  static const String navStore = 'navigation.store';
  static const String navTools = 'navigation.tools';

  // Tools
  static const String toolsTitle = 'tools.title';
  static const String toolsLanguageSettings = 'tools.language_settings';
  static const String toolsLanguageSettingsDesc =
      'tools.language_settings_desc';
  static const String toolsSubscriptionManager = 'tools.subscription_manager';
  static const String toolsIpInformation = 'tools.ip_information';
  static const String toolsHostChecker = 'tools.host_checker';
  static const String toolsSpeedTest = 'tools.speed_test';
  static const String toolsBlockedApps = 'tools.blocked_apps';
  static const String toolsPerAppTunnel = 'tools.per_app_tunnel';
  static const String toolsHomeWallpaper = 'tools.home_wallpaper';
  static const String toolsWallpaperStore = 'tools.wallpaper_store';
  static const String toolsVpnSettings = 'tools.vpn_settings';
  static const String toolsBatteryBackground = 'tools.battery_background';
  static const String toolsBackupRestore = 'tools.backup_restore';

  // Language Settings
  static const String langTitle = 'language_settings.title';
  static const String langSubtitle = 'language_settings.subtitle';
  static const String langCurrent = 'language_settings.current_language';
  static const String langAvailable = 'language_settings.available_languages';
  static const String langChanged = 'language_settings.language_changed';
  static const String langRestartRequired =
      'language_settings.restart_required';
  static const String langSelect = 'language_settings.select_language';

  // Home
  static const String homeTitle = 'home.title';
  static const String homeConnect = 'home.connect';
  static const String homeDisconnect = 'home.disconnect';
  static const String homeConnecting = 'home.connecting';
  static const String homeConnected = 'home.connected';
  static const String homeDisconnected = 'home.disconnected';
  static const String homeConnectionFailed = 'home.connection_failed';
  static const String homeSelectServer = 'home.select_server';
  static const String homeNoServerSelected = 'home.no_server_selected';
  static const String homeConnectionTime = 'home.connection_time';
  static const String homeTrafficUsage = 'home.traffic_usage';
  static const String homeDownload = 'home.download';
  static const String homeUpload = 'home.upload';
  static const String homeIpAddress = 'home.ip_address';
  static const String homeLocation = 'home.location';
  static const String homeRefresh = 'home.refresh';
  static const String homeSubscriptions = 'home.subscriptions';
  static const String homeAbout = 'home.about';
  static const String homeConnectionStatistics = 'home.connection_statistics';
  static const String homeCheckingConfig = 'home.checking_config';
  static const String homeConfigOk = 'home.config_ok';
  static const String homeConfigNotWorking = 'home.config_not_working';
  static const String homeCheckConfig = 'home.check_config';
  static const String homeCantGetIp = 'home.cant_get_ip';
  static const String homeFetching = 'home.fetching';
  static const String homeV2rayLinkCopied = 'home.v2ray_link_copied';
  static const String homeNoV2rayConfig = 'home.no_v2ray_config';
  static const String homeErrorCopying = 'home.error_copying';
  static const String homeIpInformation = 'home.ip_information';

  // Common
  static const String commonOk = 'common.ok';
  static const String commonCancel = 'common.cancel';
  static const String commonSave = 'common.save';
  static const String commonDelete = 'common.delete';
  static const String commonEdit = 'common.edit';
  static const String commonAdd = 'common.add';
  static const String commonRemove = 'common.remove';
  static const String commonBack = 'common.back';
  static const String commonNext = 'common.next';
  static const String commonClose = 'common.close';
  static const String commonRefresh = 'common.refresh';
  static const String commonLoading = 'common.loading';
  static const String commonError = 'common.error';
  static const String commonSuccess = 'common.success';
  static const String commonWarning = 'common.warning';
  static const String commonInfo = 'common.info';
  static const String commonYes = 'common.yes';
  static const String commonNo = 'common.no';
  static const String commonRetry = 'common.retry';
  static const String commonCopy = 'common.copy';
  static const String commonShare = 'common.share';
  static const String commonSettings = 'common.settings';
  static const String commonHelp = 'common.help';
  static const String commonSearch = 'common.search';
  static const String commonContact = 'common.contact';
  static const String commonContactOnTelegram = 'common.contact_on_telegram';
  static const String commonDismiss = 'common.dismiss';
  static const String commonLoadingApps = 'common.loading_apps';
  static const String commonExit = 'common.exit';
  static const String commonExitApp = 'common.exit_app';
  static const String commonExitConfirm = 'common.exit_confirm';
  static const String commonExitYes = 'common.exit_yes';
  static const String commonExitCancel = 'common.exit_cancel';

  // Server Selector
  static const String serverSelectorConnectionActive =
      'server_selector.connection_active';
  static const String serverSelectorDisconnectFirst =
      'server_selector.disconnect_first';
  static const String serverSelectorSelectServer =
      'server_selector.select_server';
  static const String serverSelectorLoadingServers =
      'server_selector.loading_servers';
  static const String serverSelectorNoServers = 'server_selector.no_servers';
  static const String serverSelectorAddSubscription =
      'server_selector.add_subscription';
  static const String serverSelectorErrorRefreshing =
      'server_selector.error_refreshing';

  // Server List Item
  static const String serverListItemDeleteConfiguration =
      'server_list_item.delete_configuration';
  static const String serverListItemDeleteConfirmation =
      'server_list_item.delete_confirmation';
  static const String serverListItemDelete = 'server_list_item.delete';
  static const String serverListItemDeleteTooltip =
      'server_list_item.delete_tooltip';
  static const String serverListItemConnect = 'server_list_item.connect';
  static const String serverListItemDisconnect = 'server_list_item.disconnect';
  static const String serverListItemDefaultSubscription =
      'server_list_item.default_subscription';

  // Server Bottom Sheet
  static const String serverBottomSheetSelectServer =
      'server_bottom_sheet.select_server';
  static const String serverBottomSheetStatus = 'server_bottom_sheet.status';
  static const String serverBottomSheetConnected =
      'server_bottom_sheet.connected';
  static const String serverBottomSheetDisconnected =
      'server_bottom_sheet.disconnected';
  static const String serverBottomSheetConnectionActive =
      'server_bottom_sheet.connection_active';
  static const String serverBottomSheetDisconnectFirst =
      'server_bottom_sheet.disconnect_first';

  // Update Service
  static const String updateServiceUpdateAvailable =
      'update_service.update_available';
  static const String updateServiceNewVersion = 'update_service.new_version';
  static const String updateServiceLater = 'update_service.later';
  static const String updateServiceDownload = 'update_service.download';
  static const String updateServiceCouldNotLaunch =
      'update_service.could_not_launch';

  // About Screen
  static const String aboutTitle = 'about.title';
  static const String aboutVersion = 'about.version';
  static const String aboutTagline = 'about.tagline';
  static const String aboutDevelopedBy = 'about.developed_by';
  static const String aboutDevelopers = 'about.developers';
  static const String aboutDescription = 'about.description';
  static const String aboutTelegramChannel = 'about.telegram_channel';
  static const String aboutGithubSource = 'about.github_source';
  static const String aboutPrivacyPolicy = 'about.privacy_policy';
  static const String aboutTermsOfService = 'about.terms_of_service';
  static const String aboutCopyright = 'about.copyright';

  // Backup Restore Screen
  static const String backupRestoreTitle = 'backup_restore.title';
  static const String backupRestoreBackupData = 'backup_restore.backup_data';
  static const String backupRestoreBackupDescription =
      'backup_restore.backup_description';
  static const String backupRestoreExportNow = 'backup_restore.export_now';
  static const String backupRestoreRestoreData = 'backup_restore.restore_data';
  static const String backupRestoreRestoreDescription =
      'backup_restore.restore_description';
  static const String backupRestoreImportNow = 'backup_restore.import_now';
  static const String backupRestoreBackupSaved = 'backup_restore.backup_saved';
  static const String backupRestoreErrorExporting =
      'backup_restore.error_exporting';
  static const String backupRestoreNoFileSelected =
      'backup_restore.no_file_selected';
  static const String backupRestoreDataImported =
      'backup_restore.data_imported';
  static const String backupRestoreErrorImporting =
      'backup_restore.error_importing';

  // Battery Settings Screen
  static const String batterySettingsTitle = 'battery_settings.title';
  static const String batterySettingsHeaderTitle =
      'battery_settings.header_title';
  static const String batterySettingsHeaderDescription =
      'battery_settings.header_description';
  static const String batterySettingsBatteryOptimization =
      'battery_settings.battery_optimization';
  static const String batterySettingsBatteryOptimizationDesc =
      'battery_settings.battery_optimization_desc';
  static const String batterySettingsOpenBatteryOptimization =
      'battery_settings.open_battery_optimization';
  static const String batterySettingsGeneralBattery =
      'battery_settings.general_battery';
  static const String batterySettingsGeneralBatteryDesc =
      'battery_settings.general_battery_desc';
  static const String batterySettingsOpenBatterySettings =
      'battery_settings.open_battery_settings';
  static const String batterySettingsAppSettings =
      'battery_settings.app_settings';
  static const String batterySettingsAppSettingsDesc =
      'battery_settings.app_settings_desc';
  static const String batterySettingsOpenAppSettings =
      'battery_settings.open_app_settings';
  static const String batterySettingsWhyDisable =
      'battery_settings.why_disable';
  static const String batterySettingsBenefitsList =
      'battery_settings.benefits_list';
  static const String batterySettingsImportantNote =
      'battery_settings.important_note';
  static const String batterySettingsDeviceNote =
      'battery_settings.device_note';
  static const String batterySettingsBatteryOptimizationOpened =
      'battery_settings.battery_optimization_opened';
  static const String batterySettingsGeneralBatteryOpened =
      'battery_settings.general_battery_opened';
  static const String batterySettingsAppSettingsOpened =
      'battery_settings.app_settings_opened';
  static const String batterySettingsErrorOpening =
      'battery_settings.error_opening';
  static const String batterySettingsOpening = 'battery_settings.opening';

  // Blocked Apps Screen
  static const String blockedAppsTitle = 'blocked_apps.title';
  static const String blockedAppsClearAllSelections =
      'blocked_apps.clear_all_selections';
  static const String blockedAppsSearchApps = 'blocked_apps.search_apps';
  static const String blockedAppsNoAppsFound = 'blocked_apps.no_apps_found';
  static const String blockedAppsNoMatchingApps =
      'blocked_apps.no_matching_apps';
  static const String blockedAppsUnknownApp = 'blocked_apps.unknown_app';
  static const String blockedAppsFailedToLoad = 'blocked_apps.failed_to_load';
  static const String blockedAppsNoAppsSelected =
      'blocked_apps.no_apps_selected';
  static const String blockedAppsSavedSuccessfully =
      'blocked_apps.saved_successfully';
  static const String blockedAppsFailedToSave = 'blocked_apps.failed_to_save';

  // Host Checker Screen
  static const String hostCheckerTitle = 'host_checker.title';
  static const String hostCheckerEnterUrl = 'host_checker.enter_url';
  static const String hostCheckerSelectDefaultUrl =
      'host_checker.select_default_url';
  static const String hostCheckerTimeoutSettings =
      'host_checker.timeout_settings';
  static const String hostCheckerTimeoutSeconds =
      'host_checker.timeout_seconds';
  static const String hostCheckerCheckHost = 'host_checker.check_host';
  static const String hostCheckerCheckingHost = 'host_checker.checking_host';
  static const String hostCheckerEnterUrlInstruction =
      'host_checker.enter_url_instruction';
  static const String hostCheckerErrorEmptyUrl = 'host_checker.error_empty_url';
  static const String hostCheckerErrorInvalidUrl =
      'host_checker.error_invalid_url';
  static const String hostCheckerErrorTimeout = 'host_checker.error_timeout';
  static const String hostCheckerErrorConnection =
      'host_checker.error_connection';
  static const String hostCheckerStatus = 'host_checker.status';
  static const String hostCheckerSuccess = 'host_checker.success';
  static const String hostCheckerFailed = 'host_checker.failed';
  static const String hostCheckerStatusCode = 'host_checker.status_code';
  static const String hostCheckerResponseTime = 'host_checker.response_time';
  static const String hostCheckerResponseDetails =
      'host_checker.response_details';
  static const String hostCheckerUrl = 'host_checker.url';
  static const String hostCheckerTimeoutUsed = 'host_checker.timeout_used';
  static const String hostCheckerContentLength = 'host_checker.content_length';
  static const String hostCheckerHeadersSecurityNote =
      'host_checker.headers_security_note';

  // Errors
  static const String errorNetwork = 'errors.network_error';
  static const String errorConnectionTimeout = 'errors.connection_timeout';
  static const String errorInvalidUrl = 'errors.invalid_url';
  static const String errorFileNotFound = 'errors.file_not_found';
  static const String errorPermissionDenied = 'errors.permission_denied';
  static const String errorUnknown = 'errors.unknown_error';
  static const String errorServerUnreachable = 'errors.server_unreachable';
  static const String errorInvalidConfiguration =
      'errors.invalid_configuration';
  static const String errorSubscription = 'errors.subscription_error';
  static const String errorParsing = 'errors.parsing_error';
  static const String errorStorage = 'errors.storage_error';
  static const String errorVpnConnection = 'errors.vpn_connection_failed';
  static const String errorProxyConnection = 'errors.proxy_connection_failed';
  static const String errorCouldNotOpenUrl = 'errors.could_not_open_url';

  // IP Information
  static const String ipInfoTitle = 'ip_info.title';
  static const String ipInfoSummary = 'ip_info.summary';
  static const String ipInfoDetails = 'ip_info.details';
  static const String ipInfoLocation = 'ip_info.location';
  static const String ipInfoNetwork = 'ip_info.network';
  static const String ipInfoIpAddress = 'ip_info.ip_address';
  static const String ipInfoIsp = 'ip_info.isp';
  static const String ipInfoQueryType = 'ip_info.query_type';
  static const String ipInfoQueryText = 'ip_info.query_text';
  static const String ipInfoReverseDns = 'ip_info.reverse_dns';
  static const String ipInfoLevel = 'ip_info.level';
  static const String ipInfoCountry = 'ip_info.country';
  static const String ipInfoRegion = 'ip_info.region';
  static const String ipInfoCity = 'ip_info.city';
  static const String ipInfoContinent = 'ip_info.continent';
  static const String ipInfoPostalCode = 'ip_info.postal_code';
  static const String ipInfoTimeZone = 'ip_info.time_zone';
  static const String ipInfoCoordinates = 'ip_info.coordinates';
  static const String ipInfoAccuracyRadius = 'ip_info.accuracy_radius';
  static const String ipInfoAsNumber = 'ip_info.as_number';
  static const String ipInfoNone = 'ip_info.none';
  static const String ipInfoKm = 'ip_info.km';
  static const String ipInfoFailedFetchInfo = 'ip_info.failed_fetch_info';
  static const String ipInfoFailedLoadData = 'ip_info.failed_load_data';
  static const String ipInfoFailedFetchDetails = 'ip_info.failed_fetch_details';
  static const String ipInfoNoInfoAvailable = 'ip_info.no_info_available';

  // Per-App Tunnel
  static const String perAppTunnelTitle = 'per_app_tunnel.title';
  static const String perAppTunnelInfoBanner = 'per_app_tunnel.info_banner';
  static const String perAppTunnelSearchHint = 'per_app_tunnel.search_hint';
  static const String perAppTunnelNoAppsFound = 'per_app_tunnel.no_apps_found';
  static const String perAppTunnelSelectAllTooltip =
      'per_app_tunnel.select_all_tooltip';
  static const String perAppTunnelClearSelectionTooltip =
      'per_app_tunnel.clear_selection_tooltip';
  static const String perAppTunnelAllBlocked = 'per_app_tunnel.all_blocked';
  static const String perAppTunnelUpdatedSuccessfully =
      'per_app_tunnel.updated_successfully';
  static const String perAppTunnelFailedSave = 'per_app_tunnel.failed_save';

  // Privacy Welcome
  static const String privacyWelcomeAcceptPrivacyPolicy =
      'privacy_welcome.accept_privacy_policy';
  static const String privacyWelcomePrivacyNotAcceptedTitle =
      'privacy_welcome.privacy_not_accepted_title';
  static const String privacyWelcomePrivacyNotAcceptedContent =
      'privacy_welcome.privacy_not_accepted_content';
  static const String privacyWelcomeProceedAnyway =
      'privacy_welcome.proceed_anyway';
  static const String privacyWelcomeBackgroundAccessRequired =
      'privacy_welcome.background_access_required';
  static const String privacyWelcomeBackgroundAccessContent =
      'privacy_welcome.background_access_content';
  static const String privacyWelcomeStay = 'privacy_welcome.stay';
  static const String privacyWelcomeOpeningGeneralBattery =
      'privacy_welcome.opening_general_battery';
  static const String privacyWelcomeGeneralBatteryOpened =
      'privacy_welcome.general_battery_opened';
  static const String privacyWelcomeErrorOpeningGeneralBattery =
      'privacy_welcome.error_opening_general_battery';
  static const String privacyWelcomeAppSettingsOpenedFallback =
      'privacy_welcome.app_settings_opened_fallback';
  static const String privacyWelcomeAllSettingsFailed =
      'privacy_welcome.all_settings_failed';
  static const String privacyWelcomeCouldNotOpenSettings =
      'privacy_welcome.could_not_open_settings';
  static const String privacyWelcomeOpeningBackgroundSettings =
      'privacy_welcome.opening_background_settings';
  static const String privacyWelcomeSettingsOpenedSuccessfully =
      'privacy_welcome.settings_opened_successfully';
  static const String privacyWelcomeErrorOpeningBatterySettings =
      'privacy_welcome.error_opening_battery_settings';
  static const String privacyWelcomeAppSettingsOpened =
      'privacy_welcome.app_settings_opened';
  static const String privacyWelcomeErrorOpeningAppSettings =
      'privacy_welcome.error_opening_app_settings';
  static const String privacyWelcomeSkip = 'privacy_welcome.skip';
  static const String privacyWelcomeGetStarted = 'privacy_welcome.get_started';
  static const String privacyWelcomeWelcomeTitle =
      'privacy_welcome.welcome_title';
  static const String privacyWelcomeWelcomeSubtitle =
      'privacy_welcome.welcome_subtitle';
  static const String privacyWelcomePrivacyTitle =
      'privacy_welcome.privacy_title';
  static const String privacyWelcomePrivacySubtitle =
      'privacy_welcome.privacy_subtitle';
  static const String privacyWelcomeIAccept = 'privacy_welcome.i_accept';
  static const String privacyWelcomeAnd = 'privacy_welcome.and';
  static const String privacyWelcomeCouldNotOpenPrivacy =
      'privacy_welcome.could_not_open_privacy';
  static const String privacyWelcomeCouldNotOpenTerms =
      'privacy_welcome.could_not_open_terms';
  static const String privacyWelcomeNoLimitsTitle =
      'privacy_welcome.no_limits_title';
  static const String privacyWelcomeNoLimitsSubtitle =
      'privacy_welcome.no_limits_subtitle';
  static const String privacyWelcomeBackgroundAccessTitle =
      'privacy_welcome.background_access_title';
  static const String privacyWelcomeBackgroundAccessSubtitle =
      'privacy_welcome.background_access_subtitle';
  static const String privacyWelcomeOpenSettings =
      'privacy_welcome.open_settings';
  static const String privacyWelcomeBatterySettings =
      'privacy_welcome.battery_settings';
  static const String privacyWelcomeBatteryOptimizationNote =
      'privacy_welcome.battery_optimization_note';
  static const String privacyWelcomeFreeToUseTitle =
      'privacy_welcome.free_to_use_title';
  static const String privacyWelcomeFreeToUseSubtitle =
      'privacy_welcome.free_to_use_subtitle';

  // Language Selection
  static const String selectLanguagePrompt = 'select_language_prompt';
  static const String selectLanguageTitle = 'select_language_title';
  static const String selectLanguageSubtitle = 'select_language_subtitle';

  // Channels and Sponsors
  static const String channelsAndSponsorsTitle = 'channels_and_sponsors_title';
  static const String internetForAll = 'internet_for_all';

  // Server Selection
  static const String serverSelectionTitle = 'server_selection.title';
  static const String serverSelectionSelectServer =
      'server_selection.select_server';
  static const String serverSelectionNoServers =
      'server_selection.no_servers_available';
  static const String serverSelectionAutoSelect =
      'server_selection.auto_select';
  static const String serverSelectionAutoSelectDescription =
      'server_selection.auto_select_description';
  static const String serverSelectionTestingServers =
      'server_selection.testing_servers';
  static const String serverSelectionConnectionActive =
      'server_selection.connection_active';
  static const String serverSelectionDisconnectFirst =
      'server_selection.disconnect_first';
  static const String serverSelectionUpdatingServers =
      'server_selection.updating_servers';
  static const String serverSelectionServersUpdated =
      'server_selection.servers_updated';
  static const String serverSelectionErrorUpdating =
      'server_selection.error_updating';
  static const String serverSelectionImportFromClipboard =
      'server_selection.import_from_clipboard';
  static const String serverSelectionClipboardEmpty =
      'server_selection.clipboard_empty';
  static const String serverSelectionImportSuccess =
      'server_selection.import_success';
  static const String serverSelectionImportFailed =
      'server_selection.import_failed';
  static const String serverSelectionDeleteConfig =
      'server_selection.delete_config';
  static const String serverSelectionDeleteSuccess =
      'server_selection.delete_success';
  static const String serverSelectionDeleteFailed =
      'server_selection.delete_failed';
  static const String serverSelectionConnectFailed =
      'server_selection.connect_failed';
  static const String serverSelectionTestPing = 'server_selection.test_ping';
  static const String serverSelectionSortByPing =
      'server_selection.sort_by_ping';
  static const String serverSelectionUpdateServers =
      'server_selection.update_servers';
  static const String serverSelectionLowestPing =
      'server_selection.lowest_ping';
  static const String serverSelectionTimeout = 'server_selection.timeout';
  static const String serverSelectionFastestConnection =
      'server_selection.fastest_connection';
  static const String serverSelectionTestingBatch =
      'server_selection.testing_batch';
  static const String serverSelectionBatchTimeout =
      'server_selection.batch_timeout';
  static const String serverSelectionNoSuitableServer =
      'server_selection.no_suitable_server';
  static const String serverSelectionTestingServer =
      'server_selection.testing_server';

  // Store Screen
  static const String storeScreenTitle = 'store_screen.title';
  static const String storeScreenSubscriptionStore =
      'store_screen.subscription_store';
  static const String storeScreenSearchHint = 'store_screen.search_hint';
  static const String storeScreenRetry = 'store_screen.retry';
  static const String storeScreenNoSubscriptions =
      'store_screen.no_subscriptions';
  static const String storeScreenUnknown = 'store_screen.unknown';
  static const String storeScreenCopyUrl = 'store_screen.copy_url';
  static const String storeScreenUrlCopied = 'store_screen.url_copied';
  static const String storeScreenAddToApp = 'store_screen.add_to_app';
  static const String storeScreenAddingSubscription =
      'store_screen.adding_subscription';
  static const String storeScreenSubscriptionAdded =
      'store_screen.subscription_added';
  static const String storeScreenSubscriptionExists =
      'store_screen.subscription_exists';
  static const String storeScreenFailedToLoad = 'store_screen.failed_to_load';
  static const String storeScreenAddNew = 'store_screen.add_new';
  static const String storeScreenContactTelegram =
      'store_screen.contact_telegram';
  static const String storeScreenCancel = 'store_screen.cancel';
  static const String storeScreenCouldNotLaunch =
      'store_screen.could_not_launch';

  // Subscription Management
  static const String subscriptionManagementTitle =
      'subscription_management.title';
  static const String subscriptionManagementManageSubs =
      'subscription_management.manage_subscriptions';
  static const String subscriptionManagementAddSubscription =
      'subscription_management.add_subscription';
  static const String subscriptionManagementEditSubscription =
      'subscription_management.edit_subscription';
  static const String subscriptionManagementName =
      'subscription_management.name';
  static const String subscriptionManagementUrl = 'subscription_management.url';
  static const String subscriptionManagementAdd = 'subscription_management.add';
  static const String subscriptionManagementUpdate =
      'subscription_management.update';
  static const String subscriptionManagementCancel =
      'subscription_management.cancel';
  static const String subscriptionManagementEnterName =
      'subscription_management.enter_name';
  static const String subscriptionManagementEnterUrl =
      'subscription_management.enter_url';
  static const String subscriptionManagementDuplicateNameTitle =
      'subscription_management.duplicate_name_title';
  static const String subscriptionManagementNameExists =
      'subscription_management.name_exists';
  static const String subscriptionManagementAddingSubscription =
      'subscription_management.adding_subscription';
  static const String subscriptionManagementSubscriptionAdded =
      'subscription_management.subscription_added';
  static const String subscriptionManagementUpdatingSubscription =
      'subscription_management.updating_subscription';
  static const String subscriptionManagementSubscriptionUpdated =
      'subscription_management.subscription_updated';
  static const String subscriptionManagementDeleteSubscription =
      'subscription_management.delete_subscription';
  static const String subscriptionManagementDeleteConfirmation =
      'subscription_management.delete_confirmation';
  static const String subscriptionManagementSubscriptionDeleted =
      'subscription_management.subscription_deleted';
  static const String subscriptionManagementUpdatingAll =
      'subscription_management.updating_all';
  static const String subscriptionManagementAllUpdated =
      'subscription_management.all_updated';
  static const String subscriptionManagementCannotDeleteDefault =
      'subscription_management.cannot_delete_default';
  static const String subscriptionManagementHowToAdd =
      'subscription_management.how_to_add';
  static const String subscriptionManagementUniqueNameForSub =
      'subscription_management.unique_name_for_subscription';
  static const String subscriptionManagementFormatRequirements =
      'subscription_management.format_requirements';
  static const String subscriptionManagementV2RayConfigs =
      'subscription_management.v2ray_configs';
  static const String subscriptionManagementOnePerLine =
      'subscription_management.one_per_line';
  static const String subscriptionManagementSupports =
      'subscription_management.supports';
  static const String subscriptionManagementExample =
      'subscription_management.example';
  static const String subscriptionManagementSteps =
      'subscription_management.steps';
  static const String subscriptionManagementUniqueName =
      'subscription_management.unique_name_step';
  static const String subscriptionManagementUrlWithConfigs =
      'subscription_management.url_with_configs';
  static const String subscriptionManagementImportFromFile =
      'subscription_management.import_from_file';
  static const String subscriptionManagementGotIt =
      'subscription_management.got_it';
  static const String subscriptionManagementNoSubscriptions =
      'subscription_management.no_subscriptions';
  static const String subscriptionManagementLastUpdated =
      'subscription_management.last_updated';
  static const String subscriptionManagementServers =
      'subscription_management.servers';
  static const String subscriptionManagementDay = 'subscription_management.day';
  static const String subscriptionManagementDays =
      'subscription_management.days';
  static const String subscriptionManagementHour =
      'subscription_management.hour';
  static const String subscriptionManagementHours =
      'subscription_management.hours';
  static const String subscriptionManagementMinute =
      'subscription_management.minute';
  static const String subscriptionManagementMinutes =
      'subscription_management.minutes';
  static const String subscriptionManagementAgo = 'subscription_management.ago';
  static const String subscriptionManagementJustNow =
      'subscription_management.just_now';
  static const String subscriptionManagementEdit =
      'subscription_management.edit';
  static const String subscriptionManagementDelete =
      'subscription_management.delete';
  static const String subscriptionManagementHelp =
      'subscription_management.help';
  static const String subscriptionManagementUpdateAll =
      'subscription_management.update_all';
  static const String subscriptionManagementResetDefaultUrl =
      'subscription_management.reset_default_url';
  static const String subscriptionManagementResetDefaultUrlTitle =
      'subscription_management.reset_default_url_title';
  static const String subscriptionManagementResetDefaultUrlConfirmation =
      'subscription_management.reset_default_url_confirmation';
  static const String subscriptionManagementDefaultUrlReset =
      'subscription_management.default_url_reset';

  // Telegram Proxy Screen
  static const String telegramProxyTitle = 'telegram_proxy.title';
  static const String telegramProxyRefresh = 'telegram_proxy.refresh';
  static const String telegramProxyErrorLoading =
      'telegram_proxy.error_loading';
  static const String telegramProxyTryAgain = 'telegram_proxy.try_again';
  static const String telegramProxyNoProxies = 'telegram_proxy.no_proxies';
  static const String telegramProxyPort = 'telegram_proxy.port';
  static const String telegramProxyCountry = 'telegram_proxy.country';
  static const String telegramProxyProvider = 'telegram_proxy.provider';
  static const String telegramProxyPing = 'telegram_proxy.ping';
  static const String telegramProxyUptime = 'telegram_proxy.uptime';
  static const String telegramProxyCopyDetails = 'telegram_proxy.copy_details';
  static const String telegramProxyCopyUrl = 'telegram_proxy.copy_url';
  static const String telegramProxyDetailsCopied =
      'telegram_proxy.details_copied';
  static const String telegramProxyUrlCopied = 'telegram_proxy.url_copied';
  static const String telegramProxyConnect = 'telegram_proxy.connect';
  static const String telegramProxyLaunchError = 'telegram_proxy.launch_error';
  static const String telegramProxyNotInstalled =
      'telegram_proxy.not_installed';

  // Wallpaper Settings Screen
  static const String wallpaperSettingsTitle = 'wallpaper_settings.title';
  static const String wallpaperSettingsCurrent = 'wallpaper_settings.current';
  static const String wallpaperSettingsDefault = 'wallpaper_settings.default';
  static const String wallpaperSettingsActions = 'wallpaper_settings.actions';
  static const String wallpaperSettingsSelect = 'wallpaper_settings.select';
  static const String wallpaperSettingsRemove = 'wallpaper_settings.remove';
  static const String wallpaperSettingsRemoveTitle =
      'wallpaper_settings.remove_title';
  static const String wallpaperSettingsRemoveContent =
      'wallpaper_settings.remove_content';
  static const String wallpaperSettingsSetSuccess =
      'wallpaper_settings.set_success';
  static const String wallpaperSettingsNoImage = 'wallpaper_settings.no_image';
  static const String wallpaperSettingsRemoveSuccess =
      'wallpaper_settings.remove_success';
  static const String wallpaperSettingsErrorSet =
      'wallpaper_settings.error_set';
  static const String wallpaperSettingsErrorRemove =
      'wallpaper_settings.error_remove';
  static const String wallpaperSettingsImageNotFound =
      'wallpaper_settings.image_not_found';
  static const String wallpaperSettingsFailedLoad =
      'wallpaper_settings.failed_load';
  static const String wallpaperSettingsDefaultBackground =
      'wallpaper_settings.default_background';
  static const String wallpaperSettingsInfo = 'wallpaper_settings.info';
  static const String wallpaperSettingsVisitStore =
      'wallpaper_settings.visit_store';
  static const String wallpaperSettingsStoreButton =
      'wallpaper_settings.store_button';
  static const String wallpaperSettingsGlassBackground =
      'wallpaper_settings.glass_background';
  static const String wallpaperSettingsGlassBackgroundDesc =
      'wallpaper_settings.glass_background_desc';

  // Wallpaper Store Screen
  static const String wallpaperStoreTitle = 'wallpaper_store.title';
  static const String wallpaperStoreLoading = 'wallpaper_store.loading';
  static const String wallpaperStoreErrorLoading =
      'wallpaper_store.error_loading';
  static const String wallpaperStoreRetry = 'wallpaper_store.retry';
  static const String wallpaperStoreNoWallpapers =
      'wallpaper_store.no_wallpapers';
  static const String wallpaperStoreSetAsWallpaper =
      'wallpaper_store.set_as_wallpaper';
  static const String wallpaperStoreDownload = 'wallpaper_store.download';
  static const String wallpaperStoreDownloadSuccess =
      'wallpaper_store.download_success';
  static const String wallpaperStoreDownloadError =
      'wallpaper_store.download_error';
  static const String wallpaperStoreSetSuccess = 'wallpaper_store.set_success';

  // VPN Settings Screen
  static const String vpnSettingsTitle = 'vpn_settings.title';
  static const String vpnSettingsSave = 'vpn_settings.save';
  static const String vpnSettingsBypassSubnets = 'vpn_settings.bypass_subnets';
  static const String vpnSettingsBypassSubnetsDesc =
      'vpn_settings.bypass_subnets_desc';
  static const String vpnSettingsBypassSubnetsHint =
      'vpn_settings.bypass_subnets_hint';
  static const String vpnSettingsResetDefault = 'vpn_settings.reset_default';
  static const String vpnSettingsClearAll = 'vpn_settings.clear_all';
  static const String vpnSettingsCustomDns = 'vpn_settings.custom_dns';
  static const String vpnSettingsCustomDnsDesc = 'vpn_settings.custom_dns_desc';
  static const String vpnSettingsCustomDnsHint = 'vpn_settings.custom_dns_hint';
  static const String vpnSettingsDnsResetDefault =
      'vpn_settings.dns_reset_default';
  static const String vpnSettingsChangesEffect = 'vpn_settings.changes_effect';
  static const String vpnSettingsAboutBypass = 'vpn_settings.about_bypass';
  static const String vpnSettingsPingBatchSize = 'vpn_settings.ping_batch_size';
  static const String vpnSettingsPingBatchSizeDesc =
      'vpn_settings.ping_batch_size_desc';
  static const String vpnSettingsAboutBypassDesc =
      'vpn_settings.about_bypass_desc';
  static const String vpnSettingsAboutBypassExample =
      'vpn_settings.about_bypass_example';
  static const String vpnSettingsSavedSuccess = 'vpn_settings.saved_success';
  static const String vpnSettingsErrorLoading = 'vpn_settings.error_loading';
  static const String vpnSettingsErrorSaving = 'vpn_settings.error_saving';
  // Proxy Mode translations
  static const String vpnSettingsProxyMode = 'vpn_settings.proxy_mode';
  static const String vpnSettingsProxyModeDesc = 'vpn_settings.proxy_mode_desc';
  static const String vpnSettingsProxyInformation =
      'vpn_settings.proxy_information';
  static const String vpnSettingsSocksProxy = 'vpn_settings.socks_proxy';
  static const String vpnSettingsHttpProxy = 'vpn_settings.http_proxy';
  static const String vpnSettingsProxyNote = 'vpn_settings.proxy_note';

  // Persian Gulf Page
  static const String persianGulfTitle = 'persian_gulf.title';
  static const String persianGulfMessage = 'persian_gulf.message';
  static const String persianGulfCardTitle = 'persian_gulf.card_title';

  // IRCF Channel
  static const String ircfChannel = 'ircf.channel';
}

/// Translation helper functions
class TrHelper {
  /// Format error message with URL parameter
  static String errorUrlFormat(BuildContext context, String url) {
    return context.tr(
      TranslationKeys.errorCouldNotOpenUrl,
      parameters: {'url': url},
    );
  }

  /// Format version string
  static String versionFormat(
    BuildContext context,
    String version, {
    bool isNew = false,
  }) {
    final key = isNew ? 'tools.new_version' : 'tools.current_version';
    return context.tr(key, parameters: {'version': version});
  }
}
