# GPT-Triad-Tests
Mini data collection and processing pipeline for testing ChatGPT on Triad word tasks.

## Triads
A triad is a word task where the participant has to select the two words that are most related
- `{ complaint, harm, phobia }`
The answer is formatted programmatically as the letters corresponding to the word pair, so complaint-harm would be AB.

## Parallelization
- Using the `future` and `future.apply` libraries we are able to speed up querying time.
- This allows us to run 120+ prompts concurrently, reducing the wait time (at 10s/query for example) for 600 prompts from 90m when serialized to <5 minutes when parallelised (literal difference varies by prompt I/O size)

## Data Pipeline
1. The program reads in CSV triad data.
2. It then takes a prompt format, and generates (suboptimal, I know) 6 prompts for each triad in the dataset, one for each possible word order.
3. ChatGPT is then queried for the prompts in parallel, to speed up processing time.
4. The responses are then processed, answers are parsed via (weak) regex strategies and then coded as answers to the triad. This processing returns the frequency of selection of each triad answer.
5. Data analysis is then run, using statistical tests **TBD**
6. Results are then displayed in tabular form.

## Inputs

**Data**
- This program takes a csv containg triad data. Columns required are:
-  `A, B, C` for each word of each triad
2. `AB, AC, BC` with the frequency of each word response from participants (if applicable)
Fields you can easily customise are:

**Variables**
`prompt_start` and `prompt_end`
- These can be used to format the prompt to be sent to ChatGPT. The strings are concatenated with the triads in the middle.

`triads_per_prompt`
- This can be changed if attempting to use a different number of triads per prompt, although has been deprecated to a default value of 1 in the `generate_prompts()` function, as using multiple triads was too susceptible to noise.

`gpt_model` and `gpt_temperature`
- These are parameters for the API call to OpenAI, defaults are "gpt-3.5-turbo" and 0 respectively.

`prompt_method`
- This came about from testing various prompting methods for triads, options include basic, odd, and similarity.
- **basic**: used when asking ChatGPT to give the most similar pair in the triad.
- **odd**: used when asking ChatGPT to pick the odd word out (an emulation of solving the triad that was found to have less noise).
- **explain**: used when asking ChatGPT to explain each word or word-pair connection, then select the most similar word pair.
- **similarity**: (**now removed**) was used when asking ChatGPT to rank each word-pair's similarity.
- NOTE: These options are built on flimsy regexes that were not generalised (overengineering). Therefore, you should opt for formatting of `{word1, word2};` in one-shot or few-shot training to give the best chance at regexes working. Asking for an answer at the end of the response is also helpful.

`concurrent`
- This is the number of triads that will be run simultaneously. Each triad will be run 6 times, to use each possible word ordering.
- The default value of 20 means that 120 prompts will be run at once, 6 per triad for 20 triads.
- Optimal performance will depend on the number of cores of your machine and tailoring to this (`library(parallel), detectCores()`)
