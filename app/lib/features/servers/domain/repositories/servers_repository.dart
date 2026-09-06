import '../entities/server_item.dart';

/// Контракт управления серверами и переключения узлов.
abstract interface class ServersRepository {
  /// Получает список серверов из активного профиля подписки.
  Future<List<ServerModel>> getServers();

  /// Замеряет задержки для всех доступных узлов.
  Future<List<ServerModel>> pingAllServers(List<ServerModel> servers);

  /// Переключает активный outbound (через Clash API или обновление конфига).
  Future<bool> switchServer(String tag);

  /// Сохраняет последний выбранный сервер в кэш.
  Future<void> saveSelectedTag(String tag);

  /// Получает сохранённый тег сервера.
  Future<String?> getSelectedTag();
}
