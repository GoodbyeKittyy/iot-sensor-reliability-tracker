{-# LANGUAGE RecordWildCards #-}

module ReliabilityModels where

import Data.List (sortBy)
import Data.Ord (comparing)
import Text.Printf (printf)

-- Type definitions
type SensorID = String
type Lambda = Double
type Time = Double
type Probability = Double

-- Sensor data structure
data Sensor = Sensor
  { sensorId :: SensorID
  , sensorType :: SensorType
  , location :: Location
  , health :: Double
  , uptimeHours :: Double
  , failureRate :: Lambda
  , kStages :: Int
  , queuePosition :: Int
  } deriving (Show, Eq)

data SensorType = Traffic | AirQuality | WaterFlow
  deriving (Show, Eq)

data Location = Location
  { locX :: Double
  , locY :: Double
  , locZ :: Double
  } deriving (Show, Eq)

-- Exponential Distribution Functions
exponentialReliability :: Lambda -> Time -> Probability
exponentialReliability lambda t = exp (-lambda * t)

exponentialHazardRate :: Lambda -> Double
exponentialHazardRate lambda = lambda

exponentialMTBF :: Lambda -> Time
exponentialMTBF lambda = 1.0 / lambda

-- Erlang Distribution Functions
factorial :: Int -> Double
factorial n = product [1..fromIntegral n]

erlangPDF :: Int -> Lambda -> Time -> Probability
erlangPDF k lambda t
  | t < 0     = 0
  | otherwise = (lambda ** fromIntegral k) * (t ** fromIntegral (k - 1)) 
                * exp (-lambda * t) / factorial (k - 1)

erlangCDF :: Int -> Lambda -> Time -> Probability
erlangCDF k lambda t
  | t < 0     = 0
  | otherwise = 1 - sum [erlangTerm i | i <- [0..(k-1)]]
  where
    erlangTerm i = exp (-lambda * t) * ((lambda * t) ** fromIntegral i) / factorial i

erlangReliability :: Int -> Lambda -> Time -> Probability
erlangReliability k lambda t = 1 - erlangCDF k lambda t

erlangMTTF :: Int -> Lambda -> Time
erlangMTTF k lambda = fromIntegral k / lambda

-- Fleet Reliability Metrics
data FleetMetrics = FleetMetrics
  { totalSensors :: Int
  , activeSensors :: Int
  , warningSensors :: Int
  , failedSensors :: Int
  , fleetMTBF :: Time
  , fleetMTTF :: Time
  , fleetReliability :: Probability
  } deriving (Show)

calculateFleetMetrics :: [Sensor] -> Time -> FleetMetrics
calculateFleetMetrics sensors timeHorizon = FleetMetrics {..}
  where
    totalSensors = length sensors
    activeSensors = length $ filter (\s -> health s > 70) sensors
    warningSensors = length $ filter (\s -> health s > 30 && health s <= 70) sensors
    failedSensors = length $ filter (\s -> health s <= 30) sensors
    
    mtbfValues = map (exponentialMTBF . failureRate) sensors
    fleetMTBF = average mtbfValues
    
    mttfValues = map (\s -> erlangMTTF (kStages s) (failureRate s)) sensors
    fleetMTTF = average mttfValues
    
    reliabilities = map (\s -> erlangReliability (kStages s) (failureRate s) timeHorizon) sensors
    fleetReliability = average reliabilities

average :: [Double] -> Double
average xs = sum xs / fromIntegral (length xs)

-- Sensor Health Classification
data HealthStatus = Active | Warning | Failed
  deriving (Show, Eq)

classifySensor :: Sensor -> HealthStatus
classifySensor sensor
  | health sensor > 70  = Active
  | health sensor > 30  = Warning
  | otherwise           = Failed

-- Cascade Failure Analysis
data CascadeRisk = CascadeRisk
  { currentFailures :: Int
  , cascadeRiskFactor :: Double
  , expectedAdditionalFailures :: Int
  , riskLevel :: RiskLevel
  , dependencyMultiplier :: Double
  } deriving (Show)

data RiskLevel = Low | Medium | High
  deriving (Show, Eq)

analyzeCascadeRisk :: [Sensor] -> CascadeRisk
analyzeCascadeRisk sensors = CascadeRisk {..}
  where
    failedSensorsList = filter (\s -> health s < 30) sensors
    currentFailures = length failedSensorsList
    totalSensors = length sensors
    cascadeRiskFactor = fromIntegral currentFailures / fromIntegral totalSensors
    
    dependencyMultiplier
      | cascadeRiskFactor > 0.2  = 1.5
      | cascadeRiskFactor > 0.1  = 1.2
      | otherwise                = 1.0
    
    expectedAdditionalFailures = round (fromIntegral currentFailures * dependencyMultiplier * 0.3)
    
    riskLevel
      | cascadeRiskFactor > 0.15  = High
      | cascadeRiskFactor > 0.08  = Medium
      | otherwise                 = Low

-- Maintenance Queue Optimization
data MaintenanceTask = MaintenanceTask
  { taskSensorId :: SensorID
  , taskPriority :: Int
  , assignedCrew :: CrewID
  , estimatedArrival :: Int
  } deriving (Show)

type CrewID = String

generateMaintenanceSchedule :: [Sensor] -> [String] -> [MaintenanceTask]
generateMaintenanceSchedule sensors crews = tasks
  where
    failedSensors = sortBy (comparing queuePosition) $ filter (\s -> health s < 30) sensors
    warningSensors = sortBy (comparing health) $ filter (\s -> health s > 30 && health s <= 70) sensors
    prioritySensors = take 20 (failedSensors ++ warningSensors)
    
    tasks = zipWith makeTask [0..] prioritySensors
    
    makeTask idx sensor = MaintenanceTask
      { taskSensorId = sensorId sensor
      , taskPriority = if health sensor < 30 then 1 else 2
      , assignedCrew = crews !! (idx `mod` length crews)
      , estimatedArrival = (idx `div` length crews) * 45 + 15
      }

-- Reliability Prediction
predictNextFailure :: Int -> Lambda -> Int -> [Time]
predictNextFailure k lambda nSamples = take nSamples $ repeat estimatedTime
  where
    estimatedTime = erlangMTTF k lambda

-- Queueing Theory M/M/c Model
data QueueMetrics = QueueMetrics
  { utilization :: Double
  , avgQueueLength :: Double
  , avgWaitTimeMinutes :: Double
  } deriving (Show)

calculateQueueMetrics :: Double -> Double -> Int -> Maybe QueueMetrics
calculateQueueMetrics arrivalRate serviceRate numServers
  | rho >= 1  = Nothing
  | otherwise = Just QueueMetrics {..}
  where
    rho = arrivalRate / (fromIntegral numServers * serviceRate)
    utilization = rho * 100
    
    lambdaMu = arrivalRate / serviceRate
    
    p0Denominator = sum [lambdaMu ** fromIntegral n / factorial n | n <- [0..(numServers-1)]]
                  + (lambdaMu ** fromIntegral numServers) / (factorial numServers * (1 - rho))
    p0 = 1 / p0Denominator
    
    avgQueueLength = (p0 * (lambdaMu ** fromIntegral numServers) * rho) 
                   / (factorial numServers * (1 - rho) ** 2)
    
    avgWaitTimeHours = avgQueueLength / arrivalRate
    avgWaitTimeMinutes = avgWaitTimeHours * 60

-- Sample Data Generation
sampleSensors :: [Sensor]
sampleSensors = 
  [ Sensor 
      { sensorId = "SNS-" ++ printf "%04d" i
      , sensorType = sensorTypes !! (i `mod` 3)
      , location = Location (fromIntegral i * 2.0) (fromIntegral i * 1.5) (fromIntegral (i `mod` 3))
      , health = 50.0 + fromIntegral (i `mod` 40)
      , uptimeHours = 1000.0 + fromIntegral (i * 100)
      , failureRate = 0.0005 + fromIntegral (i `mod` 3) * 0.0001
      , kStages = 2 + (i `mod` 3)
      , queuePosition = i `mod` 10
      }
  | i <- [1..50]
  ]
  where
    sensorTypes = [Traffic, AirQuality, WaterFlow]

-- Pretty Printing
printFleetMetrics :: FleetMetrics -> IO ()
printFleetMetrics FleetMetrics{..} = do
  putStrLn "=== Fleet Reliability Metrics ==="
  printf "Total Sensors: %d\n" totalSensors
  printf "Active Sensors: %d\n" activeSensors
  printf "Warning Sensors: %d\n" warningSensors
  printf "Failed Sensors: %d\n" failedSensors
  printf "Fleet MTBF: %.2f hours\n" fleetMTBF
  printf "Fleet MTTF: %.2f hours\n" fleetMTTF
  printf "Fleet Reliability: %.2f%%\n" (fleetReliability * 100)
  putStrLn ""

printCascadeRisk :: CascadeRisk -> IO ()
printCascadeRisk CascadeRisk{..} = do
  putStrLn "=== Cascade Failure Risk Analysis ==="
  printf "Current Failures: %d\n" currentFailures
  printf "Cascade Risk Factor: %.3f\n" cascadeRiskFactor
  printf "Expected Additional Failures: %d\n" expectedAdditionalFailures
  printf "Risk Level: %s\n" (show riskLevel)
  printf "Dependency Multiplier: %.2f\n" dependencyMultiplier
  putStrLn ""

printQueueMetrics :: QueueMetrics -> IO ()
printQueueMetrics QueueMetrics{..} = do
  putStrLn "=== Maintenance Queue Metrics ==="
  printf "System Utilization: %.2f%%\n" utilization
  printf "Average Queue Length: %.2f\n" avgQueueLength
  printf "Average Wait Time: %.2f minutes\n" avgWaitTimeMinutes
  putStrLn ""

-- Main execution
main :: IO ()
main = do
  putStrLn "IoT Sensor Network Reliability Tracker - Haskell Implementation"
  putStrLn "================================================================\n"
  
  let sensors = sampleSensors
  let metrics = calculateFleetMetrics sensors 1000.0
  printFleetMetrics metrics
  
  let cascade = analyzeCascadeRisk sensors
  printCascadeRisk cascade
  
  case calculateQueueMetrics 0.05 0.15 3 of
    Just queueMetrics -> printQueueMetrics queueMetrics
    Nothing -> putStrLn "Queue system unstable (rho >= 1)\n"
  
  let crews = ["CREW-A", "CREW-B", "CREW-C"]
  let schedule = generateMaintenanceSchedule sensors crews
  putStrLn "=== Maintenance Schedule (First 10 Tasks) ==="
  mapM_ (printf "  %s -> %s (ETA: %d min, Priority: %d)\n" 
         <$> taskSensorId 
         <*> assignedCrew 
         <*> estimatedArrival 
         <*> taskPriority) (take 10 schedule)
  putStrLn ""
  
  putStrLn "=== Sample Reliability Calculations ==="
  let sampleSensor = head sensors
  let t = 500.0
  printf "Sensor: %s\n" (sensorId sampleSensor)
  printf "Exponential R(%s): %.4f\n" (show t) 
         (exponentialReliability (failureRate sampleSensor) t)
  printf "Erlang R(%s): %.4f\n" (show t)
         (erlangReliability (kStages sampleSensor) (failureRate sampleSensor) t)
  printf "MTBF: %.2f hours\n" (exponentialMTBF (failureRate sampleSensor))
  printf "MTTF: %.2f hours\n" (erlangMTTF (kStages sampleSensor) (failureRate sampleSensor))
  
  putStrLn "\n=== Analysis Complete ==="
