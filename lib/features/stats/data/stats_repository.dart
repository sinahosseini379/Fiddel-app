import 'package:fpdart/fpdart.dart';
import 'package:fiddel/core/utils/exception_handler.dart';
import 'package:fiddel/features/stats/model/stats_failure.dart';
import 'package:fiddel/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:fiddel/hiddifycore/hiddify_core_service.dart';
import 'package:fiddel/utils/custom_loggers.dart';

abstract interface class StatsRepository {
  Stream<Either<StatsFailure, SystemInfo>> watchStats();
}

class StatsRepositoryImpl with ExceptionHandler, InfraLogger implements StatsRepository {
  StatsRepositoryImpl({required this.singbox});

  final HiddifyCoreService singbox;

  @override
  Stream<Either<StatsFailure, SystemInfo>> watchStats() {
    return singbox.watchStats().handleExceptions(StatsUnexpectedFailure.new);
  }
}
