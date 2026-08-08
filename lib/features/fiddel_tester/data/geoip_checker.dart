import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fiddel/features/fiddel_tester/model/test_result.dart';
import 'package:meta/meta.dart';

class GeoIpChecker {
  static const _providers = [
    'https://ipinfo.io/json',
    'https://ip-api.com/json/',
    'https://ipapi.co/json/',
  ];

  final Dio _dio;
  final Duration _timeout;
  final Map<String, String> _cache = {};

  GeoIpChecker({
    Dio? dio,
    Duration timeout = const Duration(seconds: 10),
  }) : _dio = dio ?? Dio(),
       _timeout = timeout {
    _dio.options.connectTimeout = timeout;
    _dio.options.receiveTimeout = timeout;
  }

  Future<String?> getCountry(String socksProxy) async {
    if (_cache.containsKey(socksProxy)) {
      return _cache[socksProxy];
    }

    for (final provider in _providers) {
      try {
        final proxyDio = Dio(BaseOptions(
          connectTimeout: _timeout,
          receiveTimeout: _timeout,
        ));
        proxyDio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => HttpClient()
            ..findProxy = ((_) => 'PROXY $socksProxy')
            ..badCertificateCallback = ((_, __, ___) => true),
        );

        final response = await proxyDio.get(provider);
        if (response.statusCode == 200 && response.data is Map) {
          final country = _parseCountry(response.data as Map);
          if (country != null) {
            _cache[socksProxy] = country;
            return country;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  String? _parseCountry(Map data) {
    // ipinfo.io
    if (data['country'] is String && (data['country'] as String).length == 2) {
      return (data['country'] as String).toUpperCase();
    }
    // ip-api.com
    if (data['countryCode'] is String && (data['countryCode'] as String).length == 2 && data['status'] == 'success') {
      return (data['countryCode'] as String).toUpperCase();
    }
    // ipapi.co
    if (data['country_code'] is String && (data['country_code'] as String).length == 2) {
      return (data['country_code'] as String).toUpperCase();
    }
    if (data['country'] is String && (data['country'] as String).length == 2) {
      return (data['country'] as String).toUpperCase();
    }
    return null;
  }

  static const Map<String, (String, String)> _countryInfo = {
    'US': ('United States', '🇺🇸'),
    'DE': ('Germany', '🇩🇪'),
    'FI': ('Finland', '🇫🇮'),
    'NL': ('Netherlands', '🇳🇱'),
    'GB': ('United Kingdom', '🇬🇧'),
    'TR': ('Turkey', '🇹🇷'),
    'FR': ('France', '🇫🇷'),
    'JP': ('Japan', '🇯🇵'),
    'SG': ('Singapore', '🇸🇬'),
    'HK': ('Hong Kong', '🇭🇰'),
    'CA': ('Canada', '🇨🇦'),
    'AU': ('Australia', '🇦🇺'),
    'CH': ('Switzerland', '🇨🇭'),
    'SE': ('Sweden', '🇸🇪'),
    'NO': ('Norway', '🇳🇴'),
    'DK': ('Denmark', '🇩🇰'),
    'IE': ('Ireland', '🇮🇪'),
    'AT': ('Austria', '🇦🇹'),
    'BE': ('Belgium', '🇧🇪'),
    'PL': ('Poland', '🇵🇱'),
    'CZ': ('Czechia', '🇨🇿'),
    'RO': ('Romania', '🇷🇴'),
    'BG': ('Bulgaria', '🇧🇬'),
    'HR': ('Croatia', '🇭🇷'),
    'RS': ('Serbia', '🇷🇸'),
    'SK': ('Slovakia', '🇸🇰'),
    'SI': ('Slovenia', '🇸🇮'),
    'LT': ('Lithuania', '🇱🇹'),
    'LV': ('Latvia', '🇱🇻'),
    'EE': ('Estonia', '🇪🇪'),
    'RU': ('Russia', '🇷🇺'),
    'CN': ('China', '🇨🇳'),
    'KR': ('South Korea', '🇰🇷'),
    'TW': ('Taiwan', '🇹🇼'),
    'IN': ('India', '🇮🇳'),
    'BR': ('Brazil', '🇧🇷'),
    'MX': ('Mexico', '🇲🇽'),
    'AR': ('Argentina', '🇦🇷'),
    'ZA': ('South Africa', '🇿🇦'),
    'AE': ('UAE', '🇦🇪'),
    'IL': ('Israel', '🇮🇱'),
  };

  static (String, String) getCountryInfo(String code) {
    return _countryInfo[code.toUpperCase()] ?? (code.toUpperCase(), '');
  }

  void clearCache() => _cache.clear();
}