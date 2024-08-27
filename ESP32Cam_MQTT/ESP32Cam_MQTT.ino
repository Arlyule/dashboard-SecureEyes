#include "esp_camera.h"
#include <WiFi.h>
#include <MQTT.h>
#include <ArduinoJson.h>  // Asegúrate de tener esta librería instalada

#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

#define ESP32CAM_PUBLISH_TOPIC "sistema_segureye_esp2/cam_0"
#define LED_STATUS_TOPIC "sistema_segureye_esp2/led_status"
const int bufferSize = 1024 * 23;

const char ssid[] = "HUAWEI nova 3 A4E7";
const char pass[] = "hola12345";

WiFiClient net;
MQTTClient client = MQTTClient(bufferSize);

const int ledPin = 4;
bool playingVideo = false;

void connect() {
  WiFi.begin(ssid, pass);

  Serial.println("\n\n=====================");
  Serial.println("Connecting to Wi-Fi");
  Serial.println("=====================\n\n");

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(100);
  }

  Serial.println("\n\n=====================");
  Serial.println("WIFI Connected!!");
  Serial.println("=====================\n\n");

  // Cambiando la conexión MQTT a broker.hivemq.com en el puerto 1883
  client.begin("broker.hivemq.com", 1883, net);
  client.onMessage(messageReceived);

  Serial.println("\n\n=====================");
  Serial.println("Connecting to MQTT Broker");
  Serial.println("=====================\n\n");

  while (!client.connect("ESP32CAM")) {
    Serial.print(".");
    delay(100);
  }

  if (!client.connected()) {
    Serial.println("MQTT Broker Timeout!");
    ESP.restart();
    return;
  }

  Serial.println("\n\n=====================");
  Serial.println("MQTT Broker Connected!");
  Serial.println("=====================\n\n");

  client.subscribe("sistema_segureye_esp2/led");
  client.subscribe("sistema_segureye_esp2/video");
}

void messageReceived(String &topic, String &payload) {
  Serial.print("Message received on topic: ");
  Serial.print(topic);
  Serial.print(". Message: ");
  Serial.println(payload);

  // Parsear el JSON del payload
  DynamicJsonDocument doc(1024);  // Tamaño del buffer para JSON
  DeserializationError error = deserializeJson(doc, payload);

  if (error) {
    Serial.print("Failed to parse JSON: ");
    Serial.println(error.c_str());
    return;
  }

  // Obtener el valor del campo "msg"
  String msg = doc["msg"].as<String>();

  if (String(topic) == "sistema_segureye_esp2/led") {
    if (msg == "on") {
      Serial.println("Led on");
      digitalWrite(ledPin, HIGH);
      publishLedStatus("on");  // Publicar el estado del LED
    } else if (msg == "off") {
      Serial.println("Led off");
      digitalWrite(ledPin, LOW);
      publishLedStatus("off");  // Publicar el estado del LED
    }
  }

  if (String(topic) == "sistema_segureye_esp2/video") {
    if (msg == "on") {
      Serial.println("Video on");
      playingVideo = true;
    } else if (msg == "off") {
      Serial.println("Video off");
      playingVideo = false;
    }
  }
}

void publishLedStatus(const char* status) {
  DynamicJsonDocument doc(512);
  doc["led"] = status;

  String jsonString;
  serializeJson(doc, jsonString);

  client.publish(LED_STATUS_TOPIC, jsonString);
  Serial.print("Published LED status: ");
  Serial.println(jsonString);
}

void setup() {
  Serial.begin(115200);
  cameraInit();
  connect();
  pinMode(ledPin, OUTPUT);
}

void loop() {
  client.loop();

  if (client.connected()) {
    // Llama continuamente a grabImage si playingVideo es true
    if (playingVideo) {
      grabImage(false);
    }
  }

  delay(100);  // Retraso para no saturar la red con demasiadas imágenes
}

void cameraInit() {
  camera_config_t config;

  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_VGA; // 640x480
  config.jpeg_quality = 10;
  config.fb_count = 2;

  esp_err_t err = esp_camera_init(&config);

  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    ESP.restart();
    return;
  }

  Serial.println("\n\n=====================");
  Serial.println("Camera init Success!");
  Serial.println("=====================\n\n");
}

void grabImage(bool ding) {
  camera_fb_t *fb = esp_camera_fb_get();

  if (fb != NULL && fb->format == PIXFORMAT_JPEG && fb->len < bufferSize) {
    Serial.print("Image Length: ");
    Serial.print(fb->len);
    Serial.print("\t Publish Image: ");

    bool result = client.publish(ESP32CAM_PUBLISH_TOPIC, (const char *)fb->buf, fb->len);

    if (!result) {
      Serial.println("No Result====== ");
      ESP.restart();
    }
  }

  esp_camera_fb_return(fb);
  delay(1);
}
