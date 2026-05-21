import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:schemantic/schemantic.dart';
import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

final getWeather = ai.defineTool<Map<String, dynamic>, String>(
  name: 'getWeather',
  description: 'Fetch current and tomorrow\'s weather report for a 6-digit Indian PIN code.',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'pincode': {
          'type': 'string',
          'description': 'The 6-digit Indian PIN code (e.g., 781313)',
        },
      },
      'required': ['pincode'],
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final pincode = input['pincode'];
      // 1. PIN to Coordinates
      final geoUrl = Uri.parse('https://api.postalpincode.in/pincode/$pincode');
      final geoRes = await http.get(geoUrl);
      if (geoRes.statusCode != 200) return 'Error: Could not resolve PIN code.';
      
      final geoData = jsonDecode(geoRes.body) as List;
      if (geoData.isEmpty || geoData[0]['Status'] != 'Success') return 'Error: Invalid PIN code.';
      
      final postOffice = geoData[0]['PostOffice'][0];
      final locationName = postOffice['Name'];
      final district = postOffice['District'];
      final state = postOffice['State'];

      final searchUrl = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$locationName&count=1&language=en&format=json');
      final searchRes = await http.get(searchUrl);
      final searchData = jsonDecode(searchRes.body);
      
      double lat, lon;
      if (searchData['results'] != null && (searchData['results'] as List).isNotEmpty) {
        lat = searchData['results'][0]['latitude'];
        lon = searchData['results'][0]['longitude'];
      } else {
        final districtSearchUrl = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$district&count=1&language=en&format=json');
        final dRes = await http.get(districtSearchUrl);
        final dData = jsonDecode(dRes.body);
        if (dData['results'] != null && (dData['results'] as List).isNotEmpty) {
          lat = dData['results'][0]['latitude'];
          lon = dData['results'][0]['longitude'];
        } else {
          return 'Error: Could not find geographic coordinates for $locationName, $district.';
        }
      }

      final weatherUrl = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,rain_sum,showers_sum,snowfall_sum&timezone=auto&forecast_days=2');
      final weatherRes = await http.get(weatherUrl);
      final w = jsonDecode(weatherRes.body);

      final currentTemp = w['current']['temperature_2m'];
      final currentApparent = w['current']['apparent_temperature'];
      final currentWind = w['current']['wind_speed_10m'];
      
      final todayMax = w['daily']['temperature_2m_max'][0];
      final todayMin = w['daily']['temperature_2m_min'][0];
      
      final tomorrowMax = w['daily']['temperature_2m_max'][1];
      final tomorrowMin = w['daily']['temperature_2m_min'][1];
      final tomorrowCode = w['daily']['weather_code'][1];

      return '''📍 Weather for $locationName ($district, $state):

🌡 Temperature outside: $currentTemp°C (Feels like $currentApparent°C)
💨 Wind Speed: $currentWind km/h

📅 Today's Forecast:
High: $todayMax°C | Low: $todayMin°C

📅 Tomorrow's Forecast:
High: $tomorrowMax°C | Low: $tomorrowMin°C
Expect ${tomorrowCode > 50 ? 'rain/showers' : 'clear skies'}.''';

    } catch (e) {
      return 'Error fetching weather: $e';
    }
  },
);

final setReminder = ai.defineTool<Map<String, dynamic>, String>(
  name: 'setReminder',
  description: 'Schedule a reminder message for the shop owner. Use ISO format for scheduledAt.',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'reminderText': {
          'type': 'string',
          'description': 'What to remind the user about',
        },
        'scheduledAt': {
          'type': 'string',
          'description': 'ISO 8601 timestamp (UTC) for the reminder (e.g., 2026-04-26T17:00:00Z)',
        },
        'headsUp': {
          'type': 'boolean',
          'description': 'If true, the user will be reminded 25 minutes earlier than scheduledAt',
        },
      },
      'required': ['reminderText', 'scheduledAt'],
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      final chatId = int.parse(userIdentifier);
      
      var scheduledAt = DateTime.parse(input['scheduledAt'] as String);
      final bool headsUp = input['headsUp'] as bool? ?? false;
      
      if (headsUp) {
        scheduledAt = scheduledAt.subtract(const Duration(minutes: 25));
      }

      await supabase.from('reminders').insert({
        'chat_id': chatId,
        'shop_id': shopId,
        'reminder_text': input['reminderText'],
        'scheduled_at': scheduledAt.toIso8601String(),
        'heads_up': headsUp,
        'status': 'PENDING',
      });

      final timeStr = headsUp 
          ? 'at ${scheduledAt.toLocal().toString().substring(11, 16)} (including 25 min heads-up)' 
          : 'at ${scheduledAt.toLocal().toString().substring(11, 16)}';
          
      return '✅ Reminder set: "${input['reminderText']}" $timeStr.';
    } catch (e) {
      return 'Error setting reminder: $e';
    }
  },
);
