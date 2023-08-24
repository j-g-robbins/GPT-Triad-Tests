# GPT-Triad-Tests
Mini data collection and processing pipeline for testing ChatGPT on Triad word tasks.

## Triads
A triad is a word task where the participant has to select the two words that are most related
- `{ complaint, harm, phobia }`

The answer is formatted programmatically as the letters corresponding to the word pair, so complaint-harm would be AB.

## Data Pipeline
This program takes a csv containg triad data.
Required columns are:
- columns `A, B, C` for each word of each triad
- columns `AB, AC, BC` with the frequency of each word response from participants (if applicable)

## Customising
Fields you can easily customise are
- Prompt formatting: `prompt_start` and `prompt_end` (note: adding text between triads would be more involved)
- Triads per prompt: `triads_per_prompt` 
- GPT Model: `gpt_model`
- GPT Temperature: `gpt_temperature`
- Similarity Ratings: `similarity_scores` (if asking chatgpt to rate the similarity of each word-pair)
