import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    Future<String?> Function()? tokenProvider,
  }) : _tokenProvider = tokenProvider,
       dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
           sendTimeout: const Duration(seconds: 20),
           listFormat: ListFormat.multi,
           headers: {'Content-Type': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['anonymous'] == true) {
            handler.next(options);
            return;
          }
          final version = sessionVersion;
          try {
            final token = await _tokenProvider?.call();
            if (version != sessionVersion || token == null || token.isEmpty) {
              throw const ApiException(
                'انتهت الجلسة، يرجى تسجيل الدخول.',
                statusCode: 401,
              );
            }
            options.extra['sessionVersion'] = version;
            options.headers['Authorization'] = 'Bearer $token';
            handler.next(options);
          } catch (error) {
            handler.reject(DioException(requestOptions: options, error: error));
          }
        },
        onResponse: (response, handler) {
          if (response.requestOptions.extra['anonymous'] != true &&
              response.requestOptions.extra['sessionVersion'] !=
                  sessionVersion) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: const ApiException('تم تغيير الجلسة.'),
              ),
            );
          } else {
            handler.next(response);
          }
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['anonymous'] == true ||
              request.extra['sessionVersion'] != sessionVersion) {
            handler.next(error);
            return;
          }
          if (request.extra['retried'] == true) {
            await onSessionExpired?.call();
            handler.next(error);
            return;
          }
          try {
            final token = await refreshSession?.call(
              request.headers['Authorization']?.toString(),
            );
            if (token == null ||
                request.extra['sessionVersion'] != sessionVersion) {
              handler.next(error);
              return;
            }
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $token';
            handler.resolve(await dio.fetch<dynamic>(request));
          } on DioException catch (retryError) {
            handler.next(retryError);
          } catch (e) {
            handler.reject(DioException(requestOptions: request, error: e));
          }
        },
      ),
    );
  }

  final Dio dio;
  int sessionVersion = 0;
  Future<String?> Function()? _tokenProvider;
  Future<String?> Function(String? sentAuthorization)? refreshSession;
  Future<void> Function()? onSessionExpired;
  void setTokenProvider(Future<String?> Function() provider) =>
      _tokenProvider = provider;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _wrap(() => dio.get(path, queryParameters: queryParameters));
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool anonymous = false,
  }) => _wrap(
    () => dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(extra: {'anonymous': anonymous}),
    ),
  );
  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _wrap(() => dio.put(path, data: data));
  Future<Response<dynamic>> delete(String path) =>
      _wrap(() => dio.delete(path));
  Future<Response<dynamic>> _wrap(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      // للتشخيص فقط، احذفه لاحقاً
      debugPrint('API ERROR type=${e.type}');
      debugPrint('API ERROR uri=${e.requestOptions.uri}');
      debugPrint('API ERROR status=${e.response?.statusCode}');
      debugPrint('API ERROR body=${e.response?.data}');
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(_messageFrom(e), statusCode: e.response?.statusCode);
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        final text = errors.values.expand((v) => v is List ? v : [v]).join(' ');
        if (text.isNotEmpty) return text;
      }
      for (final key in ['detail', 'message']) {
        if (data[key] is String && (data[key] as String).isNotEmpty) {
          return data[key] as String;
        }
      }
    }
    if (e.response?.statusCode == 401) {
      return 'انتهت الجلسة، يرجى تسجيل الدخول.';
    }
    if (e.response?.statusCode == 429) return 'طلبات كثيرة، حاول بعد قليل.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'انتهت مهلة الاتصال، تحقق من النتيجة قبل إعادة المحاولة.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'تعذر الاتصال بالسيرفر، تأكد من الاتصال.';
    }
    return 'تعذر إتمام الطلب. حاول مجددًا.';
  }
}
