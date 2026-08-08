import 'package:dio/dio.dart';
import 'package:fiddel/core/http_client/dio_http_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fiddel/core/http_client/http_client_provider.dart';

final geoIpProvider = Provider<GeoIpService>((ref) {
  return GeoIpService(ref.read(httpClientProvider));
});

class GeoIpService {
  static const List<String> _providers = [
    'https://ipinfo.io/json',
    'https://ip-api.com/json/',
    'https://ipapi.co/json/',
  ];
  
  final DioHttpClient _httpClient;
  final Map<String, String> _cache = {};
  
  GeoIpService(this._httpClient);
  
  Future<String?> getCountry({CancelToken? cancelToken}) async {
    // First try to get exit IP for caching
    String? exitIp;
    try {
      final ipResp = await _httpClient.get(
        'https://api.ipify.org',
        cancelToken: cancelToken,
      );
      exitIp = ipResp.data.toString().trim();
      if (_cache.containsKey(exitIp)) return _cache[exitIp]!;
    } catch (_) {}
    
    for (final url in _providers) {
      try {
        final resp = await _httpClient.get(
          url,
          cancelToken: cancelToken,
        );
        
        if (resp.statusCode == 200 && resp.data is Map) {
          final data = resp.data as Map;
          String? cc;
          
          if (url.contains('ipinfo')) {
            cc = data['country']?.toString();
          } else if (url.contains('ip-api')) {
            if (data['status'] == 'success') cc = data['countryCode']?.toString();
          } else if (url.contains('ipapi')) {
            cc = data['country_code']?.toString() ?? data['country']?.toString();
          }
          
          if (cc != null && cc.length == 2) {
            final country = cc.toUpperCase();
            if (exitIp != null) _cache[exitIp] = country;
            return country;
          }
        }
      } catch (_) {}
    }
    
    return null;
  }
}