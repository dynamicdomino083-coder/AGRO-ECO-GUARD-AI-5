
"""
AGRO ECO GUARD AI 5.0
Founder & Developer: MUHAYUDDIN GAUS

Python AI Backend
Real sensor data only.
No invented sensor readings.
"""

import os
import time
from datetime import datetime, timezone
from typing import Optional

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


APP_NAME = "AGRO ECO GUARD AI 5.0"
FOUNDER = "MUHAYUDDIN GAUS"

# Configure these as private environment variables on the server.
# Never paste API keys into this public GitHub repository.
AI_API_URL = os.getenv("AI_API_URL", "")
AI_API_KEY = os.getenv("AI_API_KEY", "")
AI_MODEL = os.getenv("AI_MODEL", "")

app = FastAPI(
    title=APP_NAME,
    description="Smart Agriculture and Universal AI Backend",
    version="5.0.0"
)

# Development setting only.
# Restrict allowed origins before public production deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

# This stores only the latest received sensor payload in memory.
# It resets when the server restarts.
latest_sensor_data = None
activity_logs = []


def add_log(event: str):
    activity_logs.append({
        "event": event,
        "time": datetime.now(timezone.utc).isoformat()
    })

    if len(activity_logs) > 200:
        del activity_logs[:-200]


class AskRequest(BaseModel):
    question: str = Field(min_length=1, max_length=4000)
    language: str = "English"


class SensorData(BaseModel):
    device_id: str = "AGRO-ECO-GUARD-ESP32"
    timestamp: Optional[str] = None

    soil_moisture_raw: Optional[float] = None
    soil_moisture_pct: Optional[float] = None
    temperature_c: Optional[float] = None
    humidity_pct: Optional[float] = None
    rain_raw: Optional[float] = None
    mq4_raw: Optional[float] = None
    ldr_left_raw: Optional[float] = None
    ldr_right_raw: Optional[float] = None
    pir_motion: Optional[bool] = None
    ultrasonic_distance_cm: Optional[float] = None
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None


class ActuatorRequest(BaseModel):
    device_id: str
    actuator: str
    requested_state: str


KNOWLEDGE = {
    "soil": (
        "Soil health depends on soil texture, organic matter, "
        "drainage, nutrients and suitable pH. Soil testing helps "
        "make better fertilizer decisions."
    ),
    "irrigation": (
        "Irrigation should depend on crop requirements, soil "
        "moisture, weather and the crop growth stage. Avoid "
        "watering without checking actual field conditions."
    ),
    "rain": (
        "Rainfall information helps farmers plan irrigation and "
        "field activities. A rain sensor reading alone does not "
        "provide an accurate rainfall measurement in millimetres."
    ),
    "temperature": (
        "Temperature affects crop growth, flowering and water "
        "requirements. Compare actual readings with the needs "
        "of the specific crop."
    ),
    "humidity": (
        "Humidity affects plant water loss and can influence "
        "some crop diseases. Interpret it together with temperature "
        "and field conditions."
    ),
    "tomato": (
        "Tomatoes need suitable sunlight, well-drained soil, "
        "appropriate watering and regular crop monitoring. "
        "Avoid waterlogging."
    ),
    "rice": (
        "Rice cultivation depends on variety, soil, climate, "
        "water availability and local agricultural practices."
    ),
    "methane": (
        "An MQ-4 sensor provides a raw gas-sensor reading. "
        "It does not directly provide calibrated methane ppm. "
        "Calibration and suitable safety equipment are required."
    ),
    "solar": (
        "Solar panels convert sunlight into electrical energy. "
        "Their output depends on sunlight, orientation, temperature "
        "and system condition."
    ),
    "gps": (
        "GPS provides location coordinates when the receiver "
        "has a suitable satellite fix. Coordinates should be "
        "checked for validity before use."
    ),
}


def local_knowledge_answer(question: str):
    text = question.lower()

    for topic, answer in KNOWLEDGE.items():
        if topic in text:
            return answer

    return None


async def ask_external_ai(question: str, language: str):
    if not AI_API_URL or not AI_API_KEY or not AI_MODEL:
        return None

    system_prompt = (
        "You are AGRO ECO GUARD AI 5.0, a helpful multilingual "
        "assistant created by MUHAYUDDIN GAUS. "
        "Answer general questions, education, science, technology "
        "and agriculture questions. Respond in the requested language. "
        "Never invent sensor readings. Clearly distinguish facts "
        "from estimates. Do not claim to control hardware unless "
        "a verified hardware command system is connected."
    )

    payload = {
        "model": AI_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": (
                    "Requested language: " + language +
                    "\nQuestion: " + question
                )
            }
        ],
        "temperature": 0.5
    }

    headers = {
        "Authorization": "Bearer " + AI_API_KEY,
        "Content-Type": "application/json"
    }

    async with httpx.AsyncClient(timeout=45) as client:
        response = await client.post(
            AI_API_URL,
            json=payload,
            headers=headers
        )

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail="The external AI provider returned an error."
        )

    result = response.json()

    try:
        return result["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        raise HTTPException(
            status_code=502,
            detail="Unexpected AI provider response."
        )


@app.get("/")
async def home():
    return {
        "application": APP_NAME,
        "version": "5.0.0",
        "founder": FOUNDER,
        "status": "ONLINE",
        "message": "AGRO ECO GUARD AI Backend is running."
    }


@app.get("/api/health")
async def health():
    return {
        "status": "online",
        "application": APP_NAME,
        "ai_provider_configured": bool(
            AI_API_URL and AI_API_KEY and AI_MODEL
        ),
        "sensor_data_received": latest_sensor_data is not None,
        "time": datetime.now(timezone.utc).isoformat()
    }


@app.post("/api/ask")
async def ask_ai(request: AskRequest):
    question = request.question.strip()

    if not question:
        raise HTTPException(
            status_code=400,
            detail="Question cannot be empty."
        )

    add_log("AI question received")

    # First try the configured general-purpose AI provider.
    try:
        answer = await ask_external_ai(
            question,
            request.language
        )

        if answer:
            return {
                "answer": answer,
                "mode": "external_ai",
                "language": request.language
            }

    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="AI provider timed out."
        )

    # Limited local agriculture knowledge fallback.
    local_answer = local_knowledge_answer(question)

    if local_answer:
        return {
            "answer": local_answer,
            "mode": "local_knowledge",
            "language": request.language
        }

    return {
        "answer": (
            "The Universal AI provider is not connected yet. "
            "Please configure the secure AI provider on the backend "
            "to answer general questions. No answer has been invented."
        ),
        "mode": "not_configured",
        "language": request.language
    }


@app.post("/api/data")
async def receive_sensor_data(data: SensorData):
    global latest_sensor_data

    latest_sensor_data = data.model_dump()

    add_log("Sensor data received from " + data.device_id)

    return {
        "status": "received",
        "device_id": data.device_id,
        "message": "Sensor payload stored.",
        "time": datetime.now(timezone.utc).isoformat()
    }


@app.get("/api/data")
async def get_sensor_data():
    if latest_sensor_data is None:
        return {
            "status": "waiting",
            "message": "Waiting for real ESP32 sensor data.",
            "data": None
        }

    return {
        "status": "received",
        "data": latest_sensor_data
    }


@app.get("/api/analysis")
async def analyze_sensors():
    if latest_sensor_data is None:
        return {
            "status": "waiting",
            "analysis": "No real sensor data has been received."
        }

    data = latest_sensor_data
    observations = []

    moisture = data.get("soil_moisture_pct")

    if moisture is not None:
        observations.append(
            "Soil moisture percentage received: "
            + str(moisture)
            + "%"
        )
    else:
        observations.append(
            "Soil moisture percentage is not calibrated or available."
        )

    temperature = data.get("temperature_c")

    if temperature is not None:
        observations.append(
            "Temperature received: "
            + str(temperature)
            + " degrees Celsius."
        )

    humidity = data.get("humidity_pct")

    if humidity is not None:
        observations.append(
            "Humidity received: " + str(humidity) + "%."
        )

    return {
        "status": "analysis_complete",
        "observations": observations,
        "source": "real_received_sensor_payload"
    }


@app.get("/api/knowledge")
async def get_knowledge():
    return {
        "application": APP_NAME,
        "topics": KNOWLEDGE,
        "topic_count": len(KNOWLEDGE)
    }


@app.post("/api/actuators")
async def request_actuator(request: ActuatorRequest):
    # This endpoint records a request only.
    # It does not operate a physical pump, relay or servo.
    add_log(
        "Actuator request recorded: "
        + request.actuator
    )

    return {
        "status": "recorded_only",
        "device_id": request.device_id,
        "actuator": request.actuator,
        "requested_state": request.requested_state,
        "message": (
            "No physical hardware command was sent. "
            "A secured ESP32 command channel is not configured."
        )
    }


@app.get("/api/logs")
async def get_logs():
    return {
        "count": len(activity_logs),
        "logs": activity_logs[-50:]
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8000,
        reload=False
  )
                          
