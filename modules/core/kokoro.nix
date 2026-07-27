{ pkgs, settings, ... }:
let
  langCodes = {
    en = "a";
    ja = "j";
  };

  defaultVoices = {
    en = "af_bella";
    ja = "jf_alpha";
  };

  python = pkgs.python312.withPackages (ps: [
    ps.fastapi
    ps.kokoro
    ps.numpy
    ps.soundfile
    ps.uvicorn
  ] ++ ps.misaki.optional-dependencies.ja);

  kokoroTts = pkgs.writeShellApplication {
    name = "kokoro-tts";
    runtimeInputs = [
      python
      pkgs.coreutils
      pkgs.espeak-ng
    ];
    text = ''
      set -euo pipefail

      exec ${python}/bin/python - "$@" <<'PY'
      from __future__ import annotations

      import argparse
      import io
      import json
      import sys
      from typing import Any

      import numpy as np
      import soundfile as sf
      from fastapi import FastAPI, HTTPException
      from fastapi.responses import Response
      from kokoro import KPipeline
      import uvicorn

      LANG_CODES = {
          "en": "a",
          "ja": "j",
      }

      DEFAULT_VOICES = {
          "en": ["af_bella", "af_sarah"],
          "ja": ["jf_alpha", "jf_tebukuro"],
      }

      SAMPLE_RATE = 24000

      def build_pipeline(lang: str) -> KPipeline:
          try:
              return KPipeline(lang_code=LANG_CODES[lang])
          except KeyError as exc:
              raise ValueError(f"unsupported language: {lang}") from exc

      def synthesize(text: str, lang: str, voice: str, speed: float, split_pattern: str) -> np.ndarray:
          pipeline = build_pipeline(lang)
          chunks: list[np.ndarray] = []

          for _, _, audio in pipeline(text, voice=voice, speed=speed, split_pattern=split_pattern):
              chunk = np.asarray(audio, dtype=np.float32).reshape(-1)
              if chunk.size:
                  chunks.append(chunk)

          if not chunks:
              raise RuntimeError("Kokoro returned no audio")

          return np.concatenate(chunks)

      def wav_bytes(audio: np.ndarray) -> bytes:
          buf = io.BytesIO()
          sf.write(buf, audio, SAMPLE_RATE, format="WAV")
          return buf.getvalue()

      app = FastAPI(title="Kokoro TTS", version="1.0")

      @app.get("/health")
      def health() -> dict[str, str]:
          return {"status": "ok"}

      @app.get("/voices")
      def voices() -> dict[str, Any]:
          return {
              "sample_rate": SAMPLE_RATE,
              "supported_languages": list(LANG_CODES.keys()),
              "default_voices": DEFAULT_VOICES,
          }

      @app.post("/tts")
      def tts(payload: dict[str, Any]) -> Response:
          text = str(payload.get("text", "")).strip()
          if not text:
              raise HTTPException(status_code=400, detail="text is required")

          lang = str(payload.get("lang", "en"))
          if lang not in LANG_CODES:
              raise HTTPException(status_code=400, detail=f"unsupported language: {lang}")

          voice = str(payload.get("voice", DEFAULT_VOICES[lang]))
          speed = float(payload.get("speed", 1.0))
          split_pattern = str(payload.get("split_pattern", r"\\n+"))

          audio = synthesize(text, lang, voice, speed, split_pattern)
          return Response(content=wav_bytes(audio), media_type="audio/wav")

      def parse_args() -> argparse.Namespace:
          parser = argparse.ArgumentParser(description="Kokoro TTS helper and local server")
          parser.add_argument("text", nargs="?", help="Text to synthesize. Reads stdin when omitted.")
          parser.add_argument("-o", "--output", default="kokoro.wav", help="Output path or '-' for stdout")
          parser.add_argument("--lang", choices=sorted(LANG_CODES), default="en", help="Language code")
          parser.add_argument("--voice", help="Kokoro voice name")
          parser.add_argument("--speed", type=float, default=1.0, help="Playback speed")
          parser.add_argument("--split-pattern", default=r"\\n+", help="Regex used to split text")
          parser.add_argument("--list-voices", action="store_true", help="Print the recommended voice presets")
          parser.add_argument("--serve", action="store_true", help="Run the local HTTP API")
          parser.add_argument("--host", default="127.0.0.1", help="Bind host for --serve")
          parser.add_argument("--port", type=int, default=8388, help="Bind port for --serve")
          return parser.parse_args()

      def main() -> None:
          args = parse_args()

          if args.list_voices:
              print(json.dumps({"default_voices": DEFAULT_VOICES}, indent=2, ensure_ascii=False))
              return

          if args.serve:
              uvicorn.run(app, host=args.host, port=args.port, log_level="info")
              return

          text = args.text if args.text is not None else sys.stdin.read()
          text = text.strip()
          if not text:
              raise SystemExit("No text provided")

          voice = args.voice or DEFAULT_VOICES[args.lang]
          audio = synthesize(text, args.lang, voice, args.speed, args.split_pattern)

          if args.output == "-":
              sf.write(sys.stdout.buffer, audio, SAMPLE_RATE, format="WAV")
          else:
              sf.write(args.output, audio, SAMPLE_RATE)

      if __name__ == "__main__":
          main()
      PY
    '';
  };
in
{
  environment.systemPackages = [ kokoroTts ];

  systemd.services.kokoro-tts = {
    description = "Kokoro local TTS API";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = settings.username;
      Group = "users";
      WorkingDirectory = "/home/${settings.username}";
      ExecStart = "${kokoroTts}/bin/kokoro-tts --serve --host 127.0.0.1 --port 8388";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
    };
  };
}
