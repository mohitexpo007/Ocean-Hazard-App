# nlp_filter.py
from transformers import pipeline

hazard_keywords = ["earthquake", "flood", "cyclone", "tsunami", "landslide", "disaster"]

classifier = pipeline(
    "text-classification", 
    model="distilbert-base-uncased-finetuned-sst-2-english"
)

def is_hazard_post(text: str) -> bool:
    text_lower = text.lower()
    if not any(word in text_lower for word in hazard_keywords):
        return False

    # Use sentiment classifier but allow any strong signal
    result = classifier(text)[0]

    # Accept if model confidence is high (positive OR negative)
    return result["score"] > 0.60

