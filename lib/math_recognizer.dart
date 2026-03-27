import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MathRecognizer {
  static const _apiKeyEnv = 'VOLC_API_KEY';
  static const _modelIdEnv = 'VOLC_MODEL_ID';
  static const _baseUrlEnv = 'VOLC_BASE_URL';
  static const _defaultBaseUrl =
      'https://ark.cn-beijing.volces.com/api/v3/chat/completions';

  static bool _dotenvLoaded = false;

  Future<void> _ensureEnvLoaded() async {
    if (_dotenvLoaded) return;
    await dotenv.load(fileName: '.env');
    _dotenvLoaded = true;
  }

  Future<String?> recognizeFromImage(XFile imageFile) async {
    try {
      await _ensureEnvLoaded();

      final apiKey = (dotenv.env[_apiKeyEnv] ?? '').trim();
      final modelId = (dotenv.env[_modelIdEnv] ?? '').trim();
      final baseUrl = (dotenv.env[_baseUrlEnv] ?? _defaultBaseUrl).trim();

      if (apiKey.isEmpty || modelId.isEmpty) {
        return 'Missing env config: VOLC_API_KEY / VOLC_MODEL_ID';
      }

      // 读取图片并转为 Base64
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 发起 HTTP 请求
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": modelId,
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                      "你是一个数学专家。请直接提取图片中的数学公式并转化为标准的 LaTeX 代码。不要解释，不要说‘好的’，只返回代码本身。",
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String result = data['choices'][0]['message']['content'];

        // --- 关键修复代码开始 ---
        // 1. 去掉 Markdown 的代码块标记
        result = result.replaceAll('```latex', '').replaceAll('```', '');
        // 2. 去掉 \( 和 \) 符号
        result = result.replaceAll('\\(', '').replaceAll('\\)', '');
        // 3. 去掉 $ 符号
        result = result.replaceAll('\$', '');
        // 4. 去除首尾多余空格
        result = result.trim();
        // --- 关键修复代码结束 ---

        return result;
      } else {
        final errorDetail = utf8.decode(response.bodyBytes);
        debugPrint('Volc API error: $errorDetail');
        return "接口报错: $errorDetail";
      }
    } catch (e) {
      debugPrint('识别错误: $e');
      return "识别出错: $e";
    }
  }
}
