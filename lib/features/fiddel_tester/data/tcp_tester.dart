import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/features/fiddel_tester/model/config_model.dart';
import 'package:fiddel/features/fiddel_tester/model/test_result.dart';
import 'package:fiddel/features/fiddel_tester/model/subscription.dart';
import 'package:meta/meta.dart';

class TcpTester {
  static Future<int> testTcp(String host, int port, {int tries = 5, Duration timeout = const Duration(seconds: 5)}) async {
    int success = 0;
    
    for (int i = 0; i < tries; i++) {
      try {
        final socket = await Socket.connect(host, port, timeout: timeout).timeout(timeout);
        socket.destroy();
        success++;
      } catch (_) {}
      
      // Small delay between tries
      if (i < tries - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return success;
  }

  static Future<Iterable<ProxyConfig>> filterByTcp({
    required Iterable<ProxyConfig> configs,
    required int minSuccess,
    required int tries,
    int concurrency = 100,
  }) async {
    final semaphore = Semaphore(concurrency);
    final results = <ProxyConfig, int>{};
    
    await Future.wait(configs.map((config) async {
      await semaphore.acquire();
      try {
        final success = await testTcp(config.server, config.port, tries: tries);
        results[config] = success;
      } finally {
        semaphore.release();
      }
    }));
    
    return configs.where((c) => (results[c] ?? 0) >= minSuccess);
  }
}

class Semaphore {
  final int _max;
  int _current = 0;
  final _waiters = <Completer<void>>[];

  Semaphore(this._max);

  Future<void> acquire() async {
    if (_current < _max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _current--;
    }
  }
}