
class AirQualityModel {
  final DateTime? time;
  final double? pm25Filtered;
  final double? no2Ugm3;
  final double? suhuCompensated;
  final double? kelembabanCompensated;
  final double? tvocugm3;
  final int? mlpredictionCode;
  final double? mlConfidence;
  final String? irritationRiskStatus;
  final double? irritationRiskScore;
  final double? latitude;
  final double? longitude;

  AirQualityModel({
    this.time,
    this.pm25Filtered,
    this.no2Ugm3,
    this.suhuCompensated,
    this.kelembabanCompensated,
    this.tvocugm3,
    this.mlpredictionCode,
    this.mlConfidence,
    this.irritationRiskStatus,
    this.irritationRiskScore,
    this.latitude,  
    this.longitude,
  });

  // Factory constructor untuk mengubah Map JSON menjadi Objek Dart
  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    return AirQualityModel(
      time: json['time'] != null ? DateTime.parse(json['time']).toLocal() : null,
      pm25Filtered: json['pm25_filtered']?.toDouble(),
      no2Ugm3: json['no2_ugm3']?.toDouble(),
      suhuCompensated: json['suhu_compensated']?.toDouble(),
      kelembabanCompensated: json['kelembaban_compensated']?.toDouble(),
      tvocugm3: json['tvoc_ugm3']?.toDouble(),
      mlpredictionCode: json['ml_prediction_code'] != null ? int.parse(json['ml_prediction_code'].toString()) : null,
      mlConfidence: json['ml_confidence']?.toDouble(),
      irritationRiskStatus: json['irritation_risk_status'],
      irritationRiskScore: json['irritation_risk_score']?.toDouble(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // Method untuk mengubah Objek Dart kembali ke Map JSON (jika diperlukan)
  Map<String, dynamic> toJson() {
    return {
      'time': time?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'suhu_compensated': suhuCompensated,
      'kelembaban_compensated': kelembabanCompensated,
      'pm25_filtered': pm25Filtered,
      'tvoc_ugm3': tvocugm3,
      'no2_ugm3': no2Ugm3,
      'ml_prediction_code': mlpredictionCode,
      'ml_confidence': mlConfidence,
      'irritation_risk_status': irritationRiskStatus,
      'irritation_risk_score' : irritationRiskScore,
    };
  }
}