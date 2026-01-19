#!/usr/bin/env python3

import sys
import os
import logging
import warnings
from pathlib import Path
from typing import Optional

import torch
import gc

MODEL_NAME = "nvidia/parakeet-tdt-0.6b-v2"

def configure_silence() -> None:
    warnings.filterwarnings("ignore", category=UserWarning)
    warnings.filterwarnings("ignore", category=FutureWarning)
    warnings.filterwarnings("ignore", category=DeprecationWarning)

    for logger_name in [
        "pytorch_lightning",
        "nemo_logger",
        "nemo",
        "transformers",
        "torch",
    ]:
        logging.getLogger(logger_name).setLevel(logging.ERROR)

    try:
        from nemo.utils import logging as nemo_logging
        nemo_logging.setLevel(logging.ERROR)
    except ImportError:
        pass

def load_optimized_model():
    try:
        import nemo.collections.asr as nemo_asr
    except ImportError as e:
        print(f"Error: NeMo ASR not installed: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        print("Loading model to CPU...", file=sys.stderr)
        model = nemo_asr.models.ASRModel.from_pretrained(
            model_name=MODEL_NAME,
            map_location=torch.device("cpu")
        )

        model = model.half()
        model.eval()

        gc.collect()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

        if torch.cuda.is_available():
            print("Moving model to GPU...", file=sys.stderr)
            model = model.cuda()
        else:
            print("Warning: CUDA not available, running on CPU (will be slow)", file=sys.stderr)

        return model

    except Exception as e:
        print(f"Error loading model: {e}", file=sys.stderr)
        sys.exit(1)

def transcribe_audio(model, audio_path: Path) -> Optional[str]:
    try:
        with torch.inference_mode():
            output = model.transcribe([str(audio_path)], verbose=False)

        if not output or not isinstance(output, list) or len(output) == 0:
            return None

        result = output[0]

        if hasattr(result, 'text'):
            text = result.text
        elif hasattr(result, 'hypothesis'):
            text = result.hypothesis
        else:
            text = str(result)

        text = text.strip() if text else None
        return text if text else None

    except torch.cuda.OutOfMemoryError:
        print("Error: GPU out of memory. Try a shorter audio file.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Transcription error: {e}", file=sys.stderr)
        sys.exit(1)


def validate_audio_file(audio_path: Path) -> None:
    if not audio_path.exists():
        print(f"Error: Audio file not found: {audio_path}", file=sys.stderr)
        sys.exit(1)

    if not audio_path.is_file():
        print(f"Error: Not a file: {audio_path}", file=sys.stderr)
        sys.exit(1)

    if audio_path.stat().st_size == 0:
        print(f"Error: Audio file is empty: {audio_path}", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python transcribe_parakeet.py <path_to_wav>", file=sys.stderr)
        sys.exit(1)

    audio_path = Path(sys.argv[1]).resolve()
    validate_audio_file(audio_path)

    configure_silence()

    asr_model = load_optimized_model()

    text = transcribe_audio(asr_model, audio_path)

    if text:
        print(text)


if __name__ == "__main__":
    main()
