import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_model.freezed.dart';

@freezed
sealed class ProxyConfig with _$ProxyConfig {
  const factory ProxyConfig.vless({
    required String id,
    required String name,
    required String server,
    required int port,
    required String uuid,
    String? flow,
    String? security,
    String? sni,
    String? fingerprint,
    String? publicKey,
    String? shortId,
    String? type,
    String? host,
    String? path,
    Map<String, dynamic>? extra,
  }) = VlessConfig;

  const factory ProxyConfig.vmess({
    required String id,
    required String name,
    required String server,
    required int port,
    required String uuid,
    String? security,
    String? type,
    String? host,
    String? path,
  }) = VmessConfig;

  const factory ProxyConfig.trojan({
    required String id,
    required String name,
    required String server,
    required int port,
    required String password,
    String? sni,
    String? fingerprint,
    String? type,
    String? host,
    String? path,
  }) = TrojanConfig;

  const factory ProxyConfig.shadowsocks({
    required String id,
    required String name,
    required String server,
    required int port,
    required String cipher,
    required String password,
    String? plugin,
  }) = ShadowsocksConfig;

  const factory ProxyConfig.hysteria2({
    required String id,
    required String name,
    required String server,
    required int port,
    required String password,
    String? sni,
    String? alpn,
    bool? insecure,
  }) = Hysteria2Config;
}

extension ProxyConfigX on ProxyConfig {
  String get scheme {
    return map(
      vless: (_) => 'vless',
      vmess: (_) => 'vmess',
      trojan: (_) => 'trojan',
      shadowsocks: (_) => 'ss',
      hysteria2: (_) => 'hysteria2',
    );
  }

  String get displayName => map(
    vless: (c) => c.name,
    vmess: (c) => c.name,
    trojan: (c) => c.name,
    shadowsocks: (c) => c.name,
    hysteria2: (c) => c.name,
  );

  String get server => map(
    vless: (c) => c.server,
    vmess: (c) => c.server,
    trojan: (c) => c.server,
    shadowsocks: (c) => c.server,
    hysteria2: (c) => c.server,
  );

  int get port => map(
    vless: (c) => c.port,
    vmess: (c) => c.port,
    trojan: (c) => c.port,
    shadowsocks: (c) => c.port,
    hysteria2: (c) => c.port,
  );
}