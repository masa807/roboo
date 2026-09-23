import 'package:dio/dio.dart';

/// استثناء موحّد لأي خطأ راجع من الـ API، منرميه من الـ Repositories
/// ومنمسكه بالـ Cubit/Bloc لعرض رسالة واضحة بالواجهة.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// نقطة وحيدة للتعامل مع الباك اند. عدّل [baseUrl] لعنوان السيرفر الحقيقي.
/// [tokenProvider] دالة بترجع التوكن الحالي (من مكان تخزين التوكن) لإضافته
/// بالـ Authorization header تلقائياً بكل طلب.
class ApiClient {
  ApiClient({
    required String baseUrl,
    Future<String?> Function()? tokenProvider,
  }) : _tokenProvider = tokenProvider,
       dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           headers: {'Content-Type': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_tokenProvider != null) {
            final token = await _tokenProvider();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final Future<String?> Function()? _tokenProvider;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _wrap(() => dio.get(path, queryParameters: queryParameters));

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _wrap(() => dio.post(path, data: data, queryParameters: queryParameters));

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
      throw ApiException(_messageFrom(e), statusCode: e.response?.statusCode);
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is Map && data['title'] is String) {
      // شكل أخطاء الـ ValidationProblemDetails تبع ASP.NET Core
      return data['title'] as String;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الاتصال بالسيرفر';
      case DioExceptionType.connectionError:
        return 'ما في اتصال بالسيرفر، تأكد من الإنترنت';
      default:
        return e.message ?? 'صار في خطأ غير متوقع';
    }
  }
}
