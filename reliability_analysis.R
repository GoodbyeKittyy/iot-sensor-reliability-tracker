# IoT Sensor Network Reliability Analysis in R
# Advanced statistical modeling using Exponential and Erlang distributions

library(stats)
library(ggplot2)

# Exponential Distribution Reliability Analysis
exponential_reliability <- function(lambda, time_vector) {
  # R(t) = e^(-lambda * t)
  reliability <- exp(-lambda * time_vector)
  return(reliability)
}

exponential_hazard_rate <- function(lambda) {
  # Constant hazard rate for exponential distribution
  return(lambda)
}

exponential_mtbf <- function(lambda) {
  # Mean Time Between Failures
  return(1 / lambda)
}

# Erlang Distribution Reliability Analysis
erlang_reliability <- function(k, lambda, time_vector) {
  # R(t) = 1 - F(t) where F is CDF
  reliability <- 1 - pgamma(time_vector, shape = k, rate = lambda)
  return(reliability)
}

erlang_pdf <- function(k, lambda, time_vector) {
  # Probability density function
  pdf_values <- dgamma(time_vector, shape = k, rate = lambda)
  return(pdf_values)
}

erlang_mttf <- function(k, lambda) {
  # Mean Time To Failure
  return(k / lambda)
}

# Fleet Reliability Calculator
calculate_fleet_reliability <- function(sensor_data, time_horizon = 1000) {
  reliabilities <- numeric(nrow(sensor_data))
  
  for (i in 1:nrow(sensor_data)) {
    k <- sensor_data$k_stages[i]
    lambda <- sensor_data$failure_rate[i]
    reliabilities[i] <- erlang_reliability(k, lambda, time_horizon)
  }
  
  fleet_reliability <- mean(reliabilities)
  return(list(
    fleet_reliability = fleet_reliability,
    individual_reliabilities = reliabilities,
    time_horizon = time_horizon
  ))
}

# Queueing Theory M/M/c Model
mmc_queue_metrics <- function(arrival_rate, service_rate, num_servers) {
  rho <- arrival_rate / (num_servers * service_rate)
  
  if (rho >= 1) {
    return(list(
      stable = FALSE,
      message = "System unstable: rho >= 1"
    ))
  }
  
  # Calculate P0
  lambda_mu <- arrival_rate / service_rate
  sum_term <- sum(sapply(0:(num_servers - 1), function(n) {
    (lambda_mu^n) / factorial(n)
  }))
  last_term <- (lambda_mu^num_servers) / (factorial(num_servers) * (1 - rho))
  p0 <- 1 / (sum_term + last_term)
  
  # Average queue length Lq
  lq <- (p0 * (lambda_mu^num_servers) * rho) / (factorial(num_servers) * (1 - rho)^2)
  
  # Average waiting time Wq
  wq <- lq / arrival_rate
  
  # Average time in system W
  w <- wq + (1 / service_rate)
  
  # Average number in system L
  l <- arrival_rate * w
  
  return(list(
    stable = TRUE,
    utilization = rho,
    p0 = p0,
    average_queue_length = lq,
    average_waiting_time_hours = wq,
    average_waiting_time_minutes = wq * 60,
    average_time_in_system = w,
    average_number_in_system = l
  ))
}

# Generate Sample Sensor Data
generate_sensor_data <- function(n_sensors = 50) {
  sensor_types <- c("TRAFFIC", "AIR_QUALITY", "WATER_FLOW")
  
  data.frame(
    sensor_id = sprintf("SNS-%04d", 1:n_sensors),
    sensor_type = sample(sensor_types, n_sensors, replace = TRUE),
    location_x = runif(n_sensors, 5, 95),
    location_y = runif(n_sensors, 5, 95),
    location_z = runif(n_sensors, 0, 3),
    health = runif(n_sensors, 20, 100),
    uptime_hours = runif(n_sensors, 100, 8000),
    failure_rate = runif(n_sensors, 0.0003, 0.0008),
    k_stages = sample(2:5, n_sensors, replace = TRUE),
    stringsAsFactors = FALSE
  )
}

# Statistical Analysis of Sensor Network
analyze_sensor_network <- function(sensor_data) {
  # Calculate MTBF for each sensor
  sensor_data$mtbf <- sapply(sensor_data$failure_rate, exponential_mtbf)
  
  # Calculate MTTF for each sensor
  sensor_data$mttf <- mapply(erlang_mttf, sensor_data$k_stages, sensor_data$failure_rate)
  
  # Fleet-wide metrics
  fleet_mtbf <- mean(sensor_data$mtbf)
  fleet_mttf <- mean(sensor_data$mttf)
  
  # Reliability at 1000 hours
  reliability_results <- calculate_fleet_reliability(sensor_data, 1000)
  
  # Sensor health categories
  active_count <- sum(sensor_data$health > 70)
  warning_count <- sum(sensor_data$health > 30 & sensor_data$health <= 70)
  failed_count <- sum(sensor_data$health <= 30)
  
  return(list(
    sensor_data = sensor_data,
    fleet_mtbf = fleet_mtbf,
    fleet_mttf = fleet_mttf,
    fleet_reliability = reliability_results$fleet_reliability,
    active_sensors = active_count,
    warning_sensors = warning_count,
    failed_sensors = failed_count,
    total_sensors = nrow(sensor_data)
  ))
}

# Predict Time to Next Failure
predict_next_failure <- function(k, lambda, n_simulations = 10000) {
  failures <- rgamma(n_simulations, shape = k, rate = lambda)
  
  return(list(
    mean_time = mean(failures),
    median_time = median(failures),
    sd_time = sd(failures),
    quantile_05 = quantile(failures, 0.05),
    quantile_95 = quantile(failures, 0.95)
  ))
}

# Cascade Failure Analysis
analyze_cascade_risk <- function(sensor_data) {
  failed_sensors <- sensor_data[sensor_data$health < 30, ]
  n_failed <- nrow(failed_sensors)
  n_total <- nrow(sensor_data)
  
  cascade_risk <- n_failed / n_total
  
  # Dependency multiplier based on risk
  if (cascade_risk > 0.2) {
    dependency_multiplier <- 1.5
  } else if (cascade_risk > 0.1) {
    dependency_multiplier <- 1.2
  } else {
    dependency_multiplier <- 1.0
  }
  
  expected_additional <- round(n_failed * dependency_multiplier * 0.3)
  
  risk_level <- if (cascade_risk > 0.15) {
    "HIGH"
  } else if (cascade_risk > 0.08) {
    "MEDIUM"
  } else {
    "LOW"
  }
  
  return(list(
    current_failures = n_failed,
    cascade_risk_factor = cascade_risk,
    expected_additional_failures = expected_additional,
    risk_level = risk_level,
    dependency_multiplier = dependency_multiplier
  ))
}

# Visualization: Reliability Curves
plot_reliability_curves <- function(k_values = c(2, 3, 4, 5), lambda = 0.0005) {
  time_seq <- seq(0, 5000, length.out = 500)
  
  plot_data <- data.frame()
  
  for (k in k_values) {
    reliability <- erlang_reliability(k, lambda, time_seq)
    temp_df <- data.frame(
      time = time_seq,
      reliability = reliability,
      k = factor(k)
    )
    plot_data <- rbind(plot_data, temp_df)
  }
  
  p <- ggplot(plot_data, aes(x = time, y = reliability, color = k)) +
    geom_line(size = 1.2) +
    labs(
      title = "Erlang Distribution Reliability Curves",
      subtitle = paste("Lambda =", lambda),
      x = "Time (hours)",
      y = "Reliability R(t)",
      color = "k-stages"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    ) +
    scale_color_brewer(palette = "Set1")
  
  return(p)
}

# Main Execution
cat("=== IoT Sensor Network Reliability Analysis ===\n\n")

# Generate sensor data
sensor_data <- generate_sensor_data(50)
cat("Generated", nrow(sensor_data), "sensors\n\n")

# Analyze network
analysis <- analyze_sensor_network(sensor_data)

cat("=== Fleet Reliability Metrics ===\n")
cat("Fleet MTBF:", round(analysis$fleet_mtbf, 2), "hours\n")
cat("Fleet MTTF:", round(analysis$fleet_mttf, 2), "hours\n")
cat("Fleet Reliability at 1000h:", round(analysis$fleet_reliability * 100, 2), "%\n\n")

cat("=== Sensor Status ===\n")
cat("Active (>70%):", analysis$active_sensors, "\n")
cat("Warning (30-70%):", analysis$warning_sensors, "\n")
cat("Failed (<30%):", analysis$failed_sensors, "\n\n")

# Queueing analysis
queue_metrics <- mmc_queue_metrics(
  arrival_rate = 0.05,
  service_rate = 0.15,
  num_servers = 3
)

cat("=== Maintenance Queue Metrics (M/M/3) ===\n")
if (queue_metrics$stable) {
  cat("System Utilization:", round(queue_metrics$utilization * 100, 2), "%\n")
  cat("Average Queue Length:", round(queue_metrics$average_queue_length, 2), "\n")
  cat("Average Wait Time:", round(queue_metrics$average_waiting_time_minutes, 2), "minutes\n\n")
} else {
  cat(queue_metrics$message, "\n\n")
}

# Cascade risk
cascade <- analyze_cascade_risk(sensor_data)
cat("=== Cascade Failure Risk ===\n")
cat("Current Failures:", cascade$current_failures, "\n")
cat("Cascade Risk Factor:", round(cascade$cascade_risk_factor, 3), "\n")
cat("Expected Additional Failures:", cascade$expected_additional_failures, "\n")
cat("Risk Level:", cascade$risk_level, "\n\n")

# Sample prediction
cat("=== Sample Failure Prediction (k=3, lambda=0.0005) ===\n")
prediction <- predict_next_failure(3, 0.0005)
cat("Mean Time to Failure:", round(prediction$mean_time, 2), "hours\n")
cat("Median Time to Failure:", round(prediction$median_time, 2), "hours\n")
cat("95% Confidence Interval:", round(prediction$quantile_05, 2), "-", round(prediction$quantile_95, 2), "hours\n\n")

cat("=== Analysis Complete ===\n")

# Generate and save plot
# plot <- plot_reliability_curves()
# ggsave("reliability_curves.png", plot, width = 10, height = 6)
