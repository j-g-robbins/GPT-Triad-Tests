# Helper functions for processing triad data

library(tidyverse)
library(httr)
library(dplyr)
library(stringr)

# Reads and processes triadic data into a dataframe
process_triad_data <- function(file_path, answer_col = NULL) {
  triad_data <- readr::read_csv(file_path, show_col_types = FALSE)

  raw_answer_cols <- c("AB", "AC", "BC")
  percent_answer_cols <- c("pAC", "pBC", "pBC")

  # Rename answer column to standard if existing
  if (!is.null(answer_col) && answer_col %in% colnames(triad_data)) {
    if (any(c("AB", "AC", "BC")))
      colnames(triad_data)[colnames(df) == answer_col] <- "human_coded_answer"

  } else if (all(raw_answer_cols %in% colnames(triad_data))) {

    # Calculate answer probabilities if required
    if (!(all(percent_answer_cols %in% colnames(triad_data)))) {
      triad_data <- triad_data %>%
        rowwise %>%
        mutate(
          num_responses = sum(AB, AC, BC),
          pAB = AB / num_responses,
          pAC = AC / num_responses,
          pBC = BC / num_responses,
        ) %>%
        select(-num_responses)
    }

    # Calculate the answer and difficulty for each triad
    triad_data <- triad_data %>%
      mutate(
        max_val = pmax(pAB, pAC, pBC),
        human_coded_answer = str_c(
          ifelse(pAB == max_val, "AB,", ""),
          ifelse(pAC == max_val, "AC,", ""),
          ifelse(pBC == max_val, "BC,", ""),
          sep = ""
        ),
        difficulty = (1 - max_val) * 3 / 2,
      ) %>%
      select(-max_val)

  } else {
    print("Triad answer data not found. Answer frequency should be stored in 
          columns c(AB, AC, BC)")
  }
  
  triad_data <- triad_data %>%
    rowwise %>%
    mutate(
      regex = paste0("(", paste(A, B, C, sep = "|"), ")", sep = ""),
      t1 = NA,
      t2 = NA,
      t3 = NA,
      t4 = NA,
      t5 = NA,
      t6 = NA
    )
  
  # Format a triad string for each row of format: '{word_A,word_B,word_C};'
  for (i in seq(1, nrow(triad_data))) {
    perms <- list(combinat::permn(c(triad_data[i,]$A, triad_data[i,]$B, triad_data[i,]$C)))[[1]]
    triad_data[i,]$t1 <- paste0("{", paste(perms[[1]], collapse = ","), "};", sep = "")
    triad_data[i,]$t2 <- paste0("{", paste(perms[[2]], collapse = ","), "};", sep = "")
    triad_data[i,]$t3 <- paste0("{", paste(perms[[3]], collapse = ","), "};", sep = "")
    triad_data[i,]$t4 <- paste0("{", paste(perms[[4]], collapse = ","), "};", sep = "")
    triad_data[i,]$t5 <- paste0("{", paste(perms[[5]], collapse = ","), "};", sep = "")
    triad_data[i,]$t6 <- paste0("{", paste(perms[[6]], collapse = ","), "};", sep = "")
  }

  return(triad_data)
}


# Generates prompts by inserting triads between a prompt prefix and suffix
generate_prompts <- function(
  triad_data,
  prompt_start,
  prompt_end = "",
  num_triads = 1 # number of triads per prompt, default to 1
) {
  prompts <- data.frame(
    p1 = character(), 
    p2 = character(), 
    p3 = character(), 
    p4 = character(), 
    p5 = character(), 
    p6 = character(), 
    regex = character(),
    stringsAsFactors = FALSE
  )

  # Remaining triads for final prompt
  rem <- nrow(triad_data) %% num_triads

  # Build prompts with that many triads from the data
  for (i in seq(from = 1, to = nrow(triad_data) - rem, by = num_triads)) {

    prompts <- prompts %>% add_row(
      p1 = paste(prompt_start, triad_data[seq(i, i + num_triads - 1), ]$t1, prompt_end, sep = ""),
      p2 = paste(prompt_start, triad_data[seq(i, i + num_triads - 1), ]$t2, prompt_end, sep = ""),
      p3 = paste(prompt_start, triad_data[seq(i, i + num_triads - 1), ]$t3, prompt_end, sep = ""),
      p4 = paste(prompt_start, triad_data[seq(i, i + num_triads - 1), ]$t4, prompt_end, sep = ""),
      p5 = paste(prompt_start, triad_data[seq(i, i + num_triads - 1), ]$t5, prompt_end, sep = ""),
      p6 = paste(prompt_start, triad_data[seq(i, i + num_triads - 1), ]$t6, prompt_end, sep = ""),
      regex = triad_data[seq(i, i + num_triads - 1), ]$regex
    )
  }

  if (rem > 0) {
    remaining_triads <- paste(
      triad_data[seq(nrow(triad_data) - rem + 1, nrow(triad_data)), ]$triad,
      collapse = ""
    )
    leftovers_prompt <- paste(
      prompt_start, remaining_triads, prompt_end, sep = ""
    )
    prompts <- prompts %>% add_row(prompt = leftovers_prompt)
  }
  return(prompts)
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
process_response <- function(response, triad_rx, prompting_method = "explain") {
  message <- tolower(content(response)$choices[[1]]$message$content)

  # Remove where gpt repeats the triad, e.g., "{word1, word2, word3}"
  message <- str_replace_all(
    message,
    "(\\{[\\w]+[^\\w]+[\\w]+[^\\w]+[\\w]+\\})",
    ""
  )

  if (prompting_method == "odd") {
    reg <- paste(
      "(?<=(odd word )?(.{0,30}))",
      triad_rx,
      "(.{0,40})$",
      sep = ""
    )
    triad_results <- str_extract_all(
      message,
      reg
    )

    results <- tibble(triad_results)

  } else {
    if (prompting_method == "basic") {
      reg <- paste(
        triad_rx,
        "(.{0,30})",
        triad_rx,
        "(.{0,20})$",
        sep = ""
      )
      # When asking ChatGPT only for the most similar pair
      triad_results <- str_extract_all(
        message,
        reg
      )[[1]]
      if (length(triad_results) > 0) {
        triad_results <- paste(str_extract_all(
          triad_results,
          triad_rx
        )[[1]], collapse = " ")
      }
      return(triad_results)
    }
  }
  #print(reg)
  #print(triad_results)
  return(results[1,])
}


format_frequencies <- function(row_data) {
  freqs <- tibble(coded_answer = c('AB', 'BC', 'AC'),
                  count = c(0, 0, 0))
  
  formatted <- freqs %>% 
    full_join(row_results, by = "coded_answer") %>% 
    mutate(count = coalesce(count.y, count.x)) %>% 
    group_by(coded_answer) %>% 
    summarise(count = sum(count, na.rm = TRUE))
  
  return(formatted)
}