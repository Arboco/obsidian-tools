# transcribe.py

from faster_whisper import WhisperModel
import argparse
import os

def transcribe_audio(audio_path, model_size="base", device="cpu", compute_type="int8", language=None, vad_filter=False, beam_size=5):
    # Load the model
    model = WhisperModel(model_size, device=device, compute_type=compute_type)
    
    # Transcribe the audio
    segments, info = model.transcribe(
        audio_path,
        beam_size=beam_size,
        language=language,
        vad_filter=vad_filter
    )

    print(f"\n[Language detected: {info.language}]\n")
    
    for segment in segments:
        print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Transcribe audio using faster-whisper.")
    parser.add_argument("audio_path", type=str, help="Path to the audio file (mp3, wav, etc.)")
    parser.add_argument("--model_size", type=str, default="base", help="Model size: tiny, base, small, medium, large-v2")
    parser.add_argument("--device", type=str, default="cpu", help="Device to use: cpu or cuda")
    parser.add_argument("--compute_type", type=str, default="int8", help="Precision: int8, int8_float32, float16, float32")
    parser.add_argument("--language", type=str, default=None, help="Force language (e.g., en, fr), or detect if not set")
    parser.add_argument("--vad", action="store_true", help="Enable VAD filtering")
    parser.add_argument("--beam_size", type=int, default=5, help="Beam size for decoding")

    args = parser.parse_args()

    if not os.path.isfile(args.audio_path):
        print("Error: File not found:", args.audio_path)
        exit(1)

    transcribe_audio(
        audio_path=args.audio_path,
        model_size=args.model_size,
        device=args.device,
        compute_type=args.compute_type,
        language=args.language,
        vad_filter=args.vad,
        beam_size=args.beam_size
    )
