from flask import Flask, request, jsonify
from anthropic import Anthropic
import os

app = Flask(__name__)
client = Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

FREE_SYSTEM_PROMPT = """You are a helpful AI assistant.
Give concise, useful answers. Keep responses under 200 words for free tier users."""

PREMIUM_SYSTEM_PROMPT = """You are an advanced AI assistant with full capabilities.
Provide comprehensive, detailed, and high-quality responses. No length limits."""


@app.route("/ai/ask", methods=["POST"])
def ask():
    data = request.get_json()
    prompt = data.get("prompt", "").strip()
    tier = data.get("tier", "free")
    user_id = request.headers.get("X-User-ID", "anonymous")

    if not prompt:
        return jsonify({"error": "Prompt is required"}), 400

    system_prompt = PREMIUM_SYSTEM_PROMPT if tier == "premium" else FREE_SYSTEM_PROMPT

    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2048 if tier == "premium" else 512,
        system=system_prompt,
        messages=[{"role": "user", "content": prompt}],
    )

    return jsonify({"response": message.content[0].text})


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
