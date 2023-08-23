# Helper functions for working with OpenAI ChatGPT API

# Roughly estimates the cost of a request given the prompt and number of triads
# @param model          A string representing the ChatGPT model
# @param num_requests   An integer reprsenting the number of requests to be sent
# @param prompt         A string of the prompt to be asked
# @param num_triads     An integer representing the number of triads per prompt
# @return None
estimate_cost <- function(model, num_requests, prompt, num_triads) {
  if (model == "gpt-3.5-turbo") {
    p_token_rate = 0.0015
    c_token_rate = 0.002
  } else if (model == "gpt-4") {
    p_token_rate = 0.03
    c_token_rate = 0.06
  } else {
    return("Unknown model name")
  }
  # Prompt tokens estimate
  prompt_tokens = (nchar(prompt) + num_triads * 5) / 4
  # Completion tokens estimate
  completion_tokens = num_triads * 4
  
  cost = nrow(prompts) * (
    prompt_tokens * p_token_rate + 
      completion_tokens * c_token_rate
  ) /1000
  print("-----------------------------------------")
  print(paste("It will cost around $", round(cost, 5), "to run on all triads."))
  print("-----------------------------------------")
}


# Sends a request to OpenAI API
# @param model          A string representing the ChatGPT model
# @param temperature    A decimal [0, 1] representing the randomness in response
# @param prompt         A string of the prompt to be asked
# @return response      A json structured response from OpenAI
ask_gpt <- function(model, temperature, prompt) {
  response = POST(
    url = "https://api.openai.com/v1/chat/completions", 
    add_headers(Authorization = paste("Bearer", apiKey)),
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


# Processes the response from chatgpt and returns a list of triad answers
# @param response       A json structured response from OpenAI
# @return result_pairs  A list of triad answers
process_response <- function(response) {
  message = content(response)$choices[[1]]$message$content
  
  words = unlist(strsplit(message, "[^a-zA-Z]+"))
  
  if (length(words) <= 1) {
    return("tmp")
  }
  
  num_triads = length(words)/2
  result_pairs =  sapply(seq(1, length(words), 2), function(i) {
    paste(words[i], words[i+1], sep = "-")
  })
  
  return(result_pairs)
}
