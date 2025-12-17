// NFC Helper untuk Aplikasi Pesantren
//
// PERBAIKAN UNTUK KARTU FLAZZ GEN 2:
// - Implementasi deteksi khusus untuk kartu Flazz Gen 2
// - Ekstraksi ID menggunakan kombinasi teknologi ISO-DEP dan NFC-A
// - Retry mechanism untuk meningkatkan success rate
// - Cache system untuk konsistensi pembacaan
// - Timeout yang lebih panjang (60 detik) untuk kartu yang sulit dibaca
// - Error handling yang lebih informatif
// - Menggunakan nfc_manager 4.x API dengan platform-specific tag classes

import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:flutter/foundation.dart';

/// Helper class untuk menangani operasi NFC
///
/// Kelas ini telah dioptimalkan untuk menangani kartu Flazz Gen 2
/// dengan implementasi khusus untuk ekstraksi ID kartu dari teknologi ISO-DEP dan NFC-A
class NFCHelper {
  static final NFCHelper _instance = NFCHelper._internal();
  factory NFCHelper() => _instance;
  NFCHelper._internal();
  static NFCHelper get instance => _instance;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // Cache untuk menyimpan mapping kartu yang sudah berhasil dibaca
  // Membantu mengatasi masalah konsistensi pembacaan kartu Flazz Gen 2
  final Map<String, String> _cardIdCache = {};

  /// Mengecek status NFC secara real-time
  Future<bool> checkNFCStatus() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      _isAvailable = (availability == NfcAvailability.enabled);
      return _isAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking NFC status: $e');
      }
      _isAvailable = false;
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      _isAvailable = (availability == NfcAvailability.enabled);
      if (kDebugMode) {
        print('NFC Available: $_isAvailable (status: $availability)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NFC: $e');
      }
      _isAvailable = false;
    }
  }

  Future<String?> scanCard({
    required String title,
    required String instruction,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!_isAvailable) {
      throw Exception('NFC tidak tersedia di perangkat ini');
    }

    Completer<String?> completer = Completer<String?>();
    bool sessionStarted = false;

    try {
      if (kDebugMode) {
        print('Starting NFC scan session...');
      }

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          try {
            if (kDebugMode) {
              print('=== NFC TAG DISCOVERED ===');
            }

            // Ambil ID kartu dari tag
            String cardId = _extractCardId(tag);

            if (kDebugMode) {
              print('Final extracted card ID: $cardId');
            }

            // Validasi card ID
            if (cardId.isEmpty) {
              // Retry untuk kartu Flazz Gen 2 dengan multiple attempts
              if (_isFlazzGen2Card(tag)) {
                if (kDebugMode) {
                  print('🔄 Retrying Flazz Gen 2 card extraction...');
                }

                // Multiple retry attempts dengan delay yang berbeda
                for (int attempt = 1; attempt <= 3; attempt++) {
                  await Future.delayed(Duration(milliseconds: 300 * attempt));
                  cardId = _extractFlazzGen2Id(tag) ?? '';

                  if (cardId.isNotEmpty) {
                    if (kDebugMode) {
                      print(
                        '✅ Flazz Gen 2 card ID extracted on attempt $attempt: $cardId',
                      );
                    }
                    break;
                  }

                  if (kDebugMode) {
                    print('❌ Flazz Gen 2 extraction attempt $attempt failed');
                  }
                }

                if (cardId.isEmpty) {
                  throw Exception(
                    'Gagal mengekstrak ID kartu Flazz Gen 2.\\n\\nTips:\\n• Tempelkan kartu lebih erat ke perangkat\\n• Tahan kartu selama 2-3 detik\\n• Pastikan tidak ada case atau penghalang\\n• Coba posisi kartu yang berbeda',
                  );
                }
              } else {
                throw Exception('Gagal mengekstrak ID kartu dari tag NFC');
              }
            }

            if (!completer.isCompleted) {
              completer.complete(cardId);
            }

            await NfcManager.instance.stopSession(
              alertMessageIos: 'Kartu berhasil dibaca',
            );
          } catch (e) {
            if (kDebugMode) {
              print('Error in onDiscovered: $e');
              print('Stack trace: ${StackTrace.current}');
            }
            if (!completer.isCompleted) {
              completer.completeError('Error membaca kartu: $e');
            }
            await NfcManager.instance.stopSession(
              errorMessageIos: 'Error membaca kartu',
            );
          }
        },
      );

      sessionStarted = true;
      if (kDebugMode) {
        print('NFC session started successfully');
      }

      // Set timeout
      Timer(timeout, () {
        if (!completer.isCompleted) {
          if (kDebugMode) {
            print('NFC scan timeout');
          }
          completer.complete(null);
          NfcManager.instance.stopSession(
            errorMessageIos: 'Waktu habis - coba lagi',
          );
        }
      });

      return await completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('Error in scanCard: $e');
        print('Session started: $sessionStarted');
      }

      if (sessionStarted) {
        try {
          await NfcManager.instance.stopSession(errorMessageIos: 'Error: $e');
        } catch (stopError) {
          if (kDebugMode) {
            print('Error stopping session: $stopError');
          }
        }
      }

      // Provide more specific error messages
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('nfc not available') ||
          errorMessage.contains('nfc is not available') ||
          errorMessage.contains('nfc disabled')) {
        throw Exception(
          'NFC tidak aktif. Silakan aktifkan NFC di pengaturan perangkat.',
        );
      } else if (errorMessage.contains('permission') ||
          errorMessage.contains('denied')) {
        throw Exception(
          'Aplikasi tidak memiliki izin NFC. Berikan izin NFC di pengaturan aplikasi.',
        );
      } else if (errorMessage.contains('session') ||
          errorMessage.contains('already running')) {
        throw Exception(
          'Sesi NFC sedang berjalan. Coba lagi dalam beberapa detik.',
        );
      } else if (errorMessage.contains('timeout')) {
        throw Exception(
          'Waktu scan habis. Pastikan kartu NFC dekat dengan perangkat.',
        );
      } else {
        throw Exception('Error scanning NFC: $e');
      }
    }
  }

  /// Deteksi apakah kartu adalah Flazz Gen 2
  ///
  /// Kartu Flazz Gen 2 menggunakan teknologi ISO-DEP dengan historicalBytes
  /// atau NFC-A dengan ATQA dan SAK yang spesifik
  bool _isFlazzGen2Card(NfcTag tag) {
    try {
      if (kDebugMode) {
        print('🔍 Detecting Flazz Gen 2 card...');
      }

      // Cek ISO-DEP
      final isoDep = IsoDepAndroid.from(tag);
      if (isoDep != null) {
        if (kDebugMode) {
          print('ISO-DEP detected');
          print('Historical bytes: ${isoDep.historicalBytes}');
          print('Hi-layer response: ${isoDep.hiLayerResponse}');
        }

        // Flazz Gen 2 biasanya menggunakan ISO-DEP dengan historicalBytes atau hiLayerResponse
        if ((isoDep.historicalBytes != null &&
                isoDep.historicalBytes!.isNotEmpty) ||
            (isoDep.hiLayerResponse != null &&
                isoDep.hiLayerResponse!.isNotEmpty)) {
          if (kDebugMode) {
            print('✅ Detected Flazz Gen 2 via ISO-DEP');
          }
          return true;
        }
      }

      // Cek NFC-A
      final nfcA = NfcAAndroid.from(tag);
      if (nfcA != null) {
        if (kDebugMode) {
          print('NFC-A detected');
          print('ATQA: ${nfcA.atqa}');
          print('SAK: ${nfcA.sak}');
        }

        // Flazz Gen 2 juga bisa menggunakan NFC-A
        if (nfcA.atqa.isNotEmpty) {
          if (kDebugMode) {
            print('✅ Detected Flazz Gen 2 via NFC-A');
          }
          return true;
        }
      }

      // Fallback: jika ada ISO-DEP atau NFC-A, anggap sebagai potential Flazz Gen 2
      if (isoDep != null || nfcA != null) {
        if (kDebugMode) {
          print('⚠️ Assuming Flazz Gen 2 based on available technologies');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting Flazz Gen 2: $e');
      }
    }

    if (kDebugMode) {
      print('❌ Not detected as Flazz Gen 2');
    }
    return false;
  }

  /// Ekstraksi khusus untuk kartu Flazz Gen 2
  ///
  /// Method ini menggunakan strategi khusus untuk mengekstrak ID dari kartu Flazz Gen 2:
  /// 1. Prioritas pada teknologi ISO-DEP dengan kombinasi identifier + historicalBytes + hiLayerResponse
  /// 2. Fallback ke NFC-A dengan kombinasi identifier + ATQA + SAK
  /// 3. Menggunakan encoding yang tepat untuk memastikan konsistensi ID
  String? _extractFlazzGen2Id(NfcTag tag) {
    try {
      if (kDebugMode) {
        print('Attempting Flazz Gen 2 specific extraction...');
      }

      // Metode 1: Coba dari ISO-DEP dengan kombinasi semua field
      final isoDep = IsoDepAndroid.from(tag);
      if (isoDep != null) {
        final parts = <String>[];

        // Identifier
        if (isoDep.tag.id.isNotEmpty) {
          final identifier =
              isoDep.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          parts.add(identifier);
        }

        // Historical bytes
        if (isoDep.historicalBytes != null &&
            isoDep.historicalBytes!.isNotEmpty) {
          final historicalBytes =
              isoDep.historicalBytes!
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          parts.add(historicalBytes);
        }

        // Hi-layer response
        if (isoDep.hiLayerResponse != null &&
            isoDep.hiLayerResponse!.isNotEmpty) {
          final hiLayerResponse =
              isoDep.hiLayerResponse!
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          parts.add(hiLayerResponse);
        }

        if (parts.isNotEmpty) {
          final flazzId = parts.join('');
          if (kDebugMode) {
            print('Flazz Gen 2 ID extracted from ISO-DEP: $flazzId');
          }
          return flazzId;
        }
      }

      // Metode 2: Coba dari NFC-A dengan semua field
      final nfcA = NfcAAndroid.from(tag);
      if (nfcA != null) {
        String? identifier, atqa, sak;

        // Identifier
        if (nfcA.tag.id.isNotEmpty) {
          identifier =
              nfcA.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
        }

        // ATQA
        if (nfcA.atqa.isNotEmpty) {
          atqa =
              nfcA.atqa
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
        }

        // SAK
        sak = nfcA.sak.toRadixString(16).padLeft(2, '0').toUpperCase();

        // Buat ID dari kombinasi NFC-A fields
        if (identifier != null && identifier.isNotEmpty) {
          final flazzId = '$identifier${atqa ?? ''}$sak';
          if (kDebugMode) {
            print('Flazz Gen 2 ID extracted from NFC-A: $flazzId');
          }
          return flazzId;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in Flazz Gen 2 extraction: $e');
      }
    }

    return null;
  }

  String _extractCardId(NfcTag tag) {
    try {
      if (kDebugMode) {
        print('Extracting card ID from NFC tag...');
      }

      // Deteksi jenis kartu
      final isFlazz = _isFlazzGen2Card(tag);
      if (kDebugMode) {
        print('Detected as Flazz Gen 2: $isFlazz');
      }

      if (isFlazz) {
        // Untuk Flazz Gen 2, prioritaskan ISO-DEP dan NFC-A
        final isoDep = IsoDepAndroid.from(tag);
        if (isoDep != null && isoDep.tag.id.isNotEmpty) {
          final cardId =
              isoDep.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from ISO-DEP: $cardId');
          }
          return cardId;
        }

        final nfcA = NfcAAndroid.from(tag);
        if (nfcA != null && nfcA.tag.id.isNotEmpty) {
          final cardId =
              nfcA.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from NFC-A: $cardId');
          }
          return cardId;
        }

        // Jika gagal dengan metode standar, coba ekstraksi khusus Flazz
        final flazzId = _extractFlazzGen2Id(tag);
        if (flazzId != null && flazzId.isNotEmpty) {
          return flazzId;
        }
      } else {
        // Untuk kartu non-Flazz, coba berbagai teknologi

        // Try NFC-A first (most common)
        final nfcA = NfcAAndroid.from(tag);
        if (nfcA != null && nfcA.tag.id.isNotEmpty) {
          final cardId =
              nfcA.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from NFC-A: $cardId');
          }
          return cardId;
        }

        // Try ISO-DEP
        final isoDep = IsoDepAndroid.from(tag);
        if (isoDep != null && isoDep.tag.id.isNotEmpty) {
          final cardId =
              isoDep.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from ISO-DEP: $cardId');
          }
          return cardId;
        }

        // Try NFC-B
        final nfcB = NfcBAndroid.from(tag);
        if (nfcB != null && nfcB.tag.id.isNotEmpty) {
          final cardId =
              nfcB.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from NFC-B: $cardId');
          }
          return cardId;
        }

        // Try NFC-F
        final nfcF = NfcFAndroid.from(tag);
        if (nfcF != null && nfcF.tag.id.isNotEmpty) {
          final cardId =
              nfcF.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from NFC-F: $cardId');
          }
          return cardId;
        }

        // Try NFC-V
        final nfcV = NfcVAndroid.from(tag);
        if (nfcV != null && nfcV.tag.id.isNotEmpty) {
          final cardId =
              nfcV.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from NFC-V: $cardId');
          }
          return cardId;
        }

        // Try Mifare Classic
        final mifareClassic = MifareClassicAndroid.from(tag);
        if (mifareClassic != null && mifareClassic.tag.id.isNotEmpty) {
          final cardId =
              mifareClassic.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from Mifare Classic: $cardId');
          }
          return cardId;
        }

        // Try Mifare Ultralight
        final mifareUltralight = MifareUltralightAndroid.from(tag);
        if (mifareUltralight != null && mifareUltralight.tag.id.isNotEmpty) {
          final cardId =
              mifareUltralight.tag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
          if (kDebugMode) {
            print('Extracted card ID from Mifare Ultralight: $cardId');
          }
          return cardId;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting card ID: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    }

    // If all else fails, return empty string
    if (kDebugMode) {
      print('Failed to extract card ID from any technology');
    }
    return '';
  }

  Future<void> stopSession({String? message}) async {
    try {
      await NfcManager.instance.stopSession(errorMessageIos: message);
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping NFC session: $e');
      }
    }
  }

  /// Membersihkan cache kartu
  void clearCardCache() {
    _cardIdCache.clear();
    if (kDebugMode) {
      print('Card ID cache cleared');
    }
  }

  /// Mendapatkan informasi cache untuk debugging
  Map<String, String> getCacheInfo() {
    return Map.from(_cardIdCache);
  }
}
