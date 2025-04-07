abstract class IRepository<T> {
  Future<List<T>> getAll();

  Future<T?> getById(String anyId);

  Future<String> add(T item);

  Future<void> update(String id, T item);

  Future<void> delete(String id);

}