# Helper functions for working with OpenAI ChatGPT API

library(jsonlite)
library(httr)
library(dplyr)
library(stringr)

# Roughly estimates the cost of a request given the prompt and number of triads
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

fast_query <- function(rows) {
  start <- Sys.time()
  
  responses <- furrr::future_map(1:nrow(rows), function(i) {
    cat(i, " ")
    current_row_responses <- future_lapply(
      c(rows$p1[i], rows$p2[i], rows$p3[i], rows$p4[i], rows$p5[i], rows$p6[i]), 
      function(prompt) ask_gpt(
        prompt = prompt,
        model = gpt_model,
        temperature = gpt_temperature,
        api_key = api_key
      )
    )
  })
  
  print(Sys.time() - start)
  return(tibble(responses))
}

