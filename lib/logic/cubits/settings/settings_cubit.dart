import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundrymu_app/core/constants/app_constants.dart';
import 'package:kreatif_laundrymu_app/core/api/api_service.dart';
import 'package:kreatif_laundrymu_app/data/repositories/settings_repository.dart';
import 'package:kreatif_laundrymu_app/logic/cubits/settings/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository(),
        super(SettingsInitial());

  LaundryInfo? _currentInfo;
  LaundryInfo? get currentInfo => _currentInfo;

  Future<void> loadSettings() async {
    emit(SettingsLoading());

    try {
      final settings = await _repository.getAllSettings();

      final laundryInfo = LaundryInfo(
        name: settings[AppConstants.keyLaundryName] ??
            AppConstants.defaultLaundryName,
        address: settings[AppConstants.keyLaundryAddress] ??
            AppConstants.defaultLaundryAddress,
        phone: settings[AppConstants.keyLaundryPhone] ??
            AppConstants.defaultLaundryPhone,
        invoicePrefix: settings[AppConstants.keyInvoicePrefix] ??
            AppConstants.defaultInvoicePrefix,
        baseUrl: settings[AppConstants.keyBaseUrl] ??
            AppConstants.defaultBaseUrl,
        fonnteToken: settings[AppConstants.keyFonnteToken] ?? AppConstants.defaultFonnteToken,
        plantId: settings[AppConstants.keyPlantId] ?? AppConstants.defaultPlantId,
        plantCode: settings[AppConstants.keyPlantCode] ?? AppConstants.defaultPlantCode,
        plantName: settings[AppConstants.keyPlantName] ?? AppConstants.defaultPlantName,
      );

      // Initialize ApiService with loaded URL
      ApiService().setBaseUrl(laundryInfo.baseUrl);

      _currentInfo = laundryInfo;
      emit(SettingsLoaded(laundryInfo: laundryInfo));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memuat pengaturan: ${e.toString()}'));
    }
  }

  // ... existing update methods ...

  Future<void> updateBaseUrl(String url) async {
    if (url.trim().isEmpty) {
      emit(const SettingsError(message: 'Base URL tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyBaseUrl, url.trim());

      // Update ApiService
      ApiService().setBaseUrl(url.trim());

      final updatedInfo = _currentInfo!.copyWith(baseUrl: url.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Base URL berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui Base URL: ${e.toString()}'));
    }
  }

  Future<void> updateLaundryName(String name) async {
    if (name.trim().isEmpty) {
      emit(const SettingsError(message: 'Nama laundry tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyLaundryName, name.trim());

      final updatedInfo = _currentInfo!.copyWith(name: name.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nama laundry berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui nama: ${e.toString()}'));
    }
  }

  Future<void> updateLaundryAddress(String address) async {
    if (address.trim().isEmpty) {
      emit(const SettingsError(message: 'Alamat tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(
          AppConstants.keyLaundryAddress, address.trim());

      final updatedInfo = _currentInfo!.copyWith(address: address.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Alamat berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui alamat: ${e.toString()}'));
    }
  }

  Future<void> updateLaundryPhone(String phone) async {
    if (phone.trim().isEmpty) {
      emit(const SettingsError(message: 'Nomor HP tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyLaundryPhone, phone.trim());

      final updatedInfo = _currentInfo!.copyWith(phone: phone.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nomor HP berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(
          SettingsError(message: 'Gagal memperbarui nomor HP: ${e.toString()}'));
    }
  }

  Future<void> updateInvoicePrefix(String prefix) async {
    if (prefix.trim().isEmpty) {
      emit(const SettingsError(message: 'Prefix invoice tidak boleh kosong'));
      return;
    }

    if (prefix.trim().length > 10) {
      emit(const SettingsError(message: 'Prefix invoice maksimal 10 karakter'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(
          AppConstants.keyInvoicePrefix, prefix.trim().toUpperCase());

      final updatedInfo =
          _currentInfo!.copyWith(invoicePrefix: prefix.trim().toUpperCase());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Prefix invoice berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(
          message: 'Gagal memperbarui prefix invoice: ${e.toString()}'));
    }
  }

  Future<void> updateFonnteToken(String token) async {
    emit(SettingsUpdating());

    try {
      await _repository.setSetting('fonnte_token', token.trim());

      final updatedInfo = _currentInfo!.copyWith(fonnteToken: token.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Token Fonnte berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(
          message: 'Gagal memperbarui token Fonnte: ${e.toString()}'));
    }
  }

  Future<void> updatePlantId(String plantId) async {
    if (plantId.trim().isEmpty) {
      emit(const SettingsError(message: 'Plant ID tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyPlantId, plantId.trim());

      final updatedInfo = _currentInfo!.copyWith(plantId: plantId.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Plant ID berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui Plant ID: ${e.toString()}'));
    }
  }

  Future<void> updatePlantCode(String plantCode) async {
    if (plantCode.trim().isEmpty) {
      emit(const SettingsError(message: 'Plant Code tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyPlantCode, plantCode.trim());

      final updatedInfo = _currentInfo!.copyWith(plantCode: plantCode.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Plant Code berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui Plant Code: ${e.toString()}'));
    }
  }

  Future<void> updatePlantName(String plantName) async {
    if (plantName.trim().isEmpty) {
      emit(const SettingsError(message: 'Plant Name tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyPlantName, plantName.trim());

      final updatedInfo = _currentInfo!.copyWith(plantName: plantName.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Plant Name berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui Plant Name: ${e.toString()}'));
    }
  }
}
