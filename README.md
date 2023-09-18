# GPT-Triad-Tests
Mini data collection and processing pipeline for testing ChatGPT on Triad word tasks.

## This project
We are exploring the evidence of humanlike generalisation in Large Language Models, particularly GPT-3.5-turbo and GPT-4.
To do this we are using Triad tasks, where the participant is presented three words and has to select the two words that are most related (e.g., `{ complaint, harm, phobia }`, answer could be `complaint-harm`, or `AB`.

GPT-3.5-turbo and GPT-4 will be presented with 'Concrete' triads (words with a visual referent) as a baseline, and then 'Abstract' triads (words that lack visual referents). Performance on abstract triads will be analysed for similarity to human performance, which may reveal insights about how emotional information is encoded in these models. 

Conditions will include zero-shot and few-shot training, and we will present the task in two conditions, asking for the most similar pair `complaint-harm` and asking for the odd word out `phobia`.

As we found **significant** word-order effects with both GPT-3.5-turbo and GPT-4, all permutations of a triad were presented (ABC, ACB, BCA, BAC, CAB, CBA). Three further arrangements were repeated (ABC, BCA, CBA), as this was necessary to reduce tied answers to an acceptable level. As this ballooned the number of queries run, I opted to parallelise queries to make the duration of data collection manageable.

## Parallelization
Using the `future` and `future.apply` libraries we are able to speed up querying time by parallelising OpenAI queries. This allows us to run 120+ prompts concurrently (CPU-dependent), reducing the wait time by over 95%.

## Data Pipeline
1. The program reads in CSV triad data.
2. It then takes a prompt format, and generates (suboptimal, I know) 6 prompts for each triad in the dataset, one for each possible word order.
3. ChatGPT is then queried for the prompts in parallel, to speed up processing time.
4. The responses are then processed, answers are parsed via (weak) regex strategies and then coded as answers to the triad. This processing returns the frequency of selection of each triad answer.
5. Results are then displayed in tabular format.

## Inputs

**Data**
- This program takes a csv containg triad data. Columns required are:
1.  `A, B, C` for each word of each triad
2. `AB, AC, BC` with the frequency of each word response from participants (if applicable)

Fields you can customise are:
**Variables**
`prompt_start` and `prompt_end`
- These can be used to format the prompt to be sent to ChatGPT. The strings are concatenated with the triads in the middle.

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
