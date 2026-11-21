"""Generates the reference fixtures for the pure-Dart Chronos-Bolt port.

The app runs Chronos-Bolt with its own Dart implementation of the forward pass
(lib/ai/chronos/chronos_bolt_model.dart). This script pins that port to the
official implementation: it builds a tiny Chronos-Bolt with random weights
through the `chronos-forecasting` package, runs the reference PyTorch forward
pass over a few contexts and writes the weights, the config and the expected
quantiles to test/fixtures/chronos_bolt/. The Dart test loads the same files
and has to reproduce the numbers.

The tiny model has the real architecture with smaller sizes, so the fixture
stays a few kilobytes and CI never needs to download the real weights. It
still exercises every code path: an inner attention size different from
d_model, the logarithmic relative-position buckets, a context that is not a
multiple of the patch size, a context longer than the model's window and a
flat series (zero scale).

Usage (from the repository root):

    python -m venv .venv
    .venv/bin/pip install chronos-forecasting==2.3.2 safetensors
    .venv/bin/python tool/chronos_reference/generate_fixtures.py

Pass --real-model DIR to also check a downloaded copy of
amazon/chronos-bolt-tiny (config.json + model.safetensors); it writes
expected_real.json next to the weights, which the optional Dart test
`CHRONOS_BOLT_TINY_DIR=DIR flutter test test/ai/chronos_bolt_model_test.dart`
compares against.
"""

import argparse
import json
import math
import os

import torch
from chronos.chronos_bolt import ChronosBoltModelForForecasting
from safetensors.torch import save_file
from transformers import T5Config

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FIXTURE_DIR = os.path.join(ROOT, "test", "fixtures", "chronos_bolt")


def tiny_config() -> T5Config:
    return T5Config(
        architectures=["ChronosBoltModelForForecasting"],
        d_model=16,
        d_ff=32,
        d_kv=4,
        num_heads=2,
        num_layers=2,
        num_decoder_layers=2,
        relative_attention_num_buckets=8,
        relative_attention_max_distance=20,
        layer_norm_epsilon=1e-6,
        feed_forward_proj="relu",
        dense_act_fn="relu",
        is_encoder_decoder=True,
        decoder_start_token_id=0,
        pad_token_id=0,
        eos_token_id=1,
        vocab_size=2,
        dropout_rate=0.0,
        chronos_config={
            "context_length": 32,
            "prediction_length": 32,
            "input_patch_size": 4,
            "input_patch_stride": 4,
            "quantiles": [0.1, 0.5, 0.9],
            "use_reg_token": True,
        },
    )


def contexts():
    wave = [10 + 2 * math.sin(i / 3) + 0.1 * i for i in range(40)]
    return {
        # 13 points: the first patch is padded on the left.
        "short": [5.0, 5.1, 5.05, 5.2, 5.15, 5.3, 5.25, 5.4, 5.35, 5.5, 5.45, 5.6, 5.55],
        # 40 points: longer than the 32-point window, so it is truncated, and
        # long enough for the logarithmic buckets.
        "wave": wave,
        "flat": [3.0] * 9,
    }


def run(model, context):
    with torch.no_grad():
        output = model(context=torch.tensor([context], dtype=torch.float32))
    return output.quantile_preds[0].tolist()


def generate_tiny():
    torch.manual_seed(1234)
    model = ChronosBoltModelForForecasting(tiny_config()).eval()
    # The default initialisation is tiny (initializer_factor 1.0 on a 16-wide
    # model still leaves the decoder output almost constant). Wider random
    # weights make every layer matter for the result.
    with torch.no_grad():
        for name, parameter in model.named_parameters():
            if name.endswith("layer_norm.weight"):
                parameter.copy_(1 + 0.2 * torch.randn_like(parameter))
            else:
                parameter.copy_(0.3 * torch.randn_like(parameter))

    os.makedirs(FIXTURE_DIR, exist_ok=True)
    state = {k: v.contiguous() for k, v in model.state_dict().items()
             if k not in ("encoder.embed_tokens.weight", "decoder.embed_tokens.weight")}
    save_file(state, os.path.join(FIXTURE_DIR, "model.safetensors"))
    with open(os.path.join(FIXTURE_DIR, "config.json"), "w") as file:
        file.write(model.config.to_json_string())

    expected = {name: {"context": context, "quantiles": run(model, context)}
                for name, context in contexts().items()}
    with open(os.path.join(FIXTURE_DIR, "expected.json"), "w") as file:
        json.dump(expected, file, indent=1)


def check_real(directory):
    model = ChronosBoltModelForForecasting.from_pretrained(directory).eval()
    torch.manual_seed(7)
    series = {
        # A currency-like random walk and a trending, noisy crypto-like one.
        "walk": (5 * torch.exp(torch.cumsum(0.004 * torch.randn(130), 0))).tolist(),
        "trend": (300000 * torch.exp(torch.cumsum(0.002 + 0.03 * torch.randn(180), 0))).tolist(),
    }
    expected = {name: {"context": context, "quantiles": run(model, context)}
                for name, context in series.items()}
    with open(os.path.join(directory, "expected_real.json"), "w") as file:
        json.dump(expected, file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--real-model", help="directory with amazon/chronos-bolt-tiny")
    arguments = parser.parse_args()
    generate_tiny()
    if arguments.real_model:
        check_real(arguments.real_model)
