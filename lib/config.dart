// lib/config.dart

// Base API URL (for REST endpoints)
const String baseUrlx = "https://paronymic-noncontumaciously-clarence.ngrok-free.dev";

// Helper to get WebSocket URL from base
String getWsUrl(String path) {
  return baseUrlx.replaceFirst("https", "wss") + path;
}
