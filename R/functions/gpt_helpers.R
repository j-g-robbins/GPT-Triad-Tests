# Helper functions for working with OpenAI ChatGPT API

library(jsonlite)
library(httr)
library(dplyr)
library(stringr)

# Roughly estimates the cost of a request given the prompt and number of triads
# @param model          A string representing the ChatGPT model
# @param num_requests   An integer reprsenting the number of requests to be sent
# @param prompt         A string of the prompt to be asked
# @param num_triads     An integer representing the number of triads per prompt
# @return None
estimate_cost <- function(model, num_requests, prompt, num_triads) {
  if (model == "gpt-3.5-turbo") {
    p_token_rate <- 0.0015
    c_token_rate <- 0.002
  } else if (model == "gpt-4") {
    p_token_rate <- 0.03
    c_token_rate <- 0.06
  } else {
    return("Unknown model name")
  }
  # Prompt tokens estimate
  prompt_tokens <- (nchar(prompt) + num_triads * 5) / 4
  # Completion tokens estimate
  completion_tokens <- num_triads * 4

  cost <- num_requests * (
    prompt_tokens * p_token_rate +
      completion_tokens * c_token_rate
  ) / 1000
  print("-----------------------------------------")
  print(paste("It will cost approx. $", round(cost, 5), "to run all prompts."))
  print("-----------------------------------------")
}


# Sends a request to OpenAI API
# @param prompt         A string of the prompt to be asked
# @param model          A string representing the ChatGPT model
# @param temperature    A decimal representing variation in responses, default 0
# @param api_key        A string of the OpenAI api key being used
# @return response      A json structured response from OpenAI
ask_gpt <- function(
  prompt,
  model,
  temperature = 0,
  api_key
) {
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(Authorization = paste("Bearer", api_key)),
    content_type_json(),
    encode = "json",
    body = list(
      model = model,
      temperature = temperature,
      messages = list(list(
        role = "user",
        content = prompt
      ))
    )
  )
  return(response)
}

extract_pairs <- function(message) {
  words <- unlist(str_extract_all(message, "[a-zA-Z]+"))
  word_pairs <- sapply(seq(1, length(words), 2), function(i) {
    paste(words[i], words[i + 1], sep = "-")
  })
  return(word_pairs)
}

# Processes the response from chatgpt and returns a list of triad answers
# @param response       A json structured response from OpenAI
# @return result_pairs  A list of triad answers
process_response <- function(response, similarity_scores = FALSE) {
  message <- tolower(content(response)$choices[[1]]$message$content)

  # Remove where gpt repeats the triad, e.g., "{word1, word2, word3}"
  message <- str_replace_all(
    message,
    "(\\{[\\w]+[^\\w]+[\\w]+[^\\w]+[\\w]+\\}|most similar pair)",
    ""
  )

  if (similarity_scores) {
    # Select similarity scores, e.g., "{word1 and word2, 0.1}"
    triad_results <- str_extract_all(
      message,
      "\\{[\\w]+[^\\w]+[\\w]+[^\\w]+\\d+(\\.\\d+)?\\}"
    )[[1]]

    # Try another method for the same thing if that failed
    if (length(triad_results) < 1) {
      triad_results <- str_extract_all(
        message,
        "[\\w]+ (-|–|,) [\\w]+[^\\w]+\\d+(\\.\\d+)?"
      )[[1]]
    }

    # Group and save every 2 words (i.e., every triad answer)
    word_pairs <- extract_pairs(message)

    # Save every similarity score (e.g., 0.8)
    similarity <- as.numeric(
      unlist(str_extract_all(triad_results, "[0-9\\.]+"))
    )

    # Store results
    results <- tibble(similarity)
    results <- results %>%
      mutate(word_pairs = word_pairs) %>%
      distinct(word_pairs, .keep_all = TRUE) %>%
      select(word_pairs, everything())

  } else {
    # When asking ChatGPT only for the most similar pair
    # Find the answer
    triad_results <- str_extract_all(
      message,
      "\\{[\\w]+[^\\w]+[\\w]+\\}"
    )[[1]]
    # Try another method if that failed
    if (length(triad_results) < 1) {
      triad_results <- str_extract_all(
        message,
        "\\{[\\w]+ (-|–|,) [\\w]+\\}"
      )[[1]]
    }

    # Else just try the message itself
    if (length(triad_results) < 1) {
      triad_results <- message
    }

    # Group and save every 2 words (i.e., every triad answer)
    word_pairs <- extract_pairs(triad_results)
    results <- tibble(word_pairs) %>%
      distinct(word_pairs, .keep_all = TRUE)
  }

  return(results)
}
