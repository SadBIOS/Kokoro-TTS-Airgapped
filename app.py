import os
import subprocess
import json
import urllib.request
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, Response

app = FastAPI()

KOKORO_API_URL = "http://127.0.0.1:8000/v1/audio/speech"
DOWNLOAD_COUNTER = 0

@app.get("/", response_class=HTMLResponse)
async def get_index():
    with open("index.html", "r", encoding="utf-8") as f:
        return f.read()

@app.post("/api/play")
async def play_audio(request: Request):
    """Endpoint for the 'Play' button. Streams raw WAV immediately."""
    data = await request.json()
    payload = json.dumps({
        "model": "kokoro",
        "voice": data.get("voice", "jf_alpha"),
        "input": data.get("text", ""),
        "response_format": "wav"
    }).encode("utf-8")

    req = urllib.request.Request(KOKORO_API_URL, data=payload, method="POST")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as response:
            audio_data = response.read()
        return Response(content=audio_data, media_type="audio/wav")
    except Exception as e:
        return Response(content=f"Backend Generation Error: {str(e)}", status_code=500)

@app.post("/api/download")
async def download_audio(request: Request):
    """Endpoint for 'Download' button. Converts via FFmpeg and handles naming rules."""
    global DOWNLOAD_COUNTER
    data = await request.json()
    fmt = data.get("format", "wav")

    payload = json.dumps({
        "model": "kokoro",
        "voice": data.get("voice", "jf_alpha"),
        "input": data.get("text", ""),
        "response_format": "wav" 
    }).encode("utf-8")

    req = urllib.request.Request(KOKORO_API_URL, data=payload, method="POST")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as response:
            audio_data = response.read()

        input_path = "/tmp/temp_kokoro.wav"
        with open(input_path, "wb") as f:
            f.write(audio_data)

        output_filename = f"ja_jp_{DOWNLOAD_COUNTER}.{fmt}"
        output_path = f"/tmp/{output_filename}"

        if fmt != "wav":
            cmd = ["/usr/bin/ffmpeg", "-y", "-i", input_path, output_path]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise Exception(f"FFmpeg process failed: {result.stderr}")
        else:
            os.rename(input_path, output_path)

        DOWNLOAD_COUNTER += 1

        with open(output_path, "rb") as f:
            final_audio = f.read()

        if os.path.exists(output_path): os.remove(output_path)
        if os.path.exists(input_path): os.remove(input_path)

        headers = {
            "X-Filename": output_filename,
            "Access-Control-Expose-Headers": "X-Filename"
        }
        return Response(content=final_audio, media_type=f"audio/{fmt}", headers=headers)

    except Exception as e:
        return Response(content=str(e), status_code=500)